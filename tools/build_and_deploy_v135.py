#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v135.py
Prepara el worktree wt_v135 desde master, aplica los componentes de v1.3.5 (Edición Léxica):
- Base de datos con 100% de Derivaciones y Léxico Académico STEPBible
- Ocultamiento inteligente de guiones '—'
- Distintivo de «Raíz primaria»
- Hipervínculos táctiles a otros códigos Strong en derivación
- Barra clásica de 5 botones preservada (Biblia, Búsqueda, Diccionario, Mi Estudio, Ajustes)
- Alternador Sol/Luna en AppBar señalando con precisión de píxel
- Ajustes depurados (sin Switch de modo oscuro, sin repositorio GitHub)
- Guía de uso interactiva v1.3.5 de 8 pasos
Compila los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
genera checksums.txt en release_builds/v1.3.5/ y publica la release v1.3.5 como BORRADOR (DRAFT: TRUE).
"""

import hashlib
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent))
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

### 5. Alternador Rápido de Tema Sol/Luna (☀️/🌙) Calibrado
* Alterna entre Pergamino Diurno y Noche Alejandrina directamente desde la barra superior.
* Spotlight y puntero calibrados con precisión de píxel hacia el icono.
* Pantalla de Ajustes depurada (eliminado switch redundante y enlaces a repositorio).

### 6. Navegación Clásica Preservada
* Mantiene la barra de navegación clásica de 5 botones (Biblia, Búsqueda, Diccionario, Mi Estudio, Ajustes).

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
    print("[1/5] Configurando worktree wt_v135 desde master...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v135"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v135", "master"], cwd=ROOT)

    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)
    print("  [OK] Worktree wt_v135 creado y saneado.")

def patch_worktree():
    print("\n[2/5] Aplicando componentes específicos de v1.3.5 a wt_v135...")

    # 1. Actualizar versión en pubspec.yaml a 1.3.5+8
    pub_file = WT / "pubspec.yaml"
    text = pub_file.read_text(encoding="utf-8")
    text = re.sub(r"^version: .*", "version: 1.3.5+8", text, flags=re.MULTILINE)
    pub_file.write_text(text, encoding="utf-8")
    print(f"  [OK] pubspec.yaml actualizado a 1.3.5+8")

    # 2. Configurar HomeShell para barra clásica de 5 botones (sin BereaDrawer)
    home_file = WT / "lib/shell/home_shell.dart"
    h_text = home_file.read_text(encoding="utf-8")

    # Remover imports innecesarios de v1.4.0
    for imp in [
        "import 'widgets/berea_drawer.dart';\n",
        "import 'widgets/berea_drawer.dart';\r\n",
        "import '../features/summaries/book_summaries_screen.dart';\n",
        "import '../features/summaries/book_summaries_screen.dart';\r\n",
        "import '../features/authors/biblical_authors_screen.dart';\n",
        "import '../features/authors/biblical_authors_screen.dart';\r\n",
    ]:
        h_text = h_text.replace(imp, "")

    # Reemplazar versión de tour por defecto
    h_text = h_text.replace(
        "String _tourVersionLabel = UpdateService.fallbackVersion;",
        "String _tourVersionLabel = '1.3.5';"
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

    # Reemplazar bloque de screens
    screens_target = """    final screens = [
      BibleScreen(
        key: _bibleKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        tourDrawerButtonKey: _tourDrawerButtonKey,
        tourBookSummaryButtonKey: _tourBookSummaryButtonKey,
        tourThemeToggleKey: _tourThemeToggleKey,
        tourChapterModeButtonKey: _tourChapterModeKey,
        tourTypographyButtonKey: _tourTypographyKey,
        tourTheologicalPaletteKey: _tourTheologicalPaletteKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
        tourFirstItemKey: _tourDictionaryFirstItemKey,
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
        tourChapterModeButtonKey: _tourChapterModeKey,
        tourTypographyButtonKey: _tourTypographyKey,
        tourTheologicalPaletteKey: _tourTheologicalPaletteKey,
        showExegesisSections: false,
      ),
      GlobalSearchScreen(
        onOpenVerse: _navigateToVerse,
        tourSearchBarKey: _searchBarKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
        tourFirstItemKey: _tourDictionaryFirstItemKey,
        showExegesisSections: false,
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

    # Reemplazar Scaffold drawer y NavigationBar por 5 tabs
    scaffold_target = """        Scaffold(
          key: _scaffoldKey,
          drawer: BereaDrawer(
            onOpenBookSummaries: _openBookSummaries,
            onOpenAuthors: _openAuthors,
            onOpenSearch: _openGlobalSearch,
            onSelectTheologicalHighlight: _openTheologicalFilter,
            onOpenSettings: _openSettings,
            onStartTour: startInteractiveTour,
            tourTheologicalKey: _tourDrawerTheologicalKey,
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
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Biblia',
                ),
                NavigationDestination(
                  key: _tourBottomNavDictionaryKey,
                  icon: const Icon(Icons.translate_outlined),
                  selectedIcon: const Icon(Icons.translate),
                  label: 'Diccionario',
                ),
                NavigationDestination(
                  key: _tourBottomNavStudyKey,
                  icon: const Icon(Icons.bookmarks_outlined),
                  selectedIcon: const Icon(Icons.bookmarks),
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

    # 3. Saneamiento de tests para wt_v135 (remover v140 enciclopedia test y adaptar widget_test)
    v140_test = WT / "test/v140_enciclopedia_test.dart"
    if v140_test.exists():
        v140_test.unlink()
        print("  [OK] Removido v140_enciclopedia_test.dart de wt_v135.")

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
    print("  [OK] Adaptado widget_test.dart para 5 pestañas clásicas en wt_v135.")

    # 4. Desactivar secciones de exégesis (Similitudes y Familias) exclusivas de v1.3.7+
    detail_file = WT / "lib/features/dictionary/strong_detail_screen.dart"
    d_text = detail_file.read_text(encoding="utf-8")
    d_text = d_text.replace("this.showExegesisSections = true,", "this.showExegesisSections = false,")
    detail_file.write_text(d_text, encoding="utf-8")

    dict_file = WT / "lib/features/dictionary/dictionary_screen.dart"
    di_text = dict_file.read_text(encoding="utf-8")
    di_text = di_text.replace("this.showExegesisSections = true,", "this.showExegesisSections = false,")
    dict_file.write_text(di_text, encoding="utf-8")

    bible_file = WT / "lib/features/bible/bible_screen.dart"
    b_text = bible_file.read_text(encoding="utf-8")
    b_text = b_text.replace("this.showExegesisSections = true,", "this.showExegesisSections = false,")
    bible_file.write_text(b_text, encoding="utf-8")
    print("  [OK] Exégesis estrictamente desactivada para v1.3.5.")

def compile_v135():
    print("\n[3/5] Compilando APKs de Berea Interlineal v1.3.5...")
    print("  -> Verificando estática con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)

    print("  -> Ejecutando pruebas unitarias...")
    run_cmd(["flutter", "test"], cwd=WT)

    print("  -> Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    # Instalar inmediatamente en emulador si está conectado
    x86_apk = WT / "build" / "app" / "outputs" / "flutter-apk" / "app-x86_64-release.apk"
    adb_path = Path(os.environ.get("LOCALAPPDATA", "")) / "Android/Sdk/platform-tools/adb.exe"
    if x86_apk.exists() and adb_path.exists():
        print("\n  -> Instalando automáticamente v1.3.5 en emulator-5554...")
        subprocess.run([str(adb_path), "-s", "emulator-5554", "install", "-r", "-d", str(x86_apk)])
        subprocess.run([str(adb_path), "-s", "emulator-5554", "shell", "monkey", "-p", "com.netopssolutions.berea_interlineal", "-c", "android.intent.category.LAUNCHER", "1"])
        print("  [OK] v1.3.5 instalada y abierta en emulador.\n")

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
