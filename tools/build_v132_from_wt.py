#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_v132_from_wt.py
Compila los APKs de Berea Interlineal v1.3.2 desde wt_v132 con el alternador Sol/Luna incorporado.
Copia los binarios a release_builds/v1.3.2/, regenera checksums.txt y limpia el worktree.
"""

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WT = ROOT / "wt_v132"
DEST = ROOT / "release_builds" / "v1.3.2"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def run_cmd(cmd: list[str], cwd: Path) -> None:
    print(f"\n[RUN] {' '.join(cmd)}")
    res = subprocess.run(cmd, cwd=str(cwd), shell=(os.name == "nt"))
    if res.returncode != 0:
        raise RuntimeError(f"Error ({res.returncode}) ejecutando: {' '.join(cmd)}")

def main():
    print("==================================================================")
    print(" Compilando Berea Interlineal v1.3.2 (Sol/Luna) desde wt_v132")
    print("==================================================================")

    # 1. Compilar Split ABIs
    print("\n[PASO 1/3] Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    # 2. Compilar Universal APK
    print("\n[PASO 2/3] Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=WT)

    # 3. Mapear y copiar artefactos
    print("\n[PASO 3/3] Copiando binarios a release_builds/v1.3.2/...")
    apk_dir = WT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.3.2_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.3.2_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.3.2_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.3.2_universal.apk",
    }

    DEST.mkdir(parents=True, exist_ok=True)
    for src_name, dst_name in mapping.items():
        src = apk_dir / src_name
        dst = DEST / dst_name
        if not src.exists():
            raise FileNotFoundError(f"No existe {src}")
        shutil.copy2(src, dst)
        size_mb = dst.stat().st_size / (1024 * 1024)
        print(f"  -> {dst_name} ({size_mb:.2f} MB, sha256: {sha256_file(dst)[:12]}...)")

    # 4. Regenerar checksums.txt preservando .ipa si existe
    lines = []
    for item in sorted(DEST.iterdir()):
        if item.is_file() and item.name != "checksums.txt" and not item.name.endswith(".sha256"):
            lines.append(f"{sha256_file(item)}  {item.name}")
    
    chk_file = DEST / "checksums.txt"
    chk_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\n[OK] Checksums guardados en {chk_file}")

    print("\n[EXITO] Compilación v1.3.2 finalizada con éxito.")

if __name__ == "__main__":
    main()
