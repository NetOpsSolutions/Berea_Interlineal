#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deploy_production_v133.py
Publica la release oficial de producción Berea Interlineal v1.3.3 en GitHub:
- draft: False (Visible inmediatamente para actualización OTA de usuarios en v1.3.2)
- prerelease: False
- Notas de versión detalladas con corrección de despliegue de versículos y sincronización instantánea Sol/Luna
- Sube los 4 APKs multi-arquitectura y checksums.txt
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

ROOT = Path(__file__).resolve().parent.parent
BUILDS_DIR = ROOT / "release_builds" / "v1.3.3"
REPO = "NetOpsSolutions/Berea_Interlineal"
TAG_NAME = "1.3.3"
RELEASE_TITLE = "Berea Interlineal v1.3.3 - Corrección en Despliegue de Versículos & Sincronización Sol/Luna"

RELEASE_NOTES = """# 🏛️ Berea Interlineal v1.3.3 — Optimización Crítica de Rendimiento y Fluidez

> **ESTADO DE PUBLICACIÓN**: **PRODUCCIÓN OFICIAL (Full Release)**.  
> Esta versión sustituye a la v1.3.2 y está disponible para actualización OTA directa e inmediata para todos los dispositivos.

---

## 🚀 Correcciones y Optimizaciones Principales

### 1. ⚡ Despliegue de Versículos Ultra-Fluido (Sin destellos ni saltos)
* **Corrección del destello oscuro**: Se eliminó la interpolación translúcida con fondo transparente (`AnimatedContainer`), erradicando cualquier sombra o destello oscuro al tocar y expandir versículos en modo claro (*Pergamino Diurno*).
* **Eliminación de re-empaquetado abrupto (*rewrap*)**: Se reemplazó `AnimatedSize` por renderizado directo condicional, logrando una apertura instantánea del análisis interlineal sin vibraciones ni saltos tipográficos.
* **Carga liviana de texto**: Los versículos en estado colapsado utilizan `Text.rich` de costo cero de cursor, activando `SelectableText.rich` únicamente cuando el usuario expande el versículo para interactuar.
* **Precompilación de expresiones regulares**: Expresión léxica de segmentación (`_tokenRegex`) precompilada a nivel de módulo, reduciendo la recolección de basura (*GC*) durante el desplazamiento continuo.

### 2. ☀️/🌙 Sincronización Instantánea del Alternador Sol/Luna
* **Respuesta a 0 ms**: El conmutador de tema en la barra superior (`AppBar`) ahora notifica directamente a `themeModeNotifier` con `themeAnimationDuration: Duration.zero`.
* **Cero latencia**: Transición instantánea entre el modo claro (*Pergamino Diurno*) y el modo oscuro (*Noche Alejandrina*) sin pantallas intermedias borrosas ni bloqueos en la interfaz.

### 3. 🧹 Depuración de la Pantalla de Ajustes
* **Eliminación de enlaces al Repositorio Oficial**: Retirado el bloque externo de GitHub en Ajustes para una experiencia de usuario limpia y enfocada al estudio bíblico.
* **Supresión del selector redundante**: Se retiró el interruptor secundario de modo oscuro en Ajustes, unificando el control en el icono Sol/Luna de la barra superior.

### 4. 🔤 Ajuste Tipográfico Fluido en Memoria
* **Slider desacoplado de disco**: El selector de tamaño de letra actualiza la escala en memoria en tiempo real a 60 fps continuos (`setReadingFontScaleTransient`) y persiste en base de datos SQLite únicamente al soltar el control (`onChangeEnd`), eliminando tirones de I/O.

---

## 📦 Paquetes APK Oficiales Multi-Arquitectura

| Archivo APK | Arquitectura CPU | Tamaño |
| :--- | :--- | :--- |
| `berea_interlineal_1.3.3_arm64-v8a.apk` | ARM 64-bit (Teléfonos y tablets modernos) | ~41.5 MB |
| `berea_interlineal_1.3.3_armeabi-v7a.apk` | ARM 32-bit (Dispositivos anteriores) | ~39.1 MB |
| `berea_interlineal_1.3.3_x86_64.apk` | Intel / AMD 64-bit (Emuladores y ChromeOS) | ~43.0 MB |
| `berea_interlineal_1.3.3_universal.apk` | Universal Multi-ABI (Todos los dispositivos) | ~75.9 MB |

Todos los binarios están firmados con la clave criptográfica oficial de producción `berea-release.jks` (`CN=NetOps Solutions`).  
Verifique la integridad de cada paquete con los hashes SHA-256 incluidos en `checksums.txt`.
"""

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

def main():
    token = get_token()
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Berea-Production-Deployer",
    }

    files_to_upload = [
        ("berea_interlineal_1.3.3_arm64-v8a.apk", "application/vnd.android.package-archive"),
        ("berea_interlineal_1.3.3_armeabi-v7a.apk", "application/vnd.android.package-archive"),
        ("berea_interlineal_1.3.3_x86_64.apk", "application/vnd.android.package-archive"),
        ("berea_interlineal_1.3.3_universal.apk", "application/vnd.android.package-archive"),
        ("checksums.txt", "text/plain; charset=utf-8"),
    ]

    print(f"\n[DEPLOY GITHUB] Consultando releases en {REPO} para tag '{TAG_NAME}'...")
    r = requests.get(f"https://api.github.com/repos/{REPO}/releases", headers=headers)
    if r.status_code != 200:
        raise RuntimeError(f"Error consultando releases: {r.status_code} {r.text}")

    existing_releases = r.json()
    release_obj = None
    for rel in existing_releases:
        if rel["tag_name"] in (TAG_NAME, f"v{TAG_NAME}"):
            release_obj = rel
            print(f"  -> Encontrada release existente (ID: {rel['id']}, draft: {rel['draft']})")
            break

    payload = {
        "tag_name": TAG_NAME,
        "name": RELEASE_TITLE,
        "body": RELEASE_NOTES,
        "draft": False,  # <-- OFICIAL: Visible inmediatamente para OTA
        "prerelease": False,
    }

    if release_obj is None:
        print(f"  -> Creando nueva release OFICIAL (draft: False) con tag {TAG_NAME}...")
        create_res = requests.post(
            f"https://api.github.com/repos/{REPO}/releases",
            headers=headers,
            json=payload,
        )
        if create_res.status_code not in (200, 201):
            raise RuntimeError(f"No se pudo crear release: {create_res.status_code} {create_res.text}")
        release_obj = create_res.json()
        print(f"  [OK] Release OFICIAL creada (ID: {release_obj['id']})")
    else:
        print(f"  -> Actualizando metadata de release existente (forzando draft: False)...")
        patch_res = requests.patch(
            f"https://api.github.com/repos/{REPO}/releases/{release_obj['id']}",
            headers=headers,
            json=payload,
        )
        if patch_res.status_code in (200, 201):
            release_obj = patch_res.json()
            print(f"  [OK] Release actualizada exitosamente a draft: False.")

    upload_url_template = release_obj["upload_url"].split("{")[0]
    existing_assets = {a["name"]: a["id"] for a in release_obj.get("assets", [])}

    print(f"\n[DEPLOY GITHUB] Subiendo binarios desde {BUILDS_DIR}...")
    for fname, mime_type in files_to_upload:
        fpath = BUILDS_DIR / fname
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

    print(f"\n[ÉXITO] Release {TAG_NAME} subida y publicada en PRODUCCIÓN OFICIAL (Draft: False).")

if __name__ == "__main__":
    main()
