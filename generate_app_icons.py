#!/usr/bin/env python3
"""
Script to generate app icons from SVG logo
This script creates PNG versions of the logo in different sizes for Android and iOS
"""

import os
from PIL import Image, ImageDraw
import math

def create_app_icon(size, output_path):
    """Create a PNG app icon from the SVG design"""
    
    # Create a new image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate scaling factor
    scale = size / 512
    
    # Colors
    bg_color = (26, 26, 46, 255)  # #1a1a2e
    primary_color = (0, 255, 136, 230)  # #00ff88 with opacity
    inner_bg = (22, 33, 62, 255)  # #16213e
    hook_color = (255, 68, 68, 255)  # #ff4444
    white = (255, 255, 255, 255)
    
    # Draw background circle
    margin = int(12 * scale)
    bg_radius = (size - margin * 2) // 2
    draw.ellipse([margin, margin, size - margin, size - margin], 
                 fill=bg_color, outline=primary_color, width=int(12 * scale))
    
    # Draw inner circle
    inner_margin = int(56 * scale)
    inner_radius = (size - inner_margin * 2) // 2
    draw.ellipse([inner_margin, inner_margin, size - inner_margin, size - inner_margin], 
                 fill=inner_bg, outline=primary_color, width=int(6 * scale))
    
    # Draw shield
    shield_width = int(152 * scale)
    shield_height = int(200 * scale)
    shield_x = (size - shield_width) // 2
    shield_y = int(100 * scale)
    
    # Shield base
    shield_points = [
        (shield_x + int(76 * scale), shield_y),  # Top center
        (shield_x, shield_y + int(40 * scale)),  # Left top
        (shield_x, shield_y + int(160 * scale)),  # Left bottom
        (shield_x + int(76 * scale), shield_y + int(200 * scale)),  # Bottom center
        (shield_x + shield_width, shield_y + int(160 * scale)),  # Right bottom
        (shield_x + shield_width, shield_y + int(40 * scale)),  # Right top
    ]
    draw.polygon(shield_points, fill=primary_color)
    
    # Shield inner
    inner_shield_width = int(112 * scale)
    inner_shield_height = int(150 * scale)
    inner_shield_x = (size - inner_shield_width) // 2
    inner_shield_y = int(120 * scale)
    
    inner_shield_points = [
        (inner_shield_x + int(56 * scale), inner_shield_y),  # Top center
        (inner_shield_x, inner_shield_y + int(30 * scale)),  # Left top
        (inner_shield_x, inner_shield_y + int(120 * scale)),  # Left bottom
        (inner_shield_x + int(56 * scale), inner_shield_y + int(150 * scale)),  # Bottom center
        (inner_shield_x + inner_shield_width, inner_shield_y + int(120 * scale)),  # Right bottom
        (inner_shield_x + inner_shield_width, inner_shield_y + int(30 * scale)),  # Right top
    ]
    draw.polygon(inner_shield_points, fill=white)
    
    # Draw fish hook
    hook_center_x = size // 2
    hook_center_y = int(220 * scale)
    hook_radius = int(20 * scale)
    
    # Hook line
    line_start_y = int(180 * scale)
    draw.line([(hook_center_x, line_start_y), (hook_center_x, hook_center_y)], 
              fill=hook_color, width=int(6 * scale))
    
    # Hook arc
    hook_bbox = [hook_center_x - hook_radius, hook_center_y - hook_radius,
                 hook_center_x + hook_radius, hook_center_y + hook_radius]
    draw.arc(hook_bbox, 0, 180, fill=hook_color, width=int(4 * scale))
    
    # Hook point
    point_radius = int(8 * scale)
    draw.ellipse([hook_center_x - int(24 * scale) - point_radius, 
                  hook_center_y - point_radius,
                  hook_center_x - int(24 * scale) + point_radius, 
                  hook_center_y + point_radius], 
                 fill=hook_color)
    
    # Security lines
    line_y1 = int(170 * scale)
    line_y2 = int(190 * scale)
    line_y3 = int(210 * scale)
    line_start_x = int(200 * scale)
    line_end_x = int(312 * scale)
    
    for line_y in [line_y1, line_y2, line_y3]:
        draw.line([(line_start_x, line_y), (line_end_x, line_y)], 
                  fill=primary_color, width=int(3 * scale))
    
    # Decorative dots
    dot_positions = [
        (int(150 * scale), int(150 * scale)),
        (int(362 * scale), int(150 * scale)),
        (int(150 * scale), int(362 * scale)),
        (int(362 * scale), int(362 * scale)),
    ]
    
    for dot_x, dot_y in dot_positions:
        dot_radius = int(4 * scale)
        draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                      dot_x + dot_radius, dot_y + dot_radius], 
                     fill=primary_color)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Generated {output_path} ({size}x{size})")

def main():
    """Generate app icons in various sizes"""
    
    # Create output directories
    os.makedirs('android/app/src/main/res/mipmap-hdpi', exist_ok=True)
    os.makedirs('android/app/src/main/res/mipmap-mdpi', exist_ok=True)
    os.makedirs('android/app/src/main/res/mipmap-xhdpi', exist_ok=True)
    os.makedirs('android/app/src/main/res/mipmap-xxhdpi', exist_ok=True)
    os.makedirs('android/app/src/main/res/mipmap-xxxhdpi', exist_ok=True)
    os.makedirs('web/icons', exist_ok=True)
    
    # Android icon sizes
    android_sizes = [
        (48, 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'),
        (72, 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'),
        (96, 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'),
        (144, 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'),
        (192, 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'),
    ]
    
    # Web icon sizes
    web_sizes = [
        (192, 'web/icons/Icon-192.png'),
        (512, 'web/icons/Icon-512.png'),
        (192, 'web/icons/Icon-maskable-192.png'),
        (512, 'web/icons/Icon-maskable-512.png'),
    ]
    
    # Generate Android icons
    print("Generating Android app icons...")
    for size, path in android_sizes:
        create_app_icon(size, path)
    
    # Generate Web icons
    print("Generating Web app icons...")
    for size, path in web_sizes:
        create_app_icon(size, path)
    
    print("✅ All app icons generated successfully!")
    print("\nGenerated files:")
    print("- Android: ic_launcher.png in various mipmap folders")
    print("- Web: Icon-192.png, Icon-512.png, Icon-maskable-192.png, Icon-maskable-512.png")

if __name__ == "__main__":
    main()
