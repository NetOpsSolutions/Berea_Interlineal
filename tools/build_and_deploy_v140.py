#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v140.py
Compila y despliega la versión definitiva Berea Interlineal v1.4.0 (Edición Enciclopedia y Persiana):
- Incorpora todo lo de v1.3.5 (100% Derivaciones y STEPBible, cero guiones)
- Incorpora todo lo de v1.3.7 (Similitudes teológicas, familias derivadas, strong_relations)
- Incorpora todo lo exclusivo de v1.4.0 (BereaDrawer ☰, Barra 3 botones, Resumen 66 Libros, Biografías de Escritores, Guía de 9 pasos)
Compila los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
genera checksums.txt en release_builds/v1.4.0/ y actualiza la release v1.4.0 como BORRADOR (DRAFT: TRUE).
"""

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(line_buffering=True)
except Exception:
    pass

sys.path.append(str(Path(__file__).resolve().parent))
from deploy_draft_release import upload_draft_release

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "release_builds" / "v1.4.0"
TAG_NAME = "v1.4.0"
RELEASE_TITLE = "📜 Berea Interlineal v1.4.0 [BORRADOR EN DESARROLLO] • Edición Enciclopedia y Persiana"

RELEASE_NOTES = """# 📜 Berea Interlineal v1.4.0 — Edición Enciclopedia Histórica y Persiana de Estudio

> **ESTADO DE PUBLICACIÓN**: **BORRADOR PRIVADO (DRAFT: TRUE)**.  
> Esta versión se encuentra en fase de validación técnica y consolidación integral.  
> Gracias al atributo `draft: true`, no dispara notificaciones OTA automáticas en clientes v1.3.1 en producción.

---

## 🧭 Novedades Consolidadas de la Versión 1.4.0

### 1. De la Versión 1.3.5 (Edición Léxica)
* **100% de Derivaciones y Etimologías pobladas** en las 8.674 palabras en Hebreo y 5.523 palabras en Griego.
* **100% del Léxico Académico Extendido (STEPBible / Tyndale House Cambridge)** integrado en español.
* **Supresión total de guiones vacíos «—»** y distintivo solemne para *«Raíz primaria (no proviene de otra palabra bíblica)»*.
* **Hipervínculos táctiles activos** en todas las menciones a códigos Strong dentro de las derivaciones.

### 2. De la Versión 1.3.7 (Edición Exegética)
* **Similitudes, Sinónimos y Comparaciones Teológicas**: Fichas exegéticas con pastillas táctiles doradas y análisis doctrinal de términos afines en Hebreo (*érets* vs *adamáh* vs *tebél*; *bará* vs *asáh* vs *yatsár*) y Griego (*agápē* vs *philía* vs *storgē*; *lógos* vs *rhēma*; *zōē* vs *bíos* vs *psychē*).
* **Familia de Palabras Derivadas (Árbol Léxico)**: Muestra visual interactiva de todas las palabras bíblicas nacidas de la misma raíz.
* **Tabla Relacional SQLite `strong_relations`** con índices optimizados.

### 3. Exclusivo de la Versión 1.4.0 (Enciclopedia Bíblica y Persiana)
* 🚪 **Menú Lateral Persiana (`BereaDrawer` ☰)**: Acceso ágil a los 66 libros, 35 biografías, búsqueda global, filtros teológicos y guía.
* ⚡ **Barra Inferior Rápida de 3 Botones (Enfoque B)**: Simplificada para lectura diaria (Biblia, Diccionario, Mi Estudio).
* 📜 **Resumen Canónico de los 66 Libros**: Fichas analíticas completas con autor, destinatarios, fecha, contexto histórico, temas centrales y aplicación práctica.
* 👤 **Biografías de los 35 Escritores Sagrados**: Grafía original hebrea/griega, Strong interactivo y ventana modal de lectura rápida (`QuickVerseModalSheet`).
* 🧭 **Guía de Uso Interactiva Integral de 9 Pasos**: Didáctica y repetible en cualquier momento.
* ☀️/🌙 **Alternador Rápido Sol/Luna** en AppBar de todas las secciones principales.

---

## 🔒 Integridad Criptográfica (SHA-256)
Consulte el archivo adjunto `checksums.txt` para verificar los hashes SHA-256 de los 4 APKs firmados con la clave oficial `berea-release.jks`.
"""

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

def compile_v140():
    print("\n[1/3] Compilando APKs de Berea Interlineal v1.4.0...")
    print("  -> Verificando estática con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=ROOT)

    print("  -> Ejecutando pruebas unitarias...")
    run_cmd(["flutter", "test"], cwd=ROOT)

    print("  -> Compilando Split APKs...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=ROOT)

    print("  -> Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=ROOT)

    apk_dir = ROOT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.4.0_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.4.0_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.4.0_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.4.0_universal.apk",
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

    lines = []
    for item in sorted(DEST.iterdir()):
        if item.is_file() and item.name != "checksums.txt" and not item.name.endswith(".sha256"):
            lines.append(f"{sha256_file(item)}  {item.name}")
    chk_file = DEST / "checksums.txt"
    chk_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"  [OK] Checksums guardados en {chk_file}")

def deploy_v140():
    print("\n[2/3] Publicando Release v1.4.0 como BORRADOR (draft: true)...")
    upload_draft_release(TAG_NAME, RELEASE_TITLE, RELEASE_NOTES, DEST)

def main():
    print("==================================================================")
    print(" COMPILACIÓN Y DESPLIEGUE BEREA INTERLINEAL v1.4.0 (CONSOLIDADA)")
    print("==================================================================")
    compile_v140()
    deploy_v140()
    print("\n[ÉXITO COMPLETO] v1.4.0 compilada y desplegada como BORRADOR en GitHub.")

if __name__ == "__main__":
    main()
