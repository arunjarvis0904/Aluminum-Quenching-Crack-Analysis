function crack_analysis_main(image_path)
    % Step 1: Read and preprocess image
    img = imread(image_path);
    
    if islogical(img) || all(ismember(unique(img), [0, 1]))
        bw = logical(img);
        disp('Input image is already binary. No conversion applied.');
    else
        if ndims(img) == 3
            grayImg = rgb2gray(img);
        else
            grayImg = img;
        end
        bw = imbinarize(grayImg);
        if sum(bw(:)) == 0 || sum(bw(:)) == numel(bw)
            bw = grayImg < 120;
            disp('Used manual threshold.');
        end
        disp('Converted grayscale to binary.');
    end

    % Ensure crack is white
    if mean(bw(:)) < 0.5
        bw = imcomplement(bw);
        disp('Inverted image: crack made white.');
    end

    % Crop to crack region
    props = regionprops(bw, 'BoundingBox');
    if isempty(props)
        error('No crack found.');
    end
    bbox = round(props(1).BoundingBox);
    bw = imcrop(bw, bbox);

    % Step 2: Skeletonize
    bw_skel = bwmorph(bw, 'skel', Inf);

    % Step 3: Fractal Dimension
    D = compute_fractal_dimension(bw);

    % Step 4: Crack Length
    crack_length = sum(bw_skel(:));

    % Step 5: Crack Width
    bw_dist = bwdist(~bw);
    crack_width = 2 * mean(bw_dist(bw_skel));

    % Step 6: Improved Tortuosity
    endpoints = bwmorph(bw_skel, 'endpoints');
    [y_end, x_end] = find(endpoints);

    if numel(x_end) < 2
        error('Not enough endpoints to compute tortuosity.');
    end

    % Pick first two endpoints
    start_point = [x_end(1), y_end(1)];
    end_point   = [x_end(2), y_end(2)];

    % Compute geodesic path (crack path) and Euclidean distance
    Dmap = bwdistgeodesic(bw_skel, start_point(1), start_point(2), 'quasi-euclidean');
    geodist = Dmap(end_point(2), end_point(1));
    euclid_dist = sqrt(sum((start_point - end_point).^2));
    tortuosity = geodist / euclid_dist;

    % Step 7: Severity Classification
    severity = classify_crack(D, crack_length, crack_width, tortuosity);

    % Step 8: Display Results
    figure;
    subplot(1,3,1); imshow(img); title('Original Image');
    subplot(1,3,2); imshow(bw); title('Binary Crack');
    subplot(1,3,3); imshow(bw_skel); title('Skeleton (Crack Path)');

    % Show endpoints on skeleton
    hold on;
    plot(start_point(1), start_point(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    plot(end_point(1), end_point(2), 'go', 'MarkerSize', 10, 'LineWidth', 2);
    legend('Start', 'End');

    % Step 9: Final Report
    fprintf('\n--- Final Crack Summary ---\n');
    disp(severity);
end

%% Fractal Dimension Calculation (WITH PLOT)
function D = compute_fractal_dimension(bw)
    [h, w] = size(bw);
    n = 2^floor(log2(min(h, w)));
    bw = bw(1:n, 1:n);
    box_sizes = 2.^(floor(log2(n)):-1:2);
    counts = zeros(size(box_sizes));

    for i = 1:length(box_sizes)
        counts(i) = box_count(bw, box_sizes(i));
    end

    log_sizes = log(1 ./ box_sizes);
    log_counts = log(counts + 1);  % Avoid log(0)
    coeffs = polyfit(log_sizes, log_counts, 1);
    D = coeffs(1);

    % === Plot Log-Log Graph ===
    figure;
    plot(log_sizes, log_counts, 'o-', 'LineWidth', 2);
    hold on;
    plot(log_sizes, polyval(coeffs, log_sizes), 'r--', 'LineWidth', 2);
    xlabel('log(1 / Box Size)');
    ylabel('log(Box Count)');
    title(['Fractal Dimension Estimate, D = ', num2str(D, '%.4f')]);
    legend('Data Points', 'Linear Fit', 'Location', 'SouthEast');
    grid on;
end

function c = box_count(bw, box_size)
    bw = bw(1:floor(end/box_size)*box_size, 1:floor(end/box_size)*box_size);
    c = 0;
    for i = 1:box_size:size(bw,1)
        for j = 1:box_size:size(bw,2)
            block = bw(i:i+box_size-1, j:j+box_size-1);
            if any(block(:))
                c = c + 1;
            end
        end
    end
end

%% Crack Severity Classification
function result = classify_crack(D, L, W, T)
    normD = min(D / 2, 1);            % Normalize D
    normL = min(L / 10000, 1);        % Normalize length
    normW = min(W / 200, 1);          % Normalize width
    normT = min(T / 5, 1);            % Normalize tortuosity

    score = 0.4 * normD + 0.3 * normL + 0.2 * normW + 0.1 * normT;

    if score < 0.4
        level = 'Low';
    elseif score < 0.7
        level = 'Moderate';
    else
        level = 'High';
    end

    fprintf('\n--- Crack Severity Report ---\n');
    fprintf('Fractal Dimension (D): %.4f\n', D);
    fprintf('Crack Length (px):     %.2f\n', L);
    fprintf('Crack Width  (px):     %.2f\n', W);
    fprintf('Tortuosity:            %.4f\n', T);
    fprintf('Severity Score:        %.4f\n', score);
    fprintf('Severity Level:        %s\n', level);

    result = struct( ...
        'FractalDimension', D, ...
        'CrackLength', L, ...
        'CrackWidth', W, ...
        'Tortuosity', T, ...
        'Score', score, ...
        'SeverityLevel', level ...
    );
end
