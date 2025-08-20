function D = fractal_dimension_binary(image_path)
    % Read the image
    img = imread(image_path);

    % Step 1: Check if image is binary (0 and 1 only)
    if islogical(img) || all(ismember(unique(img), [0, 1]))
        bw = logical(img);  % Image is binary, use as-is
        disp('Input image is already binary. No conversion applied.');
    else
        % Step 2: Convert to grayscale if needed
        if ndims(img) == 3
            grayImg = rgb2gray(img);
        else
            grayImg = img;
        end

        figure; imshow(grayImg); title('Grayscale Image');

        % Step 3: Convert to binary
        bw = imbinarize(grayImg);

        % Step 4: Fallback if imbinarize fails (all black or white)
        if sum(bw(:)) == 0 || sum(bw(:)) == numel(bw)
            bw = grayImg < 120;
            disp('Used manual thresholding due to failed adaptive threshold.');
        end
        disp('Converted grayscale image to binary.');
    end

    % Step 5: Make crack white if needed
    crack_white_ratio = sum(bw(:)) / numel(bw);
    if crack_white_ratio < 0.01
        bw = imcomplement(bw);
        disp('Image inverted (crack made white).');
    end

    % Step 6: Try cropping to crack region
    stats = regionprops(bw, 'BoundingBox');
    if ~isempty(stats)
        bbox = stats(1).BoundingBox;
        if length(bbox) == 4
            bw = imcrop(bw, bbox);
            disp('Image cropped to crack region.');
        else
            disp('Bounding box invalid. Skipping cropping.');
        end
    else
        disp('No region found to crop. Proceeding with full image.');
    end

    % Step 7: Skeletonization (optional, but helpful)
    bw = bwmorph(bw, 'skel', Inf);
    disp('Skeletonization applied to thin the crack.');

    % Step 8: Validate crack presence
    if sum(bw(:)) == 0
        error('No crack pixels detected. Check image or thresholding.');
    end

    % Step 9: Crop to power-of-2 square
    [h, w] = size(bw);
    p = min(h, w);
    n = 2^floor(log2(p));
    bw = bw(1:n, 1:n);

    % Step 10: Box sizes and counting
    sizes = 2.^(floor(log2(n)):-1:2);
    counts = zeros(size(sizes));

    fprintf('\nImage size used: %d x %d\n', n, n);
    fprintf('Box sizes: '); disp(sizes);

    for i = 1:length(sizes)
        k = sizes(i);
        counts(i) = boxcount(bw, k);
        fprintf('Box size %4d → %d boxes\n', k, counts(i));
    end

    % Step 11: Avoid log(0)
    counts(counts == 0) = 1;

    % Step 12: Log-log fit for fractal dimension
    logsizes = log(1 ./ sizes);
    logcounts = log(counts);

    fit_range = 2:(length(sizes)-1);  % Skip edge sizes
    coeffs = polyfit(logsizes(fit_range), logcounts(fit_range), 1);
    D = coeffs(1);  % Slope = fractal dimension

    % Step 13: Compute R²
    y_fit = polyval(coeffs, logsizes(fit_range));
    y_actual = logcounts(fit_range);
    SS_res = sum((y_actual - y_fit).^2);
    SS_tot = sum((y_actual - mean(y_actual)).^2);
    R_squared = 1 - SS_res / SS_tot;

    % Step 14: Plot results
    figure;
    plot(logsizes, logcounts, 'bo-', 'LineWidth', 2); hold on;
    plot(logsizes, polyval(coeffs, logsizes), 'r--', 'LineWidth', 2);
    title(sprintf('Fractal Dimension D = %.4f (R^2 = %.4f)', D, R_squared));
    xlabel('log(1 / Box Size)');
    ylabel('log(Box Count)');
    legend('Data', 'Fit');
    grid on;
    set(gca, 'FontSize', 12);

    % Step 15: Display
    fprintf('\nEstimated Fractal Dimension: D = %.4f\n', D);
    fprintf('Goodness of Fit (R^2): %.4f\n', R_squared);
end

% Supporting function: Box Counting
function count = boxcount(BW, k)
    [rows, cols] = size(BW);
    rows = floor(rows / k) * k;
    cols = floor(cols / k) * k;
    BW = BW(1:rows, 1:cols);
    count = 0;
    for i = 1:k:rows
        for j = 1:k:cols
            block = BW(i:i+k-1, j:j+k-1);
            if any(block(:))
                count = count + 1;
            end
        end
    end
end
