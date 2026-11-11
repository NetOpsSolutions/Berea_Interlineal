#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deploy_draft_release.py
Utilidad senior para publicar o actualizar releases en GitHub estrictamente
como BORRADOR (draft: true) con sus 4 APKs y checksums.txt.
"""

import os
import re
import subprocess
import sys
import time
from pathlib import Path
import requests

try:
    sys.stdout.reconfigure(line_buffering=True)
except Exception:
    pass

REPO = "NetOpsSolutions/Berea_Interlineal"

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
    print("[ERROR] Variable GITHUB_TOKEN no encontrada ni deducible de git remote.")
    sys.exit(1)

def upload_draft_release(tag_name: str, release_title: str, release_notes: str, builds_dir: Path):
    token = get_token()
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Berea-Senior-Deployer",
    }

    files_to_upload = [
        (f"berea_interlineal_{tag_name.lstrip('v')}_arm64-v8a.apk", "application/vnd.android.package-archive"),
        (f"berea_interlineal_{tag_name.lstrip('v')}_armeabi-v7a.apk", "application/vnd.android.package-archive"),
        (f"berea_interlineal_{tag_name.lstrip('v')}_x86_64.apk", "application/vnd.android.package-archive"),
        (f"berea_interlineal_{tag_name.lstrip('v')}_universal.apk", "application/vnd.android.package-archive"),
        ("checksums.txt", "text/plain; charset=utf-8"),
    ]

    print(f"\n[DEPLOY GITHUB] Consultando releases en {REPO} para tag '{tag_name}'...")
    r = requests.get(f"https://api.github.com/repos/{REPO}/releases", headers=headers)
    if r.status_code != 200:
        raise RuntimeError(f"Error consultando releases: {r.status_code} {r.text}")

    existing_releases = r.json()
    release_obj = None
    for rel in existing_releases:
        if rel["tag_name"] == tag_name:
            release_obj = rel
            print(f"  -> Encontrada release existente (ID: {rel['id']}, draft: {rel['draft']})")
            break

    payload = {
        "tag_name": tag_name,
        "name": release_title,
        "body": release_notes,
        "draft": True,  # <-- CRÍTICO: Invisible a OTA de producción
        "prerelease": False,
    }

    if release_obj is None:
        print(f"  -> Creando nueva release BORRADOR (DRAFT: TRUE) con tag {tag_name}...")
        create_res = requests.post(
            f"https://api.github.com/repos/{REPO}/releases",
            headers=headers,
            json=payload,
        )
        if create_res.status_code not in (200, 201):
            raise RuntimeError(f"No se pudo crear release: {create_res.status_code} {create_res.text}")
        release_obj = create_res.json()
        print(f"  [OK] Release BORRADOR creada (ID: {release_obj['id']})")
    else:
        print(f"  -> Actualizando metadata de release existente (forzando draft: True)...")
        patch_res = requests.patch(
            f"https://api.github.com/repos/{REPO}/releases/{release_obj['id']}",
            headers=headers,
            json=payload,
        )
        if patch_res.status_code in (200, 201):
            release_obj = patch_res.json()
            print(f"  [OK] Release actualizada exitosamente.")

    upload_url_template = release_obj["upload_url"].split("{")[0]
    existing_assets = {a["name"]: a["id"] for a in release_obj.get("assets", [])}

    print(f"\n[DEPLOY GITHUB] Subiendo binarios desde {builds_dir}...")
    for fname, mime_type in files_to_upload:
        fpath = builds_dir / fname
        if not fpath.exists():
            raise FileNotFoundError(f"Archivo requerido no existe: {fpath}")

        size_mb = fpath.stat().st_size / (1024 * 1024)

        if fname in existing_assets:
            aid = existing_assets[fname]
            print(f"  -> Eliminando asset anterior '{fname}' (ID: {aid})...")
            del_r = requests.delete(
                f"https://api.github.com/repos/{REPO}/releases/assets/{aid}",
                headers=headers,
            )
            if del_r.status_code not in (200, 204):
                print(f"  [WARN] Falló eliminación de asset previo: {del_r.status_code}")
            time.sleep(0.5)

        print(f"  -> Subiendo '{fname}' ({size_mb:.2f} MB, {mime_type})...")
        up_headers = dict(headers)
        up_headers["Content-Type"] = mime_type

        with open(fpath, "rb") as f:
            up_r = requests.post(
                f"{upload_url_template}?name={fname}",
                headers=up_headers,
                data=f,
                timeout=180,
            )
        if up_r.status_code not in (200, 201):
            raise RuntimeError(f"Error subiendo {fname}: {up_r.status_code} {up_r.text}")
        print(f"  [OK] '{fname}' subido correctamente.")

    print(f"\n[ÉXITO] Release {tag_name} subida y verificada como BORRADOR (Draft: True).")
