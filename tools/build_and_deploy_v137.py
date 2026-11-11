#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v137.py
Prepara el worktree wt_v137 desde master, aplica los componentes de v1.3.7 (Edición Exegética):
- Todo lo de v1.3.5 (100% Derivaciones y Léxico STEPBible, cero guiones, enlaces táctiles)
- Bloque: ⚖️ Similitudes, Sinónimos y Comparaciones Teológicas con pastillas táctiles doradas
- Bloque: 🌿 Familia de Palabras Derivadas (Árbol Léxico)
- Tabla relacional SQLite strong_relations
- Barra clásica de 5 botones (Biblia, Búsqueda, Diccionario, Mi Estudio, Ajustes)
- Alternador Sol/Luna en AppBar señalando con precisión de píxel
- Ajustes depurados (sin Switch redundante, sin repositorio GitHub)
- Guía interactiva v1.3.7 de 10 pasos adaptada
Compila los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
genera checksums.txt en release_builds/v1.3.7/ y publica la release v1.3.7 como BORRADOR (DRAFT: TRUE).
"""

import hashlib
import os
import re
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
* Cero guiones «—» y distintivo de dignidad para raíces primarias.
* Hipervínculos activos en las derivaciones.
* Alternador rápido de Tema Sol/Luna (☀️/🌙) calibrado en la barra superior.
* Pantalla de Ajustes depurada sin elementos redundantes ni enlaces a repositorio.

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

### 5. Guía Interactiva Adaptada v1.3.7
* Recorrido guiado de 10 pasos con paradas dedicadas para la comparación de similitudes teológicas y árboles léxicos familiares.

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
    print("[1/5] Configurando worktree wt_v137 desde master...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v137"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v137", "master"], cwd=ROOT)

    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)
    print("  [OK] Worktree wt_v137 creado y saneado.")

def patch_worktree():
    print("\n[2/5] Aplicando componentes específicos de v1.3.7 a wt_v137...")

    # 1. Actualizar versión en pubspec.yaml a 1.3.7+9
    pub_file = WT / "pubspec.yaml"
    text = pub_file.read_text(encoding="utf-8")
    text = re.sub(r"^version: .*", "version: 1.3.7+9", text, flags=re.MULTILINE)
    pub_file.write_text(text, encoding="utf-8")
    print(f"  [OK] pubspec.yaml actualizado a 1.3.7+9")

    # 2. Configurar HomeShell para barra clásica de 5 botones (sin BereaDrawer de v1.4.0)
    home_file = WT / "lib/shell/home_shell.dart"
    h_text = home_file.read_text(encoding="utf-8")

    # Remover imports de componentes exclusivos de v1.4.0
    for imp in [
        "import 'widgets/berea_drawer.dart';\n",
        "import 'widgets/berea_drawer.dart';\r\n",
        "import '../features/summaries/book_summaries_screen.dart';\n",
        "import '../features/summaries/book_summaries_screen.dart';\r\n",
        "import '../features/authors/biblical_authors_screen.dart';\n",
        "import '../features/authors/biblical_authors_screen.dart';\r\n",
    ]:
        h_text = h_text.replace(imp, "")

    # Reemplazar versión de tour por defecto a '1.3.7'
    h_text = h_text.replace(
        "String _tourVersionLabel = UpdateService.fallbackVersion;",
        "String _tourVersionLabel = '1.3.7';"
    )

    # Remover métodos exclusivos del drawer de v1.4.0
    drawer_methods_target = """  void _openBookSummaries() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSummariesScreen(onOpenVerse: _navigateToVerse),
      ),
    );
  }

  void _openAuthors() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BiblicalAuthorsScreen(onOpenVerse: _navigateToVerse),
      ),
    );
  }

  void _openGlobalSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(
          onOpenVerse: _navigateToVerse,
          tourSearchBarKey: _searchBarKey,
        ),
      ),
    );
  }

  void _openTheologicalFilter(String colorKey) {
    setState(() => _index = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _studyKey.currentState?.setHighlightFilter(colorKey);
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          key: _settingsKey,
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
          onOpenVerse: _navigateToVerse,
          onStartInteractiveGuide: () {
            Navigator.of(context).pop();
            startInteractiveTour();
          },
        ),
      ),
    );
  }"""
    if "\r\n" in h_text:
        drawer_methods_target = drawer_methods_target.replace("\n", "\r\n")
    h_text = h_text.replace(drawer_methods_target, "", 1)

    # Reemplazar bloque de screens para 5 pantallas clásicas
    screens_target = """    final screens = [
      BibleScreen(
        key: _bibleKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        tourDrawerButtonKey: _tourDrawerButtonKey,
        tourBookSummaryButtonKey: _tourBookSummaryButtonKey,
        tourThemeToggleKey: _tourThemeToggleKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      StudyScreen(
        key: _studyKey,
        onOpenVerse: _navigateToVerse,
        tourTabsKey: _studyTabsKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];"""

    screens_replace = """    final screens = [
      BibleScreen(
        key: _bibleKey,
        tourThemeToggleKey: _tourThemeToggleKey,
      ),
      GlobalSearchScreen(
        onOpenVerse: _navigateToVerse,
        tourSearchBarKey: _searchBarKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
      ),
      StudyScreen(
        key: _studyKey,
        onOpenVerse: _navigateToVerse,
        tourTabsKey: _studyTabsKey,
      ),
      SettingsScreen(
        key: _settingsKey,
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
        onOpenVerse: _navigateToVerse,
        onStartInteractiveGuide: startInteractiveTour,
      ),
    ];"""

    if "\r\n" in h_text:
        screens_target = screens_target.replace("\n", "\r\n")
        screens_replace = screens_replace.replace("\n", "\r\n")
    h_text = h_text.replace(screens_target, screens_replace, 1)

    # Reemplazar Scaffold drawer y NavigationBar de 3 por 5 pestañas
    scaffold_target = """        Scaffold(
          key: _scaffoldKey,
          drawer: BereaDrawer(
            onOpenBookSummaries: _openBookSummaries,
            onOpenAuthors: _openAuthors,
            onOpenSearch: _openGlobalSearch,
            onSelectTheologicalHighlight: _openTheologicalFilter,
            onOpenSettings: _openSettings,
          ),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A3E34)
                      : const Color(0xFFDFCFAF),
                  width: 1.0,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: isDark
                  ? const Color(0xFF1B1613)
                  : const Color(0xFFEDE4CE),
              indicatorColor: isDark
                  ? const Color(0xFF382A1D)
                  : const Color(0xFFE2D3B5),
              selectedIndex: _index,
              onDestinationSelected: (v) => setState(() => _index = v),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Biblia',
                ),
                NavigationDestination(
                  icon: Icon(Icons.translate_outlined),
                  selectedIcon: Icon(Icons.translate),
                  label: 'Diccionario',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmarks_outlined),
                  selectedIcon: Icon(Icons.bookmarks),
                  label: 'Mi Estudio',
                ),
              ],
            ),
          ),
        ),"""

    scaffold_replace = """        Scaffold(
          key: _scaffoldKey,
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A3E34)
                      : const Color(0xFFDFCFAF),
                  width: 1.0,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: isDark
                  ? const Color(0xFF1B1613)
                  : const Color(0xFFEDE4CE),
              indicatorColor: isDark
                  ? const Color(0xFF382A1D)
                  : const Color(0xFFE2D3B5),
              selectedIndex: _index,
              onDestinationSelected: (v) => setState(() => _index = v),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Biblia',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Búsqueda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.translate_outlined),
                  selectedIcon: Icon(Icons.translate),
                  label: 'Diccionario',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmarks_outlined),
                  selectedIcon: Icon(Icons.bookmarks),
                  label: 'Mi Estudio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),"""

    if "\r\n" in h_text:
        scaffold_target = scaffold_target.replace("\n", "\r\n")
        scaffold_replace = scaffold_replace.replace("\n", "\r\n")
    h_text = h_text.replace(scaffold_target, scaffold_replace, 1)

    home_file.write_text(h_text, encoding="utf-8")
    print("  [OK] home_shell.dart adaptado a 5 pestañas sin drawer.")

    # 3. Saneamiento de tests para wt_v137
    v140_test = WT / "test/v140_enciclopedia_test.dart"
    if v140_test.exists():
        v140_test.unlink()
        print("  [OK] Removido v140_enciclopedia_test.dart de wt_v137.")

    wt_test_file = WT / "test/widget_test.dart"
    w_text = wt_test_file.read_text(encoding="utf-8")
    w_text = w_text.replace("import 'package:berea_interlineal/shell/widgets/berea_drawer.dart';\n", "")
    w_text = w_text.replace("import 'package:berea_interlineal/shell/widgets/berea_drawer.dart';\r\n", "")

    drawer_tap_target = """    // Abrir Drawer tocando el icono de menú hamburguesa
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    final drawerScrollable = find.descendant(
      of: find.byType(BereaDrawer),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Ajustes del Sistema'),
      150,
      scrollable: drawerScrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes del Sistema'));
    await tester.pumpAndSettle();"""

    drawer_tap_replace = """    // Navegar directamente a la pestaña de Ajustes (icono en barra inferior de 5 botones)
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();"""

    if "\r\n" in w_text:
        drawer_tap_target = drawer_tap_target.replace("\n", "\r\n")
        drawer_tap_replace = drawer_tap_replace.replace("\n", "\r\n")
    if drawer_tap_target in w_text:
        w_text = w_text.replace(drawer_tap_target, drawer_tap_replace, 1)
    wt_test_file.write_text(w_text, encoding="utf-8")
    print("  [OK] Adaptado widget_test.dart para 5 pestañas clásicas en wt_v137.")

def compile_v137():
    print("\n[3/5] Compilando APKs de Berea Interlineal v1.3.7...")
    print("  -> Verificando estática con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)

    print("  -> Ejecutando pruebas unitarias...")
    run_cmd(["flutter", "test"], cwd=WT)

    print("  -> Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
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
