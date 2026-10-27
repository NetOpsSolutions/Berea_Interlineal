#!/usr/bin/env python3
"""
generate_app_icons.py
Genera todos los tamaños de icono para Android (mipmap legacy, round y adaptive icons v26)
e iOS (AppIcon.appiconset) a partir de assets/images/berea_interlineal_icon.jpg
"""
import os
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent.parent
SOURCE_IMAGE = ROOT / "assets" / "images" / "berea_interlineal_icon.jpg"

ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_APPICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

# Resoluciones de Android mipmap estándar (cuadrado legacy)
ANDROID_ICONS = {
    ANDROID_RES / "mipmap-mdpi" / "ic_launcher.png": (48, 48),
    ANDROID_RES / "mipmap-hdpi" / "ic_launcher.png": (72, 72),
    ANDROID_RES / "mipmap-xhdpi" / "ic_launcher.png": (96, 96),
    ANDROID_RES / "mipmap-xxhdpi" / "ic_launcher.png": (144, 144),
    ANDROID_RES / "mipmap-xxxhdpi" / "ic_launcher.png": (192, 192),
}

# Resoluciones de Android mipmap round (circular con fondo azul marino)
ANDROID_ROUND_ICONS = {
    ANDROID_RES / "mipmap-mdpi" / "ic_launcher_round.png": (48, 48),
    ANDROID_RES / "mipmap-hdpi" / "ic_launcher_round.png": (72, 72),
    ANDROID_RES / "mipmap-xhdpi" / "ic_launcher_round.png": (96, 96),
    ANDROID_RES / "mipmap-xxhdpi" / "ic_launcher_round.png": (144, 144),
    ANDROID_RES / "mipmap-xxxhdpi" / "ic_launcher_round.png": (192, 192),
}

# Resoluciones de Foreground para Adaptive Icons (108 dp)
ANDROID_FOREGROUND_ICONS = {
    ANDROID_RES / "mipmap-mdpi" / "ic_launcher_foreground.png": (108, 108),
    ANDROID_RES / "mipmap-hdpi" / "ic_launcher_foreground.png": (162, 162),
    ANDROID_RES / "mipmap-xhdpi" / "ic_launcher_foreground.png": (216, 216),
    ANDROID_RES / "mipmap-xxhdpi" / "ic_launcher_foreground.png": (324, 324),
    ANDROID_RES / "mipmap-xxxhdpi" / "ic_launcher_foreground.png": (432, 432),
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

BG_COLOR = (6, 17, 45, 255)  # #06112D (Navy profundo del logo oficial de Berea)

def make_round_icon(im, size):
    """Genera un icono circular perfecto con fondo continuo."""
    w, h = size
    # Reescalar la imagen base
    resized = im.resize((w, h), Image.Resampling.LANCZOS)
    
    # Crear máscara circular suave antialiased
    scale = 4
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, w * scale - 1, h * scale - 1), fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    
    # Fondo base sólido
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(resized, (0, 0), mask)
    return out

def make_adaptive_foreground(im, size):
    """
    Genera el layer Foreground de 108dp para Android Adaptive Icons.
    El contenido central (Biblia + lupa) se escala para ocupar el área segura (~72dp).
    """
    w, h = size
    # El contenido del logo está centrado entre (100, 100) y (924, 924)
    cropped = im.crop((95, 95, 929, 929))
    
    # Escalar para ocupar el 72% del lienzo de 108dp
    content_size = int(w * 0.72)
    resized_content = cropped.resize((content_size, content_size), Image.Resampling.LANCZOS)
    
    # Pegar centrado en lienzo transparente de 108dp
    fg = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    offset = ((w - content_size) // 2, (h - content_size) // 2)
    fg.paste(resized_content, offset, resized_content)
    return fg

def main():
    if not SOURCE_IMAGE.exists():
        print(f"[ERROR] No se encontró la imagen origen: {SOURCE_IMAGE}")
        return

    print(f"[INFO] Cargando imagen base: {SOURCE_IMAGE}")
    im = Image.open(SOURCE_IMAGE).convert("RGBA")

    print("[INFO] Generando iconos estándar para Android...")
    for out_path, size in ANDROID_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        resized = im.resize(size, Image.Resampling.LANCZOS)
        resized.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    print("[INFO] Generando iconos circulares (round) para Android...")
    for out_path, size in ANDROID_ROUND_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        round_img = make_round_icon(im, size)
        round_img.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    print("[INFO] Generando capas foreground para Android Adaptive Icons...")
    for out_path, size in ANDROID_FOREGROUND_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        fg_img = make_adaptive_foreground(im, size)
        fg_img.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    # Generar definiciones XML para Adaptive Icons en mipmap-anydpi-v26
    anydpi_dir = ANDROID_RES / "mipmap-anydpi-v26"
    anydpi_dir.mkdir(parents=True, exist_ok=True)
    
    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n'
    )
    (anydpi_dir / "ic_launcher.xml").write_text(adaptive_xml, encoding="utf-8")
    (anydpi_dir / "ic_launcher_round.xml").write_text(adaptive_xml, encoding="utf-8")
    print(f"  -> mipmap-anydpi-v26/ic_launcher.xml y ic_launcher_round.xml creados.")

    print("[INFO] Generando iconos para iOS...")
    for out_path, size in IOS_ICONS.items():
        out_path.parent.mkdir(parents=True, exist_ok=True)
        resized = im.resize(size, Image.Resampling.LANCZOS)
        resized.save(out_path, format="PNG")
        print(f"  -> {out_path.relative_to(ROOT)} ({size[0]}x{size[1]})")

    print("[SUCCESS] ¡Todos los iconos de Android (legacy + round + adaptive v26) e iOS fueron generados exitosamente!")

if __name__ == "__main__":
    main()
