#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
resign_and_verify_all.py
Refirma todos los APKs de las versiones con la clave oficial de producción:
- android/berea-release.jks (alias: berea_key)
- DN esperado: CN=NetOps Solutions, OU=Mobile Development, O=NetOps, L=Caracas, ST=Miranda, C=VE
- Cert SHA-256 esperado: 72a99b196f453a6b84795e179bdceb5d1e70fe0cd51529eef93fcf5d29fe7d78
Recalcula los checksums.txt y redespliega las releases draft a GitHub.
"""

import glob
import hashlib
import os
import subprocess
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(line_buffering=True)
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent
APKSIGNER = Path(r"C:\Users\User\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat")
KEYSTORE = ROOT / "android" / "berea-release.jks"
KEY_ALIAS = "berea_key"
KEY_PASS = "BereaInterlineal#2026@ProductionSecure"
EXPECTED_CERT_SHA256 = "72a99b196f453a6b84795e179bdceb5d1e70fe0cd51529eef93fcf5d29fe7d78"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def sign_apk(apk_path: Path):
    print(f"  -> Refirmando {apk_path.name}...")
    cmd = [
        str(APKSIGNER), "sign",
        "--ks", str(KEYSTORE),
        "--ks-key-alias", KEY_ALIAS,
        "--ks-pass", f"pass:{KEY_PASS}",
        "--key-pass", f"pass:{KEY_PASS}",
        str(apk_path)
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Error firmando {apk_path.name}: {res.stderr}")

def verify_apk(apk_path: Path) -> str:
    cmd = [str(APKSIGNER), "verify", "--print-certs", str(apk_path)]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Firma inválida en {apk_path.name}: {res.stderr}")
    sha256 = ""
    for line in res.stdout.splitlines():
        if "Signer #1 certificate SHA-256 digest:" in line:
            sha256 = line.split(":", 1)[1].strip()
            break
    return sha256

def update_checksums(version_dir: Path):
    lines = []
    for item in sorted(version_dir.iterdir()):
        if item.is_file() and item.name.endswith(".apk"):
            lines.append(f"{sha256_file(item)}  {item.name}")
    chk_file = version_dir / "checksums.txt"
    chk_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"  [OK] Checksums actualizados en {chk_file}")

def main():
    print("==================================================================")
    print(" AUDITORÍA Y REFIRMADO OFICIAL DE APKs (BEREA INTERLINEAL)")
    print("==================================================================")
    
    # 1. Refirmar v1.3.5 y v1.3.7
    for ver in ["v1.3.5", "v1.3.7"]:
        v_dir = ROOT / "release_builds" / ver
        print(f"\n[PASO 1] Procesando {ver}...")
        for apk in sorted(v_dir.glob("*.apk")):
            sign_apk(apk)
            cert_sha = verify_apk(apk)
            if cert_sha.lower() != EXPECTED_CERT_SHA256.lower():
                raise ValueError(f"Firma incorrecta en {apk.name}: {cert_sha} != {EXPECTED_CERT_SHA256}")
            print(f"    ✅ Firma verificada: {cert_sha[:16]}... (CN=NetOps Solutions)")
        update_checksums(v_dir)

    # 2. Auditar todas las versiones
    print("\n[PASO 2] Auditoría final de todas las versiones...")
    for ver in ["v1.3.2", "v1.3.3", "v1.3.5", "v1.3.7", "v1.4.0"]:
        v_dir = ROOT / "release_builds" / ver
        print(f"\n--- Auditoría {ver} ---")
        for apk in sorted(v_dir.glob("*.apk")):
            cert_sha = verify_apk(apk)
            is_match = (cert_sha.lower() == EXPECTED_CERT_SHA256.lower())
            status = "✅ OK" if is_match else "❌ MISMATCH"
            print(f"  {apk.name:42} : {status} (Cert: {cert_sha[:16]}...)")
            if not is_match:
                raise ValueError(f"Falla de firma en {ver}/{apk.name}")

    print("\n==================================================================")
    print(" 🎉 TODOS LOS APKs ESTÁN FIRMADOS CON LA CLAVE OFICIAL DE PRODUCCIÓN")
    print("==================================================================")

if __name__ == "__main__":
    main()
