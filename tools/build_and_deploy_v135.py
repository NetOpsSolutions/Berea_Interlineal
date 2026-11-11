#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v135.py
Prepara el worktree wt_v135 desde 873509c, aplica los componentes de v1.3.5 (Edición Léxica):
- Base de datos con 100% de Derivaciones y Léxico Académico STEPBible
- Ocultamiento inteligente de guiones '—'
- Distintivo de «Raíz primaria»
- Hipervínculos táctiles a otros códigos Strong en derivación
- Barra clásica de 5 botones preservada
Compila los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
genera checksums.txt en release_builds/v1.3.5/ y publica la release v1.3.5 como BORRADOR (DRAFT: TRUE).
"""

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

from deploy_draft_release import upload_draft_release

ROOT = Path(__file__).resolve().parent.parent
WT = ROOT / "wt_v135"
DEST = ROOT / "release_builds" / "v1.3.5"
TAG_NAME = "v1.3.5"
RELEASE_TITLE = "📜 Berea Interlineal v1.3.5 [BORRADOR] • Edición Léxica"

RELEASE_NOTES = """# 📜 Berea Interlineal v1.3.5 — Edición Léxica

> **ESTADO DE PUBLICACIÓN**: **BORRADOR PRIVADO (DRAFT: TRUE)**.  
> Esta versión se encuentra en fase de validación técnica y no dispara alertas OTA a los usuarios de producción v1.3.1.

---

## 🧭 Novedades de la Versión 1.3.5: Edición Léxica

### 1. Poblado Integral de Derivaciones y Etimologías (14.197 términos)
* Cobertura del 100% en las 8.674 palabras en Hebreo (AT) y 5.523 palabras en Griego (NT).
* Cada entrada ahora contiene su etimología y raíz semítica o griega precisa.

### 2. Léxico Académico Extendido (STEPBible / Tyndale House Cambridge)
* Integración de las definiciones contextuales y académicas modernas en español desarrolladas por Tyndale House (Cambridge).
* Eliminación definitiva del vacío lexicográfico anterior.

### 3. Supresión Total de Guiones Secos «—» y Ocultamiento Inteligente
* Si una palabra es una **raíz primaria**, la ficha muestra con distinción: *«Raíz primaria (no proviene de otra palabra bíblica)»*.
* Los campos que no apliquen a un término no se renderizan, manteniendo una interfaz limpia y libre de guiones vacíos.

### 4. Hipervínculos Táctiles en Derivaciones
* Toda referencia cruzada a otros códigos Strong citados en las derivaciones se convierte en un botón interactivo para navegación inmediata.

### 5. Navegación Clásica Preservada
* Mantiene la barra de navegación clásica de 5 botones (Biblia, Diccionario, Marcadores, Búsqueda, Ajustes).

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

def setup_worktree():
    print("[1/5] Configurando worktree wt_v135 desde 873509c...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v135"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v135", "873509c"], cwd=ROOT)

    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)
    print("  [OK] Worktree wt_v135 creado y saneado.")

def patch_worktree():
    print("\n[2/5] Aplicando componentes v1.3.5 a wt_v135...")

    # 1. Base de datos con 100% derivaciones y stepbible
    shutil.copy2(ROOT / "assets/data/logos_k_logos.db", WT / "assets/data/logos_k_logos.db")
    print("  [OK] Base de datos enriquecida copiada a wt_v135.")

    # 2. Modelos y Servicio de base de datos
    shutil.copy2(ROOT / "lib/data/models.dart", WT / "lib/data/models.dart")
    shutil.copy2(ROOT / "lib/data/database_service.dart", WT / "lib/data/database_service.dart")
    print("  [OK] Modelos y DatabaseService copiados a wt_v135.")

    # 3. Widgets de diccionario
    shutil.copy2(ROOT / "lib/features/dictionary/widgets/linked_strong_text.dart", WT / "lib/features/dictionary/widgets/linked_strong_text.dart")
    shutil.copy2(ROOT / "lib/features/dictionary/strong_detail_screen.dart", WT / "lib/features/dictionary/strong_detail_screen.dart")
    print("  [OK] strong_detail_screen.dart y linked_strong_text.dart copiados a wt_v135.")

    # 4. Actualizar versión en pubspec.yaml
    pub_file = WT / "pubspec.yaml"
    text = pub_file.read_text(encoding="utf-8")
    text = text.replace("version: 1.3.1+4", "version: 1.3.5+6")
    text = text.replace("version: 1.3.2+5", "version: 1.3.5+6")
    pub_file.write_text(text, encoding="utf-8")
    print("  [OK] pubspec.yaml actualizado a versión 1.3.5+6.")

def compile_v135():
    print("\n[3/5] Compilando APKs de Berea Interlineal v1.3.5...")
    print("  -> Verificando estática con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)

    print("  -> Compilando Split APKs...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    print("  -> Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=WT)

    apk_dir = WT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.3.5_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.3.5_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.3.5_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.3.5_universal.apk",
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

def deploy_v135():
    print("\n[4/5] Publicando Release v1.3.5 como BORRADOR (draft: true)...")
    upload_draft_release(TAG_NAME, RELEASE_TITLE, RELEASE_NOTES, DEST)

def cleanup():
    print("\n[5/5] Limpiando worktree wt_v135...")
    subprocess.run(["git", "worktree", "remove", "--force", "wt_v135"], cwd=str(ROOT), shell=(os.name == "nt"))
    if WT.exists():
        shutil.rmtree(WT, ignore_errors=True)
    subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))
    print("  [OK] Limpieza terminada.")

def main():
    print("==================================================================")
    print(" COMPILACIÓN Y DESPLIEGUE BEREA INTERLINEAL v1.3.5 (EDICIÓN LÉXICA)")
    print("==================================================================")
    try:
        setup_worktree()
        patch_worktree()
        compile_v135()
        deploy_v135()
    finally:
        cleanup()
    print("\n[ÉXITO COMPLETO] v1.3.5 compilada y desplegada como BORRADOR en GitHub.")

if __name__ == "__main__":
    main()
