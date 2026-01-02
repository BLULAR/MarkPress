from PIL import Image
import os

def create_ico():
    base_dir = os.getcwd()
    logo_dir = os.path.join(base_dir, 'logo')
    output_path = os.path.join(base_dir, 'windows', 'runner', 'resources', 'app_icon.ico')
    
    img16_path = os.path.join(logo_dir, 'mdviewer16x16.jpg')
    img32_path = os.path.join(logo_dir, 'mdviewer32x32.jpg')
    
    images = []
    
    if os.path.exists(img16_path):
        img16 = Image.open(img16_path)
        images.append(img16)
        print("Loaded 16x16 icon")
        
    if os.path.exists(img32_path):
        img32 = Image.open(img32_path)
        images.append(img32)
        # Also add a larger version for high DPI, resizing the 32x32 one
        # This is not ideal quality-wise but required for Windows to not look broken in large views
        images.append(img32.resize((48, 48)))
        images.append(img32.resize((256, 256)))
        print("Loaded 32x32 icon and generated 48x48, 256x256 variants")

    if images:
        # Save as ICO
        images[0].save(output_path, format='ICO', sizes=[(img.width, img.height) for img in images], append_images=images[1:])
        print(f"Successfully created {output_path}")
    else:
        print("No images found to create icon")

if __name__ == "__main__":
    create_ico()
