from PIL import Image
import numpy as np

# ✅ Use a raw string to prevent \b being interpreted as backspace
image_path = r"D:\internship\py\crack.jpg"
# Load the image and convert to grayscale
img = Image.open(image_path).convert("L")
width, height = img.size

# Define grid size (12x12)
grid_rows, grid_cols = 12, 12
tile_width = width // grid_cols
tile_height = height // grid_rows

# Process image in 12x12 grid tiles and binarize each tile
binary_tiles = []
for row in range(grid_rows):
    row_tiles = []
    for col in range(grid_cols):
        left = col * tile_width
        upper = row * tile_height
        right = (col + 1) * tile_width if col < grid_cols - 1 else width
        lower = (row + 1) * tile_height if row < grid_rows - 1 else height

        tile = img.crop((left, upper, right, lower))
        tile_np = np.array(tile)

        # Apply binary threshold (you can tweak threshold value 128)
        binary_tile = np.where(tile_np > 128, 255, 0).astype(np.uint8)
        row_tiles.append(binary_tile)
    binary_tiles.append(row_tiles)

# Recombine all binary tiles into one image
combined_image_array = np.vstack([np.hstack(row) for row in binary_tiles])
combined_image = Image.fromarray(combined_image_array)

# Save the result
output_path_grid = r"D:\internship\py\binary_combined_grid_12x12.png"
combined_image.save(output_path_grid)

# Optional: Show in notebook or GUI app
combined_image.show()

# Output saved path
output_path_grid
