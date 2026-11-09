#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
upload_v140_draft_release.py
Crea y publica la release v1.4.0 en GitHub Releases estrictamente como BORRADOR (DRAFT: TRUE),
protegiendo la versión 1.3.1 en producción de alertas prematuras del actualizador OTA.
"""

import os
import re
import subprocess
import sys
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parent.parent
BUILDS_DIR = ROOT / "release_builds" / "v1.4.0"
REPO = "NetOpsSolutions/Berea_Interlineal"
TAG_NAME = "v1.4.0"
RELEASE_TITLE = "📜 Berea Interlineal v1.4.0 [BORRADOR EN DESARROLLO] • Edición Enciclopedia y Persiana"

FILES_TO_UPLOAD = [
    ("berea_interlineal_1.4.0_arm64-v8a.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.4.0_armeabi-v7a.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.4.0_x86_64.apk", "application/vnd.android.package-archive"),
    ("berea_interlineal_1.4.0_universal.apk", "application/vnd.android.package-archive"),
    ("checksums.txt", "text/plain; charset=utf-8"),
]

RELEASE_NOTES = """# 📜 Berea Interlineal v1.4.0 — Edición Enciclopedia Histórica y Persiana de Estudio

> **ESTADO DE PUBLICACIÓN**: **BORRADOR PRIVADO (DRAFT)**.  
> Esta versión se encuentra en fase de validación y auditoría técnica.  
> Gracias al atributo `draft: true`, no dispara notificaciones OTA automáticas en clientes v1.3.1 / v1.3.0 en producción.

---

## 🧭 Novedades Principales de la Versión 1.4.0

### 🚪 1. Menú Lateral Tipo Persiana (`BereaDrawer`) & Ergonomía Híbrida
* **Enfoque B (Modelo Híbrido)**: La barra inferior se simplifica a 3 accesos de lectura diaria ultra-rápidos:
  - 📖 **Biblia** (Lector continuo con hebreo/griego y español)
  - 🔤 **Diccionario** (Léxico Strong y concordancia unificada)
  - 📑 **Mi Estudio** (Marcadores, notas personales e historial SQLite)
* **Menú Lateral Persiana (☰)**: Deslizable desde el borde izquierdo o accesible con el botón de hamburguesa en el AppBar:
  - 📜 **Resumen de los 66 Libros**
  - 👤 **Biografías de Escritores Sagrados**
  - 🔍 **Búsqueda Global Unificada**
  - 🏷️ **Filtros Teológicos Rápidos** (Promesas, Mandamientos, Atributos, Advertencias, Profecía)
  - ⚙️ **Ajustes del Sistema**
  - 🧭 **Guía de Uso v1.4.0**

### 📜 2. Módulo Especial: Resumen Bíblico de los 66 Libros Canónicos
* **Fichas Técnicas Exhaustivas** con rigor histórico-gramatical (ISBE, Jamieson-Fausset-Brown, Reina-Valera 1960):
  1. 👤 **Autor / Escritor**: Identidad bíblica y vocación original.
  2. 🎯 **Destinatarios Originales**: Audiencia y contexto receptor inicial.
  3. 📅 **Fecha y Rango de Redacción**: Cronología precisa (a.C. / d.C.).
  4. 🏛️ **Contexto Histórico, Político y Cultural**: Situación de Israel y los imperios dominantes.
  5. ⭐ **Temas Centrales y Versículo Clave**: Ejes doctrinales y botón de salto directo al interlineal.
  6. 🌱 **Aplicación Práctica para Hoy**: Tres lecciones espirituales concretas para la vida devocional diaria.
* **Acceso Dual**: Desde el menú lateral persiana y desde el lector bíblico mediante el botón de pergamino en el AppBar sin perder la posición de lectura.

### 👤 3. Módulo de Biografías de Escritores Sagrados & Lectura Rápida
* Perfil biográfico exhaustivo de los **35 escritores canónicos** (Moisés, David, Isaías, Lucas, Pablo, Pedro, Juan...).
* Nombres en grafía original (Hebreo y Griego) con **códigos Strong interactivos** que abren directamente el léxico.
* **Versículos de llamamiento y testimonio interactivos**:
  - 👁️ **Ventana de Lectura Interlineal Rápida**: Diálogo modal emergente con palabras en hebreo/griego, lemas, Strongs y traducción sin salir de la ficha.
  - 📖 **Salto Canónico Directo**: Botón para saltar directamente a la Biblia Interlineal en pantalla completa con un solo toque.

### 🪟 4. Ventana Modal de Lectura Rápida (`QuickVerseModalSheet`) y Salto Canónico Directo
* **Lectura In Situ**: Consulta instantáneamente el texto bíblico interlineal (palabras hebreas y griegas con sus lemas, códigos Strong y traducción) sin salir de la ficha biográfica del autor ni del resumen del libro.
* **Salto Canónico Universal**: Desplazamiento fluido y directo a la Biblia Interlineal en pantalla completa con cierre coordinado de diálogos y pantallas intermedias.

### 🧭 5. Guía de Uso Interactiva Integral (9 Pasos)
* Recorrido didáctico coordinado de 9 pasos que presenta el nuevo menú lateral persiana (☰), las fichas analíticas de los 66 libros canónicos, las biografías de los 35 escritores sagrados y las herramientas de estudio personal.
* Repetible en cualquier momento desde el menú lateral persiana o desde *Ajustes ➔ Ver guía de uso*.

---

## 🔒 Verificación Criptográfica de Binarios (SHA-256)
Consulte el archivo adjunto `checksums.txt` para verificar la integridad de cada paquete APK firmado con la clave oficial de producción `berea-release.jks`.
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
        "User-Agent": "Berea-v140-Deployer",
    }

    print(f"[INFO] Consultando releases existentes en {REPO}...")
    r = requests.get(f"https://api.github.com/repos/{REPO}/releases", headers=headers)
    if r.status_code != 200:
        print(f"[ERROR] Error consultando releases: {r.status_code} {r.text}")
        sys.exit(1)

    existing_releases = r.json()
    release_obj = None
    for rel in existing_releases:
        if rel["tag_name"] == TAG_NAME:
            release_obj = rel
            print(f"[INFO] Encontrada release existente con tag {TAG_NAME} (ID: {rel['id']}, draft: {rel['draft']})")
            break

    payload = {
        "tag_name": TAG_NAME,
        "name": RELEASE_TITLE,
        "body": RELEASE_NOTES,
        "draft": True,  # <-- CRÍTICO: Release privada invisible al actualizador OTA
        "prerelease": False,
    }

    if release_obj is None:
        print(f"[INFO] Creando nueva release BORRADOR (DRAFT: TRUE) con tag {TAG_NAME}...")
        create_res = requests.post(
            f"https://api.github.com/repos/{REPO}/releases",
            headers=headers,
            json=payload,
        )
        if create_res.status_code not in (200, 201):
            print(f"[ERROR] No se pudo crear la release: {create_res.status_code} {create_res.text}")
            sys.exit(1)
        release_obj = create_res.json()
        print(f"[EXITO] Release BORRADOR creada con éxito (ID: {release_obj['id']})")
    else:
        # Asegurar que esté configurada como draft: True
        print(f"[INFO] Actualizando metadata de release existente (forzando draft: True)...")
        patch_res = requests.patch(
            f"https://api.github.com/repos/{REPO}/releases/{release_obj['id']}",
            headers=headers,
            json=payload,
        )
        if patch_res.status_code in (200, 201):
            release_obj = patch_res.json()
            print(f"[EXITO] Release actualizada.")

    upload_url_template = release_obj["upload_url"].split("{")[0]
    existing_assets = {a["name"]: a["id"] for a in release_obj.get("assets", [])}

    print("\n[INFO] Subiendo binarios APK compilados a la release Borrador...")
    for fname, mime_type in FILES_TO_UPLOAD:
        fpath = BUILDS_DIR / fname
        if not fpath.exists():
            print(f"[ERROR] Archivo no encontrado en builds: {fpath}")
            sys.exit(1)

        size_mb = fpath.stat().st_size / (1024 * 1024)

        if fname in existing_assets:
            aid = existing_assets[fname]
            print(f"  -> Eliminando asset anterior '{fname}' (ID: {aid})...")
            del_r = requests.delete(
                f"https://api.github.com/repos/{REPO}/releases/assets/{aid}",
                headers=headers,
            )
            if del_r.status_code not in (200, 204):
                print(f"  [WARN] No se pudo borrar asset anterior: {del_r.status_code}")

        print(f"  -> Subiendo '{fname}' ({size_mb:.2f} MB, {mime_type})...")
        up_headers = dict(headers)
        up_headers["Content-Type"] = mime_type

        with open(fpath, "rb") as f:
            up_r = requests.post(
                f"{upload_url_template}?name={fname}",
                headers=up_headers,
                data=f,
            )

        if up_r.status_code in (200, 201):
            created = up_r.json()
            print(f"     [OK] Subido con éxito (ID: {created['id']})")
        else:
            print(f"     [ERROR] Falló la subida ({up_r.status_code}): {up_r.text}")
            sys.exit(1)

    print("\n==================================================================")
    print(" DESPLIEGUE A GITHUB COMPLETADO EXITOSAMENTE")
    print(f" Tag: {TAG_NAME}")
    print(f" Estado: DRAFT = {release_obj['draft']} (Borrador Privado)")
    print(f" URL: {release_obj['html_url']}")
    print("==================================================================")

if __name__ == "__main__":
    main()
