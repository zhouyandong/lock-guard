#!/usr/bin/env python3
"""Convert any image (JPG/PNG) to macOS .icns app icon."""
import os, sys, shutil, subprocess, tempfile
from PIL import Image

RESOURCES = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'LockGuard/Resources')
SIZES = [16, 32, 64, 128, 256, 512, 1024]

def find_source():
    """Find the source image in Resources dir (prefer jpg/jpeg/png)."""
    for f in sorted(os.listdir(RESOURCES)):
        if f.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp', '.webp')):
            return os.path.join(RESOURCES, f)
    return None

def main():
    src = find_source()
    if not src:
        print("No image found in", RESOURCES)
        sys.exit(1)
    
    print(f"Source: {os.path.basename(src)}")
    img = Image.open(src).convert('RGB' if src.lower().endswith(('.jpg','.jpeg')) else 'RGBA')
    
    # If RGBA, check if it's a square icon already (no need to crop)
    w, h = img.size
    print(f"Size: {w}x{h}")
    
    # Crop to square (center-crop)
    if w != h:
        size = min(w, h)
        left = (w - size) // 2
        top = (h - size) // 2
        img = img.crop((left, top, left + size, top + size))
        print(f"Cropped to {size}x{size}")
    
    # Generate all sizes with rounded corners
    iconset = os.path.join(tempfile.mkdtemp(), 'LockGuard.iconset')
    os.makedirs(iconset)
    
    for sz in SIZES:
        copy = img.resize((sz, sz), Image.LANCZOS).convert('RGBA')
        # Apply rounded corner mask (macOS-style: ~22.5% corner radius)
        radius = int(sz * 0.225)
        mask = Image.new('L', (sz, sz), 0)
        from PIL import ImageDraw
        draw = ImageDraw.Draw(mask)
        draw.rounded_rectangle([0, 0, sz, sz], radius=radius, fill=255)
        rounded = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
        rounded.paste(copy, (0, 0), mask)
        p = os.path.join(iconset, f'icon_{sz}x{sz}.png')
        rounded.save(p, 'PNG')
        print(f'  {sz}x{sz}')
    
    # @2x copies
    for sz in sorted(SIZES, reverse=True):
        half = sz // 2
        if half >= 16 and half in SIZES and half * 2 == sz:
            src_p = os.path.join(iconset, f'icon_{sz}x{sz}.png')
            dst_p = os.path.join(iconset, f'icon_{half}x{half}@2x.png')
            if os.path.exists(src_p):
                shutil.copy(src_p, dst_p)
    
    output = os.path.join(RESOURCES, 'AppIcon.icns')
    result = subprocess.run(['iconutil', '-c', 'icns', iconset, '-o', output], capture_output=True, text=True)
    
    shutil.rmtree(os.path.dirname(iconset))
    
    if result.returncode == 0:
        print(f"✅ Saved {output}")
    else:
        print(f"❌ iconutil failed: {result.stderr}")

if __name__ == '__main__':
    main()
