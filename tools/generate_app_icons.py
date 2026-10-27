#!/usr/bin/env python3
"""
generate_app_icons.py
Genera todos los tamaños de icono para Android (mipmap) e iOS (AppIcon.appiconset)
a partir de assets/images/berea_interlineal_icon.jpg
"""
import os
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).parent.parent
SOURCE_IMAGE = ROOT / "assets" / "images" / "berea_interlineal_icon.jpg"

ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_APPICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

# Resoluciones de Android mipmap
ANDROID_ICONS = {
    ANDROID_RES / "mipmap-mdpi" / "ic_launcher.png": (48, 48),
    ANDROID_RES / "mipmap-hdpi" / "ic_launcher.png": (72, 72),
    ANDROID_RES / "mipmap-xhdpi" / "ic_launcher.png": (96, 96),
    ANDROID_RES / "mipmap-xxhdpi" / "ic_launcher.png": (144, 144),
    ANDROID_RES / "mipmap-xxxhdpi" / "ic_launcher.png": (192, 192),
}

# Resoluciones de iOS AppIcon
IOS_ICONS = {
    IOS_APPICON / "Icon-App-20x20@1x.png": (20, 20),
    IOS_APPICON / "Icon-App-20x20@2x.png": (40, 40),
    IOS_APPICON / "Icon-App-20x20@3x.png": (60, 60),
    IOS_APPICON / "Icon-App-29x29@1x.png": (29, 29),
    IOS_APPICON / "Icon-App-29x29@2x.png": (58, 58),
    IOS_APPICON / "Icon-App-29x29@3x.png": (87, 87),
    IOS_APPICON / "Icon-App-40x40@1x.png": (40, 40),
    IOS_APPICON / "Icon-App-40x40@2x.png": (80, 80),
    IOS_APPICON / "Icon-App-40x40@3x.png": (120, 120),
    IOS_APPICON / "Icon-App-60x60@2x.png": (120, 120),
    IOS_APPICON / "Icon-App-60x60@3x.png": (180, 180),
    IOS_APPICON / "Icon-App-76x76@1x.png": (76, 76),
    IOS_APPICON / "Icon-App-76x76@2x.png": (152, 152),
    IOS_APPICON / "Icon-App-83.5x83.5@2x.png": (167, 167),
    IOS_APPICON / "Icon-App-1024x1024@1x.png": (1024, 1024),
}

def main():
    if not SOURCE_IMAGE.exists():
        print(f"[ERROR] No se encontró la imagen origen: {SOURCE_IMAGE}")
        return

    print(f"[INFO] Cargando imagen base: {SOURCE_IMAGE}")
    im = Image.open(SOURCE_IMAGE).convert("RGBA")

    print("[INFO] Generando iconos para Android...")
    for out_path, size in ANDROID_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        resized = im.resize(size, Image.Resampling.LANCZOS)
        resized.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    print("[INFO] Generando iconos para iOS...")
    for out_path, size in IOS_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        resized = im.resize(size, Image.Resampling.LANCZOS)
        resized.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    print("[SUCCESS] ¡Todos los iconos de Android e iOS fueron generados exitosamente!")

if __name__ == "__main__":
    main()
