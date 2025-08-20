import cv2
import numpy as np
import matplotlib.pyplot as plt

def box_count(img, box_sizes):
    counts = []
    for size in box_sizes:
        S = size
        h, w = img.shape

        # Resize to fit an exact number of boxes
        new_h = h if h % S == 0 else h + S - (h % S)
        new_w = w if w % S == 0 else w + S - (w % S)

        padded = np.zeros((new_h, new_w), dtype=np.uint8)
        padded[:h, :w] = img

        count = 0
        for i in range(0, new_h, S):
            for j in range(0, new_w, S):
                block = padded[i:i+S, j:j+S]
                if np.any(block):  # If crack exists in this box
                    count += 1
        counts.append(count)
    return counts

# Load the binary image
img = cv2.imread('C:/internship/crack_binary.jpg', 0)

# Invert if needed: crack should be white (255), background black (0)
_, img = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY)

# Box sizes to test (powers of 2)
box_sizes = [2, 4, 8, 16, 32, 64]

# Get box counts
counts = box_count(img, box_sizes)

# Log-log plot
log_sizes = np.log(1/np.array(box_sizes))
log_counts = np.log(np.array(counts))

# Linear fit to get slope (fractal dimension)
fit = np.polyfit(log_sizes, log_counts, 1)
fractal_dimension = fit[0]
intercept = fit[1]

# Calculate the fitted values for the regression line
fitted_counts = fractal_dimension * log_sizes + intercept

# Plot the original points and the fitted line together
plt.plot(log_sizes, log_counts, 'bo-', label='Box Count Data')
plt.plot(log_sizes, fitted_counts, 'r--', label='Fit Line')

# Add fractal dimension text inside the plot
plt.text(
    0.05, 0.95,  # position inside axes (left, top)
    f"Fractal Dimension (D): {fractal_dimension:.4f}",
    transform=plt.gca().transAxes,  # coords relative to axes
    fontsize=12,
    verticalalignment='top',
    bbox=dict(boxstyle='round', facecolor='white', alpha=0.7)
)

plt.xlabel('log(1/box size)')
plt.ylabel('log(count)')
plt.title('Box Counting Method - Fractal Dimension')
plt.legend()
plt.grid(True)
plt.show()

# Also print in console
print(f"Estimated Fractal Dimension (slope): {fractal_dimension:.4f}")
