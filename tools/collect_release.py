#!/usr/bin/env python3
"""
collect_release.py — Script de empaquetado para release_builds/v1.3.1
Copia los APKs desde build/app/outputs/flutter-apk/ a release_builds/v1.3.1/
y renombra con el esquema logos_k_logos_{VERSION}_{ABI}.apk.
Genera checksums SHA-256 para verificación de integridad.

Uso:
    python tools/collect_release.py

Ejecutar desde la raíz del proyecto Flutter.
"""

import hashlib
import shutil
import sys
from pathlib import Path

VERSION = "1.3.1"
BUILD_NUMBER = "5"

# Carpetas
ROOT = Path(__file__).parent.parent
SRC = ROOT / "build" / "app" / "outputs" / "flutter-apk"
DEST = ROOT / "release_builds" / f"v{VERSION}"

# Mapa de nombres originales → nombres de lanzamiento
APK_MAP = {
    "app-arm64-v8a-release.apk":  f"logos_k_logos_{VERSION}_arm64-v8a.apk",
    "app-armeabi-v7a-release.apk": f"logos_k_logos_{VERSION}_armeabi-v7a.apk",
    "app-x86_64-release.apk":     f"logos_k_logos_{VERSION}_x86_64.apk",
    "app-universal-release.apk":  f"logos_k_logos_{VERSION}_universal.apk",
    "app-release.apk":            f"logos_k_logos_{VERSION}_universal.apk",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    collected = []

    for src_name, dest_name in APK_MAP.items():
        src_path = SRC / src_name
        if not src_path.exists():
            print(f"[SKIP] No encontrado: {src_name} - omitido.")
            continue
        dest_path = DEST / dest_name
        shutil.copy2(src_path, dest_path)
        size_mb = dest_path.stat().st_size / (1024 * 1024)
        checksum = sha256(dest_path)
        collected.append((dest_name, size_mb, checksum))
        print(f"[OK] {dest_name}  ({size_mb:.1f} MB)")

    if not collected:
        print("[ERROR] No se encontraron APKs. Ejecuta 'flutter build apk --release --split-per-abi' primero.")
        sys.exit(1)

    # Escribir checksums.txt
    checksums_path = DEST / "checksums.txt"
    with open(checksums_path, "w", encoding="utf-8") as f:
        f.write(f"# Logos K Logos v{VERSION}+{BUILD_NUMBER} -- SHA-256 Checksums\n")
        f.write(f"# Generado automaticamente por tools/collect_release.py\n\n")
        for name, size_mb, checksum in collected:
            f.write(f"{checksum}  {name}  ({size_mb:.1f} MB)\n")

    print(f"\n[INFO] Checksums guardados en: {checksums_path}")
    print(f"\n[INFO] Release v{VERSION} lista en: {DEST}")


if __name__ == "__main__":
    main()
