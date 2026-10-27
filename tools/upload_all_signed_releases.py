#!/usr/bin/env python3
"""
tools/upload_all_signed_releases.py
Automatiza la sustitución de APKs antiguos por los nuevos APKs refirmados con la clave
de producción en GitHub Releases para las versiones 1.3.0, 1.3.1 y 1.3.2.
Preserva intactos todos los artefactos de iOS (.ipa y .sha256).
"""
import os
import re
import sys
import time
import subprocess
from pathlib import Path
import requests

def get_token() -> str:
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token
    try:
        url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
        match = re.search(r"https://([^@:]+)@", url)
        if match:
            return match.group(1)
    except Exception:
        pass
    print("[ERROR] No se pudo obtener el token de GitHub desde GITHUB_TOKEN ni de git remote.")
    sys.exit(1)

TOKEN = get_token()
REPO = "NetOpsSolutions/Berea_Interlineal"
ROOT = Path(__file__).resolve().parent.parent

HEADERS = {
    "Authorization": f"token {TOKEN}",
    "Accept": "application/vnd.github+json",
    "User-Agent": "Berea-Production-Signer",
}

# Configuración de releases
RELEASES = [
    {
        "tag": "1.3.0",
        "folder": ROOT / "release_builds" / "v1.3.0",
        "files": [
            ("app-arm64-v8a-release.apk", "application/vnd.android.package-archive"),
            ("app-armeabi-v7a-release.apk", "application/vnd.android.package-archive"),
            ("app-x86_64-release.apk", "application/vnd.android.package-archive"),
            ("app-universal-release.apk", "application/vnd.android.package-archive"),
            ("app-release.apk", "application/vnd.android.package-archive"),
            ("checksums.txt", "text/plain; charset=utf-8"),
        ],
    },
    {
        "tag": "1.3.1",
        "folder": ROOT / "release_builds" / "v1.3.1",
        "files": [
            ("logos_k_logos_1.3.1_arm64-v8a.apk", "application/vnd.android.package-archive"),
            ("logos_k_logos_1.3.1_armeabi-v7a.apk", "application/vnd.android.package-archive"),
            ("logos_k_logos_1.3.1_x86_64.apk", "application/vnd.android.package-archive"),
            ("logos_k_logos_1.3.1_universal.apk", "application/vnd.android.package-archive"),
            ("checksums.txt", "text/plain; charset=utf-8"),
        ],
    },
    {
        "tag": "v1.3.2",
        "folder": ROOT / "release_builds" / "v1.3.2",
        "files": [
            ("berea_interlineal_1.3.2_arm64-v8a.apk", "application/vnd.android.package-archive"),
            ("berea_interlineal_1.3.2_armeabi-v7a.apk", "application/vnd.android.package-archive"),
            ("berea_interlineal_1.3.2_x86_64.apk", "application/vnd.android.package-archive"),
            ("berea_interlineal_1.3.2_universal.apk", "application/vnd.android.package-archive"),
            ("checksums.txt", "text/plain; charset=utf-8"),
        ],
    },
]

def main():
    print("=" * 65)
    print("SUBIDA AUTOMATIZADA DE RELEASES FIRMADOS A GITHUB")
    print(f"Repositorio: {REPO}")
    print("=" * 65)

    for rel_cfg in RELEASES:
        tag = rel_cfg["tag"]
        folder = rel_cfg["folder"]
        files = rel_cfg["files"]

        print(f"\n---> Consultando Release para tag '{tag}'...")
        r = requests.get(f"https://api.github.com/repos/{REPO}/releases/tags/{tag}", headers=HEADERS)
        if r.status_code != 200:
            print(f"[ERROR] No se pudo obtener la release para tag {tag}: {r.status_code} {r.text}")
            continue

        rel_data = r.json()
        release_id = rel_data["id"]
        print(f"[OK] Release encontrada: '{rel_data['name']}' (ID: {release_id})")

        existing_assets = {a["name"]: a["id"] for a in rel_data.get("assets", [])}
        upload_url_template = rel_data["upload_url"].split("{")[0]

        files_to_update = {fname for fname, _ in files}

        # 1. Eliminar assets viejos que se van a reemplazar
        for fname in files_to_update:
            if fname in existing_assets:
                asset_id = existing_assets[fname]
                print(f"[INFO] Eliminando asset previo '{fname}' (ID: {asset_id})...")
                del_r = requests.delete(
                    f"https://api.github.com/repos/{REPO}/releases/assets/{asset_id}",
                    headers=HEADERS
                )
                if del_r.status_code in (204, 200):
                    print(f"  [OK] Asset previo eliminado.")
                else:
                    print(f"  [WARN] Código al eliminar: {del_r.status_code}")
                time.sleep(0.5)

        # 2. Subir los nuevos archivos refirmados
        for fname, content_type in files:
            fpath = folder / fname
            if not fpath.exists():
                print(f"[WARN] Archivo local no encontrado: {fpath}, omitiendo.")
                continue

            size_mb = fpath.stat().st_size / (1024 * 1024)
            print(f"[SUBIENDO] '{fname}' ({size_mb:.2f} MB)...")

            upload_headers = dict(HEADERS)
            upload_headers["Content-Type"] = content_type

            max_retries = 3
            success = False
            for attempt in range(1, max_retries + 1):
                try:
                    with open(fpath, "rb") as f:
                        up_r = requests.post(
                            f"{upload_url_template}?name={fname}",
                            headers=upload_headers,
                            data=f,
                            timeout=300
                        )
                    if up_r.status_code in (201, 200):
                        asset_info = up_r.json()
                        print(f"  [EXITO] '{fname}' subido correctamente (ID: {asset_info['id']})")
                        success = True
                        break
                    else:
                        print(f"  [INTENTO {attempt}] Error {up_r.status_code}: {up_r.text}")
                except Exception as e:
                    print(f"  [INTENTO {attempt}] Excepción de red: {e}")
                time.sleep(2)

            if not success:
                print(f"[ERROR CRITICO] No se pudo subir '{fname}' después de {max_retries} intentos.")

        # 3. Validar lista final de assets en la release
        print(f"\n[VALIDACION] Assets en release '{tag}':")
        r_check = requests.get(f"https://api.github.com/repos/{REPO}/releases/{release_id}", headers=HEADERS)
        for a in r_check.json().get("assets", []):
            size_mb = a["size"] / (1024 * 1024)
            print(f"  - {a['name']:<42} {size_mb:>6.2f} MB | Descargas: {a['download_count']}")

    print("\n" + "=" * 65)
    print("¡PROCESO DE SUBIDA COMPLETADO EXITOSAMENTE PARA TODAS LAS VERSIONES!")
    print("=" * 65)

if __name__ == "__main__":
    main()
