from PIL import Image
import numpy as np

# Load and convert image to grayscale
img = Image.open("crack.jpg").convert("L")
width, height = img.size

# Number of parts (vertical split)
n_parts = 100
split_height = height // n_parts

# Create binary parts
binary_parts = []
for i in range(n_parts):
    top = i * split_height
    bottom = height if i == n_parts - 1 else (i + 1) * split_height
    part = img.crop((0, top, width, bottom))
    
    # Convert to binary (threshold = 128)
    binary_array = np.array(part)
    binary_array = np.where(binary_array > 128, 255, 0).astype(np.uint8)
    binary_img = Image.fromarray(binary_array)
    
    binary_parts.append(binary_img)

# Combine all parts
combined_image = Image.new("L", (width, height))
for i, part in enumerate(binary_parts):
    combined_image.paste(part, (0, i * split_height))

# Save final result
combined_image.save("binary_combined_output.png")
