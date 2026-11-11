#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v137.py
Prepara el worktree wt_v137 desde 873509c, aplica los componentes de v1.3.7 (Edición Exegética):
- Todo lo de v1.3.5 (100% Derivaciones y STEPBible, cero guiones, enlaces)
- Bloque: ⚖️ Similitudes, Sinónimos y Comparaciones Teológicas con pastillas táctiles doradas
- Bloque: 🌿 Familia de Palabras Derivadas (Árbol Léxico)
- Tabla relacional SQLite strong_relations
Compila los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
genera checksums.txt en release_builds/v1.3.7/ y publica la release v1.3.7 como BORRADOR (DRAFT: TRUE).
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

from deploy_draft_release import upload_draft_release

ROOT = Path(__file__).resolve().parent.parent
WT = ROOT / "wt_v137"
DEST = ROOT / "release_builds" / "v1.3.7"
TAG_NAME = "v1.3.7"
RELEASE_TITLE = "📜 Berea Interlineal v1.3.7 [BORRADOR] • Edición Exegética"

RELEASE_NOTES = """# 📜 Berea Interlineal v1.3.7 — Edición Exegética

> **ESTADO DE PUBLICACIÓN**: **BORRADOR PRIVADO (DRAFT: TRUE)**.  
> Esta versión acumulativa incorpora todo lo de la v1.3.5 más las herramientas exegéticas avanzadas y no dispara alertas OTA a los usuarios de producción v1.3.1.

---

## 🧭 Novedades de la Versión 1.3.7: Edición Exegética

### 1. Todo lo Implementado en la Versión 1.3.5
* Cobertura del 100% de Derivaciones y Léxico STEPBible en 14.197 términos bíblicos.
* Cero guiones «—» y distintivo solemne para raíces primarias.
* Hipervínculos activos en las derivaciones.

### 2. ⚖️ Similitudes, Sinónimos y Comparaciones Teológicas
* Nuevo bloque exegético interactivo con pastillas táctiles doradas y ámbar.
* Distinciones teológicas profundas entre términos afines:
  - **En Hebreo**: *érets* (#H776) vs *adamáh* (#H127) vs *tebél* (#H8398); *bará* (#H1254) vs *asáh* (#H6213) vs *yatsár* (#H3335); *jésed* (#H2617) vs *rájam* (#H7356), etc.
  - **En Griego**: *agapáo* (#G25) vs *philéo* (#G5368) vs *storgē* (#G4694); *lógos* (#G3056) vs *rhēma* (#G4487); *zōē* (#G2222) vs *bíos* (#G979) vs *psychē* (#G5590), etc.

### 3. 🌿 Familia de Palabras Derivadas (Árbol Léxico)
* Visualización de todas las palabras bíblicas que nacen de esa misma raíz semítica o griega.
* Navegación fluida de un solo toque entre miembros de la misma familia léxica.

### 4. Tabla Relacional SQLite `strong_relations`
* Estructura relacional optimizada con índices de alta velocidad para relaciones etimológicas y exegéticas.

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
    print("[1/5] Configurando worktree wt_v137 desde 873509c...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v137"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v137", "873509c"], cwd=ROOT)

    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)
    print("  [OK] Worktree wt_v137 creado y saneado.")

def patch_worktree():
    print("\n[2/5] Aplicando componentes v1.3.7 a wt_v137...")

    # 1. Base de datos enriquecida con tabla strong_relations y notas teológicas
    shutil.copy2(ROOT / "assets/data/logos_k_logos.db", WT / "assets/data/logos_k_logos.db")
    print("  [OK] Base de datos enriquecida copiada a wt_v137.")

    # 2. Modelos y Servicio de base de datos
    shutil.copy2(ROOT / "lib/data/models.dart", WT / "lib/data/models.dart")
    shutil.copy2(ROOT / "lib/data/database_service.dart", WT / "lib/data/database_service.dart")
    print("  [OK] Modelos y DatabaseService copiados a wt_v137.")

    # 3. Widgets de diccionario con bloques exegéticos
    shutil.copy2(ROOT / "lib/features/dictionary/widgets/linked_strong_text.dart", WT / "lib/features/dictionary/widgets/linked_strong_text.dart")
    shutil.copy2(ROOT / "lib/features/dictionary/strong_detail_screen.dart", WT / "lib/features/dictionary/strong_detail_screen.dart")
    print("  [OK] strong_detail_screen.dart y linked_strong_text.dart copiados a wt_v137.")

    # 4. Actualizar versión en pubspec.yaml
    pub_file = WT / "pubspec.yaml"
    text = pub_file.read_text(encoding="utf-8")
    text = text.replace("version: 1.3.1+4", "version: 1.3.7+7")
    text = text.replace("version: 1.3.2+5", "version: 1.3.7+7")
    pub_file.write_text(text, encoding="utf-8")
    print("  [OK] pubspec.yaml actualizado a versión 1.3.7+7.")

def compile_v137():
    print("\n[3/5] Compilando APKs de Berea Interlineal v1.3.7...")
    print("  -> Verificando estática con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)

    print("  -> Compilando Split APKs...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    print("  -> Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=WT)

    apk_dir = WT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.3.7_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.3.7_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.3.7_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.3.7_universal.apk",
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

def deploy_v137():
    print("\n[4/5] Publicando Release v1.3.7 como BORRADOR (draft: true)...")
    upload_draft_release(TAG_NAME, RELEASE_TITLE, RELEASE_NOTES, DEST)

def cleanup():
    print("\n[5/5] Limpiando worktree wt_v137...")
    subprocess.run(["git", "worktree", "remove", "--force", "wt_v137"], cwd=str(ROOT), shell=(os.name == "nt"))
    if WT.exists():
        shutil.rmtree(WT, ignore_errors=True)
    subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))
    print("  [OK] Limpieza terminada.")

def main():
    print("==================================================================")
    print(" COMPILACIÓN Y DESPLIEGUE BEREA INTERLINEAL v1.3.7 (EDICIÓN EXEGÉTICA)")
    print("==================================================================")
    try:
        setup_worktree()
        patch_worktree()
        compile_v137()
        deploy_v137()
    finally:
        cleanup()
    print("\n[ÉXITO COMPLETO] v1.3.7 compilada y desplegada como BORRADOR en GitHub.")

if __name__ == "__main__":
    main()
