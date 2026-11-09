#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_v140_release.py
Compila los APKs de release para Berea Interlineal v1.4.0:
- arm64-v8a
- armeabi-v7a
- x86_64
- universal
Calcula checksums SHA256 y los guarda en release_builds/v1.4.0/
"""

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT / "release_builds" / "v1.4.0"
FLUTTER_APK_DIR = ROOT / "build" / "app" / "outputs" / "flutter-apk"

def sha256_file(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def run_cmd(cmd: list[str]):
    print(f"[RUN] {' '.join(cmd)}")
    res = subprocess.run(cmd, cwd=ROOT, text=True, shell=True)
    if res.returncode != 0:
        print(f"[ERROR] Comando falló con código {res.returncode}")
        sys.exit(res.returncode)

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("==================================================================")
    print(" Compilando Berea Interlineal v1.4.0 (Split ABIs + Universal)")
    print("==================================================================")

    # 1. Compilar Split APKs
    print("\n[PASO 1/3] Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"])

    # 2. Compilar Universal APK
    print("\n[PASO 2/3] Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"])

    # 3. Mapear y Copiar Binarios
    print("\n[PASO 3/3] Recopilando binarios en release_builds/v1.4.0/...")
    mappings = [
        ("app-arm64-v8a-release.apk", "berea_interlineal_1.4.0_arm64-v8a.apk"),
        ("app-armeabi-v7a-release.apk", "berea_interlineal_1.4.0_armeabi-v7a.apk"),
        ("app-x86_64-release.apk", "berea_interlineal_1.4.0_x86_64.apk"),
        ("app-release.apk", "berea_interlineal_1.4.0_universal.apk"),
    ]

    checksums = []
    for src_name, dst_name in mappings:
        src = FLUTTER_APK_DIR / src_name
        dst = OUTPUT_DIR / dst_name
        if not src.exists():
            print(f"[ERROR] Archivo fuente no encontrado: {src}")
            sys.exit(1)
        shutil.copy2(src, dst)
        size_mb = dst.stat().st_size / (1024 * 1024)
        csum = sha256_file(dst)
        checksums.append(f"{csum}  {dst_name}")
        print(f"  -> {dst_name} ({size_mb:.2f} MB, sha256: {csum[:12]}...)")

    checksum_file = OUTPUT_DIR / "checksums.txt"
    with open(checksum_file, "w", encoding="utf-8") as f:
        f.write("\n".join(checksums) + "\n")
    print(f"\n[OK] Checksums guardados en {checksum_file}")
    print("[EXITO] Compilación v1.4.0 completada exitosamente.")

if __name__ == "__main__":
    main()
