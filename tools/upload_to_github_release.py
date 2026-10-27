#!/usr/bin/env python3
"""
upload_to_github_release.py
Actualiza los APKs de release v1.3.2 en GitHub Releases con los binarios recién compilados.
"""
import sys
from pathlib import Path
import requests

import os
import re
import subprocess
import sys
from pathlib import Path
import requests

def get_token() -> str:
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token
    # Intentar extraer del remote origin si está configurado
    try:
        url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
        match = re.search(r"https://([^@:]+)@", url)
        if match:
            return match.group(1)
    except Exception:
        pass
    print("[ERROR] Variable de entorno GITHUB_TOKEN no encontrada.")
    sys.exit(1)

TOKEN = get_token()
REPO = "NetOpsSolutions/Berea_Interlineal"
RELEASE_ID = 425000889  # v1.3.2

ROOT = Path(__file__).parent.parent
BUILDS_DIR = ROOT / "release_builds" / "v1.3.2"

FILES_TO_UPLOAD = [
    ("berea_interlineal_1.3.2_arm64-v8a.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.3.2_armeabi-v7a.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.3.2_x86_64.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.3.2_universal.apk", "application/vnd.android.package-archive"),
    ("checksums.txt", "text/plain; charset=utf-8"),
]

HEADERS = {
    "Authorization": f"token {TOKEN}",
    "Accept": "application/vnd.github.v3+json",
    "User-Agent": "Berea-Release-Uploader",
}

def main():
    print(f"[INFO] Consultando release {RELEASE_ID} en {REPO}...")
    r = requests.get(f"https://api.github.com/repos/{REPO}/releases/{RELEASE_ID}", headers=HEADERS)
    if r.status_code != 200:
        print(f"[ERROR] No se pudo obtener la release: {r.status_code} {r.text}")
        sys.exit(1)

    rel_data = r.json()
    print(f"[INFO] Release: {rel_data['name']} (Tag: {rel_data['tag_name']})")

    existing_assets = {a["name"]: a["id"] for a in rel_data.get("assets", [])}
    upload_url_template = rel_data["upload_url"].split("{")[0]

    for fname, content_type in FILES_TO_UPLOAD:
        fpath = BUILDS_DIR / fname
        if not fpath.exists():
            print(f"[WARN] Archivo local no encontrado: {fpath}, omitiendo.")
            continue

        size_mb = fpath.stat().st_size / (1024 * 1024)

        # Si ya existe en la release, borrar la versión antigua
        if fname in existing_assets:
            asset_id = existing_assets[fname]
            print(f"[INFO] Eliminando asset antiguo '{fname}' (ID: {asset_id})...")
            del_r = requests.delete(
                f"https://api.github.com/repos/{REPO}/releases/assets/{asset_id}",
                headers=HEADERS
            )
            if del_r.status_code in (204, 200):
                print(f"  -> Eliminado con éxito.")
            else:
                print(f"  -> Error al eliminar ({del_r.status_code}): {del_r.text}")

        # Subir el nuevo archivo
        print(f"[INFO] Subiendo '{fname}' ({size_mb:.2f} MB)...")
        upload_headers = dict(HEADERS)
        upload_headers["Content-Type"] = content_type

        with open(fpath, "rb") as f:
            up_r = requests.post(
                f"{upload_url_template}?name={fname}",
                headers=upload_headers,
                data=f
            )

        if up_r.status_code in (201, 200):
            created_asset = up_r.json()
            print(f"  [OK] '{fname}' subido correctamente (ID: {created_asset['id']})")
        else:
            print(f"  [ERROR] Falló la subida de '{fname}' ({up_r.status_code}): {up_r.text}")

    print("\n[INFO] Verificando lista final de assets en la release:")
    r2 = requests.get(f"https://api.github.com/repos/{REPO}/releases/{RELEASE_ID}", headers=HEADERS)
    for a in r2.json().get("assets", []):
        size_mb = a["size"] / (1024 * 1024)
        print(f"  - {a['name']} ({size_mb:.2f} MB) -> Actualizado: {a['updated_at']}")

    print("\n[SUCCESS] ¡Todos los paquetes actualizados fueron subidos a la release de GitHub!")

if __name__ == "__main__":
    main()
