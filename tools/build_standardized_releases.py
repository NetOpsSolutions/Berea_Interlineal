#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Compilador retrospectivo aislado (vía git worktree) para estandarizar Berea Interlineal
en las versiones históricas publicadas (v1.3.0 y v1.3.1) sin alterar el árbol principal (master).

Inyecta:
  - Identidad oficial Berea Interlineal (Hechos 17:11), applicationId com.netopssolutions.berea_interlineal
  - Firma de producción android/berea-release.jks + puente nativo Android de notificaciones OTA
  - Guía interactiva contextual por versión (TourStepsFactory + InteractiveTourOverlay) con auto-disparo único
  - Pantalla de Ajustes limpia de producción (0 simuladores/demos)
  - Tema con contraste WCAG AAA en SnackBars (AppSnackBar)
Preservando intacto el motor funcional propio de cada versión:
  - v1.3.0 (1.3.0+4): Estudio básico en SharedPreferences + lectura interlineal por versículo
  - v1.3.1 (1.3.1+5): Motor SQLite ACID dedicado (logos_user_data.db) + migrador automático desde v1.3.0
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent


VERSIONS_SPEC = [
    {
        "tag": "1.3.0",
        "version": "1.3.0",
        "build_number": 4,
    },
    {
        "tag": "1.3.1",
        "version": "1.3.1",
        "build_number": 5,
    },
]


DIRECT_COPY_FILES = [
    "android/berea-release.jks",
    "android/key.properties",
    "android/app/build.gradle.kts",
    "android/app/proguard-rules.pro",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/src/main/kotlin/com/netopssolutions/berea_interlineal/MainActivity.kt",
    "ios/Runner/Info.plist",
    "assets/images/berea_interlineal_icon.jpg",
    "android/app/src/main/res/values/colors.xml",
    "lib/core/theme.dart",
    "lib/core/tour/interactive_tour_overlay.dart",
    "lib/core/tour/tour_steps_factory.dart",
    "lib/core/update/update_model.dart",
    "lib/core/update/update_dialog.dart",
    "lib/features/splash/splash_screen.dart",
    "lib/main.dart",
    "lib/shell/home_shell.dart",
]


def run_cmd(cmd: list[str], cwd: Path) -> None:
    print(f"  $ {' '.join(cmd)}  (cwd={cwd})")
    res = subprocess.run(cmd, cwd=str(cwd), shell=(os.name == "nt"))
    if res.returncode != 0:
        raise RuntimeError(f"Comando falló ({res.returncode}): {' '.join(cmd)}")


def make_pubspec(version: str, build_number: int) -> str:
    return f"""name: berea_interlineal
description: "Berea Interlineal - Estudio bíblico interlineal Hebreo-Griego-Español (Hechos 17:11)"
publish_to: 'none'
version: {version}+{build_number}

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.3
  path: ^1.9.0
  shared_preferences: ^2.5.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/logos_k_logos.db
    - assets/data/sample.json
    - assets/images/berea_interlineal_icon.jpg
"""


def patch_update_service(wt: Path, version: str, build_number: int) -> None:
    src = (ROOT / "lib/core/update/update_service.dart").read_text(encoding="utf-8")
    patched = src.replace(
        "static const String fallbackVersion = '1.3.2';",
        f"static const String fallbackVersion = '{version}';",
    ).replace(
        "static const int fallbackBuildNumber = 7;",
        f"static const int fallbackBuildNumber = {build_number};",
    )
    assert f"fallbackVersion = '{version}'" in patched
    assert f"fallbackBuildNumber = {build_number}" in patched
    dest = wt / "lib/core/update/update_service.dart"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(patched, encoding="utf-8")


def patch_study_service_130(wt: Path) -> None:
    path = wt / "lib/data/study_service.dart"
    text = path.read_text(encoding="utf-8")

    text = text.replace(
        "  static const String _keyThemeMode = 'logos_theme_mode_v1';",
        "  static const String _keyThemeMode = 'logos_theme_mode_v1';\n"
        "  static const String _keyLastSeenTourVersion = 'logos_last_seen_tour_version_v1';",
    )
    text = text.replace(
        "  ThemeMode _themeMode = ThemeMode.dark;",
        "  ThemeMode _themeMode = ThemeMode.dark;\n"
        "  String _lastSeenTourVersion = '';",
    )
    text = text.replace(
        "  bool get isDarkMode => _themeMode == ThemeMode.dark;",
        "  bool get isDarkMode => _themeMode == ThemeMode.dark;\n"
        "  String get lastSeenTourVersion => _lastSeenTourVersion;\n\n"
        "  bool shouldShowVersionTour(String currentAppVersion) {\n"
        "    final clean = currentAppVersion.trim();\n"
        "    if (clean.isEmpty) return false;\n"
        "    return _lastSeenTourVersion.trim() != clean;\n"
        "  }",
    )
    text = text.replace(
        "      _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? false;",
        "      _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? false;\n"
        "      _lastSeenTourVersion = _prefs?.getString(_keyLastSeenTourVersion) ?? '';",
    )
    text = text.replace(
        "  Future<void> toggleTheme() async {\n"
        "    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;\n"
        "    await setThemeMode(next);\n"
        "  }",
        "  Future<void> toggleTheme() async {\n"
        "    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;\n"
        "    await setThemeMode(next);\n"
        "  }\n\n"
        "  Future<void> markVersionTourSeen(String currentAppVersion) async {\n"
        "    final clean = currentAppVersion.trim();\n"
        "    if (clean.isEmpty) return;\n"
        "    _lastSeenTourVersion = clean;\n"
        "    notifyListeners();\n"
        "    await _prefs?.setString(_keyLastSeenTourVersion, clean);\n"
        "  }",
    )

    assert "shouldShowVersionTour" in text and "markVersionTourSeen" in text
    path.write_text(text, encoding="utf-8")


def patch_study_service_131(wt: Path) -> None:
    path = wt / "lib/data/study_service.dart"
    text = path.read_text(encoding="utf-8")

    text = text.replace(
        "  static const String _keyThemeMode = 'logos_theme_mode_v1';",
        "  static const String _keyThemeMode = 'logos_theme_mode_v1';\n"
        "  static const String _keyLastSeenTourVersion = 'logos_last_seen_tour_version_v1';",
    )
    text = text.replace(
        "  ThemeMode _themeMode = ThemeMode.dark;",
        "  ThemeMode _themeMode = ThemeMode.dark;\n"
        "  String _lastSeenTourVersion = '';",
    )
    text = text.replace(
        "  bool get isDarkMode => _themeMode == ThemeMode.dark;",
        "  bool get isDarkMode => _themeMode == ThemeMode.dark;\n"
        "  String get lastSeenTourVersion => _lastSeenTourVersion;\n\n"
        "  bool shouldShowVersionTour(String currentAppVersion) {\n"
        "    final clean = currentAppVersion.trim();\n"
        "    if (clean.isEmpty) return false;\n"
        "    return _lastSeenTourVersion.trim() != clean;\n"
        "  }",
    )
    text = text.replace(
        "        _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? _fluentReadingMode;",
        "        _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? _fluentReadingMode;\n"
        "        _lastSeenTourVersion = _prefs?.getString(_keyLastSeenTourVersion) ?? _lastSeenTourVersion;",
    )
    text = text.replace(
        "        } else if (k == _keyThemeMode && _prefs?.getString(_keyThemeMode) == null && v != null) {\n"
        "          _themeMode = v == 'light' ? ThemeMode.light : ThemeMode.dark;\n"
        "        }",
        "        } else if (k == _keyThemeMode && _prefs?.getString(_keyThemeMode) == null && v != null) {\n"
        "          _themeMode = v == 'light' ? ThemeMode.light : ThemeMode.dark;\n"
        "        } else if (k == _keyLastSeenTourVersion && v != null && v.isNotEmpty) {\n"
        "          if (_lastSeenTourVersion.isEmpty) {\n"
        "            _lastSeenTourVersion = v;\n"
        "          }\n"
        "        }",
    )
    text = text.replace(
        "  Future<void> toggleTheme() async {\n"
        "    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;\n"
        "    await setThemeMode(next);\n"
        "  }",
        "  Future<void> toggleTheme() async {\n"
        "    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;\n"
        "    await setThemeMode(next);\n"
        "  }\n\n"
        "  Future<void> markVersionTourSeen(String currentAppVersion) async {\n"
        "    final clean = currentAppVersion.trim();\n"
        "    if (clean.isEmpty) return;\n"
        "    _lastSeenTourVersion = clean;\n"
        "    notifyListeners();\n"
        "    try {\n"
        "      await _prefs?.setString(_keyLastSeenTourVersion, clean);\n"
        "    } catch (_) {}\n"
        "    await _saveUiSettingToDb(_keyLastSeenTourVersion, clean);\n"
        "  }",
    )

    assert "shouldShowVersionTour" in text and "markVersionTourSeen" in text
    path.write_text(text, encoding="utf-8")


def patch_feature_screens_for_tour(wt: Path) -> None:
    # 1. BibleScreen: tourActiveVerseKey, tourAppBarActionsKey, prepareForInteractiveTourStep1()
    bible_path = wt / "lib/features/bible/bible_screen.dart"
    bible = bible_path.read_text(encoding="utf-8")

    bible = bible.replace(
        "  final List<TapGestureRecognizer> _recognizers = [];",
        "  final List<TapGestureRecognizer> _recognizers = [];\n"
        "  final GlobalKey tourActiveVerseKey = GlobalKey(debugLabel: 'tourBibleVerse');\n"
        "  final GlobalKey tourAppBarActionsKey = GlobalKey(debugLabel: 'tourBibleActions');\n\n"
        "  Future<void> prepareForInteractiveTourStep1() async {\n"
        "    if (_fluentMode) {\n"
        "      await StudyService.instance.setFluentReadingMode(false);\n"
        "      if (mounted) {\n"
        "        setState(() => _fluentMode = false);\n"
        "      }\n"
        "    }\n"
        "  }",
    )
    bible = bible.replace(
        "          appBar: AppBar(\n"
        "            title: const Text('Biblia Interlineal'),\n"
        "            actions: [",
        "          appBar: AppBar(\n"
        "            title: const Text('Biblia Interlineal'),\n"
        "            actions: [\n"
        "              Row(\n"
        "                key: tourAppBarActionsKey,\n"
        "                mainAxisSize: MainAxisSize.min,\n"
        "                children: [",
    )
    bible = bible.replace(
        "                  tooltip: 'Nota personal del versículo',\n"
        "                  onPressed: _editVerseNoteDialog,\n"
        "                ),\n"
        "            ],\n"
        "          ),",
        "                  tooltip: 'Nota personal del versículo',\n"
        "                  onPressed: _editVerseNoteDialog,\n"
        "                ),\n"
        "                ],\n"
        "              ),\n"
        "            ],\n"
        "          ),",
    )
    # Fallback in case indentation of IconButton inside actions was 14 spaces
    if "key: tourAppBarActionsKey" in bible and bible.count("children: [") == bible.count("actions: ["):
        pass
    bible = bible.replace(
        "              // Botón de Nota personal\n"
        "              IconButton(\n"
        "                icon: Icon(\n"
        "                  verseNote != null ? Icons.note_alt : Icons.note_alt_outlined,\n"
        "                  color: verseNote != null ? Theme.of(context).colorScheme.primary : null,\n"
        "                ),\n"
        "                tooltip: 'Nota personal del versículo',\n"
        "                onPressed: _editVerseNoteDialog,\n"
        "              ),\n"
        "            ],\n"
        "          ),",
        "              // Botón de Nota personal\n"
        "              IconButton(\n"
        "                icon: Icon(\n"
        "                  verseNote != null ? Icons.note_alt : Icons.note_alt_outlined,\n"
        "                  color: verseNote != null ? Theme.of(context).colorScheme.primary : null,\n"
        "                ),\n"
        "                tooltip: 'Nota personal del versículo',\n"
        "                onPressed: _editVerseNoteDialog,\n"
        "              ),\n"
        "                ],\n"
        "              ),\n"
        "            ],\n"
        "          ),",
    )
    bible = bible.replace(
        "                  // Vista principal del versículo\n"
        "                  Expanded(",
        "                  // Vista principal del versículo\n"
        "                  Expanded(\n"
        "                    key: tourActiveVerseKey,",
    )
    assert "tourActiveVerseKey" in bible and "prepareForInteractiveTourStep1" in bible
    bible_path.write_text(bible, encoding="utf-8")

    # 2. GlobalSearchScreen: tourSearchBarKey
    search_path = wt / "lib/features/search/global_search_screen.dart"
    search = search_path.read_text(encoding="utf-8")
    search = search.replace(
        "  final void Function(String bookId, int chapter, int verse)? onOpenVerse;\n\n"
        "  const GlobalSearchScreen({super.key, this.onOpenVerse});",
        "  final void Function(String bookId, int chapter, int verse)? onOpenVerse;\n"
        "  final GlobalKey? tourSearchBarKey;\n\n"
        "  const GlobalSearchScreen({super.key, this.onOpenVerse, this.tourSearchBarKey});",
    )
    search = search.replace(
        "            // Barra de búsqueda unificada\n"
        "            Padding(",
        "            // Barra de búsqueda unificada\n"
        "            Padding(\n"
        "              key: widget.tourSearchBarKey,",
    )
    assert "tourSearchBarKey" in search
    search_path.write_text(search, encoding="utf-8")

    # 3. DictionaryScreen: tourControlsKey
    dict_path = wt / "lib/features/dictionary/dictionary_screen.dart"
    dic = dict_path.read_text(encoding="utf-8")
    dic = dic.replace(
        "  final String initialLanguage;\n"
        "  const DictionaryScreen({super.key, required this.initialLanguage});",
        "  final String initialLanguage;\n"
        "  final GlobalKey? tourControlsKey;\n"
        "  const DictionaryScreen({super.key, required this.initialLanguage, this.tourControlsKey});",
    )
    dic = dic.replace(
        "      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [\n"
        "        SegmentedButton<String>(",
        "      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [\n"
        "        Column(key: widget.tourControlsKey, children: [\n"
        "        SegmentedButton<String>(",
    )
    dic = dic.replace(
        "          suffixIcon: _c.text.isNotEmpty ? IconButton(onPressed: () { _c.clear(); _search(''); }, icon: const Icon(Icons.close)) : null)),\n"
        "        const SizedBox(height: 16),",
        "          suffixIcon: _c.text.isNotEmpty ? IconButton(onPressed: () { _c.clear(); _search(''); }, icon: const Icon(Icons.close)) : null)),\n"
        "        ]),\n"
        "        const SizedBox(height: 16),",
    )
    assert "tourControlsKey" in dic
    dict_path.write_text(dic, encoding="utf-8")

    # 4. StudyScreen: tourTabsKey
    study_path = wt / "lib/features/study/study_screen.dart"
    study = study_path.read_text(encoding="utf-8")
    study = study.replace(
        "  final int initialIndex;\n"
        "  final StudyNotesFilter initialNotesFilter;\n\n"
        "  const StudyScreen({\n"
        "    super.key,\n"
        "    this.onOpenVerse,\n"
        "    this.initialIndex = 0,\n"
        "    this.initialNotesFilter = StudyNotesFilter.all,\n"
        "  });",
        "  final int initialIndex;\n"
        "  final StudyNotesFilter initialNotesFilter;\n"
        "  final GlobalKey? tourTabsKey;\n\n"
        "  const StudyScreen({\n"
        "    super.key,\n"
        "    this.onOpenVerse,\n"
        "    this.initialIndex = 0,\n"
        "    this.initialNotesFilter = StudyNotesFilter.all,\n"
        "    this.tourTabsKey,\n"
        "  });",
    )
    study = study.replace(
        "            bottom: TabBar(\n"
        "              controller: _tabController,",
        "            bottom: TabBar(\n"
        "              key: widget.tourTabsKey,\n"
        "              controller: _tabController,",
    )
    assert "tourTabsKey" in study
    study_path.write_text(study, encoding="utf-8")


LEGACY_CLEAN_SETTINGS_SCREEN = """import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/tour/tour_steps_factory.dart';
import '../../core/update/update_dialog.dart';
import '../../core/update/update_model.dart';
import '../../core/update/update_service.dart';
import '../../data/study_service.dart';
import '../splash/splash_screen.dart';
import '../study/study_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;
  final VoidCallback? onStartInteractiveGuide;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.onOpenVerse,
    this.onStartInteractiveGuide,
  });

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey tourReadingSectionKey = GlobalKey(debugLabel: 'tourSettingsReading');
  final GlobalKey tourUpdaterKey = GlobalKey(debugLabel: 'tourSettingsUpdater');
  final GlobalKey tourReplayGuideKey = GlobalKey(debugLabel: 'tourReplayGuide');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Desplaza suavemente la vista de Ajustes hasta dejar visible el bloque requerido por la guía
  Future<void> scrollToTourTarget(GlobalKey targetKey, {double alignment = 0.08}) async {
    if (!mounted) return;
    final ctx = targetKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: alignment,
      );
    }
  }

  void _openStudy(
    BuildContext context, {
    required int initialIndex,
    StudyNotesFilter notesFilter = StudyNotesFilter.all,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          onOpenVerse: widget.onOpenVerse,
          initialIndex: initialIndex,
          initialNotesFilter: notesFilter,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final study = StudyService.instance;
        final bookmarksCount = study.bookmarks.length;
        final verseNotesCount = study.verseNotes.length;
        final strongNotesCount = study.strongNotes.length;
        final historyCount = study.history.length;
        final isFluentDefault = study.fluentReadingMode;
        final currentVersion = UpdateService.instance.currentVersion;

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Bloque: Lectura y Visualización ──────────────────────────
                Column(
                  key: tourReadingSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(theme, 'Lectura y Visualización'),
                    SwitchListTile(
                      title: const Text('Modo oscuro'),
                      subtitle: const Text('Alterna entre tema claro y tema oscuro'),
                      secondary: Icon(
                        widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                      ),
                      value: widget.themeMode == ThemeMode.dark,
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                    SwitchListTile(
                      title: const Text('Modo lectura fluida'),
                      subtitle: const Text(
                        'Oculta el interlineal por defecto y subraya discretamente palabras Strong',
                      ),
                      secondary: const Icon(Icons.auto_stories),
                      value: isFluentDefault,
                      onChanged: (val) => study.setFluentReadingMode(val),
                    ),
                  ],
                ),

                const Divider(),

                // ── 2. Bloque: Mi Estudio Personal ──────────────────────────────
                _buildSectionHeader(theme, 'Mi Estudio Personal'),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.bookmark_outline,
                  title: 'Marcadores guardados',
                  count: bookmarksCount,
                  onTap: () => _openStudy(context, initialIndex: 0),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.edit_note,
                  title: 'Notas en versículos',
                  count: verseNotesCount,
                  onTap: () => _openStudy(
                    context,
                    initialIndex: 1,
                    notesFilter: StudyNotesFilter.verses,
                  ),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.translate,
                  title: 'Notas en palabras Strong',
                  count: strongNotesCount,
                  onTap: () => _openStudy(
                    context,
                    initialIndex: 1,
                    notesFilter: StudyNotesFilter.strong,
                  ),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.history,
                  title: 'Historial de visitas',
                  count: historyCount,
                  onTap: () => _openStudy(context, initialIndex: 2),
                ),

                const Divider(),

                // ── 3. Bloque: Acerca de la Aplicación ──────────────────────────
                _buildSectionHeader(theme, 'Acerca de la Aplicación'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versión instalada'),
                  subtitle: Text('Berea Interlineal v$currentVersion • Edición Oficial'),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Ver animación de bienvenida'),
                  subtitle: const Text('Reproducir presentación de inicio y logo'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplashScreen(
                          themeMode: widget.themeMode,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  key: tourReplayGuideKey,
                  leading: const Icon(Icons.explore_outlined),
                  title: const Text('Ver guía de uso'),
                  subtitle: const Text(
                    'Iniciar recorrido interactivo animado de la versión',
                  ),
                  onTap: widget.onStartInteractiveGuide,
                ),

                // ── 4. Tarjeta de Novedades Limpia (Específica de la versión) ───
                _buildCleanVersionFeaturesCard(theme, currentVersion),

                const Divider(),

                // ── 5. Bloque: Centro de Actualizaciones Oficial ────────────────
                Column(
                  key: tourUpdaterKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(theme, 'Actualizaciones del Sistema'),
                    const _UpdaterCard(),
                  ],
                ),

                const Divider(),

                // ── 6. Bloque: Recursos y Licencias ─────────────────────────────
                _buildSectionHeader(theme, 'Recursos y Licencias'),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Repositorio Oficial'),
                  subtitle: const Text('https://github.com/NetOpsSolutions/Berea_Interlineal'),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: () {
                    UpdateService.instance.openUrl(
                      'https://github.com/NetOpsSolutions/Berea_Interlineal',
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.source_outlined),
                  title: Text('Fuentes textuales'),
                  subtitle: Text(
                    'Biblia Hebraica Stuttgartensia (AT), Tischendorf Griego (NT), Léxicos Strong y STEPBible',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('Licencias y créditos'),
                  subtitle: Text('Recursos bíblicos de dominio público y licencias académicas abiertas'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCleanVersionFeaturesCard(ThemeData theme, String rawVersion) {
    final cleanVer = TourStepsFactory.normalizeVersion(rawVersion);
    final items = _featuresForVersion(cleanVer);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Novedades en Versión ${cleanVer.isEmpty ? rawVersion : cleanVer}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in items)
                _featureRow(
                  icon: item.icon,
                  title: item.title,
                  desc: item.desc,
                  theme: theme,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_VersionFeatureItem> _featuresForVersion(String cleanVer) {
    switch (cleanVer) {
      case '1.3.0':
        return const [
          _VersionFeatureItem(
            icon: Icons.play_circle_outline,
            title: 'Presentación Oficial y Arranque Ágil',
            desc: 'Animación solemne de bienvenida con carga rápida de manuscritos offline.',
          ),
          _VersionFeatureItem(
            icon: Icons.menu_book_rounded,
            title: 'Lectura Bíblica Interlineal',
            desc: 'Texto en Hebreo, Griego y Español palabra por palabra con fonética y morfología.',
          ),
          _VersionFeatureItem(
            icon: Icons.search_rounded,
            title: 'Búsqueda Global y Léxicos Strong',
            desc: 'Consulta instantánea de citas bíblicas, palabras clave y raíces del AT y NT.',
          ),
          _VersionFeatureItem(
            icon: Icons.bookmarks_rounded,
            title: 'Mi Estudio y Modo Oscuro',
            desc: 'Marcadores, notas personales e historial con tema oscuro cómodo por defecto.',
          ),
          _VersionFeatureItem(
            icon: Icons.explore_rounded,
            title: 'Guía Interactiva de Uso',
            desc: 'Recorrido animado en el primer inicio y disponible bajo demanda en Ajustes.',
          ),
        ];

      case '1.3.1':
      default:
        return const [
          _VersionFeatureItem(
            icon: Icons.auto_stories_rounded,
            title: 'Entorno Visual Pergamino Alejandrino',
            desc:
                'Nuevo diseño cálido inspirado en los manuscritos antiguos de papiro y vitela. Reduce el cansancio visual y brinda una experiencia de lectura bíblica inmersiva tanto en Modo Claro como en Modo Oscuro.',
          ),
          _VersionFeatureItem(
            icon: Icons.movie_filter_rounded,
            title: 'Nueva Introducción y Lema de Berea',
            desc:
                'Pantalla de bienvenida solemne con fondo de cuero antiguo, iluminación celestial, barra de progreso en oro ámbar y el lema bíblico oficial: «...escudriñando cada día las Escrituras» (Hechos 17:11).',
          ),
          _VersionFeatureItem(
            icon: Icons.storage_rounded,
            title: 'Persistencia permanente en SQLite',
            desc:
                'Marcadores, notas e historial ahora se resguardan de forma atómica en logos_user_data.db, garantizando que nunca se borren al cerrar o reiniciar la app.',
          ),
          _VersionFeatureItem(
            icon: Icons.system_update_rounded,
            title: 'Actualizador In-App OTA Multi-Procesador',
            desc:
                'Detección automática de procesador (arm64, armv7, x86_64, universal) y descarga directa con barra de progreso desde GitHub Releases.',
          ),
          _VersionFeatureItem(
            icon: Icons.link_rounded,
            title: 'Hipervínculos en códigos Strong derivados',
            desc:
                'Toca las referencias derivadas entre paréntesis dentro de las definiciones para abrir ese Strong directamente sin perder el contexto.',
          ),
          _VersionFeatureItem(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Dónde aparece desplegable',
            desc:
                'Acordeón por libro con todas las apariciones de cada palabra y resaltado de marcador que conserva el color de fuente original.',
          ),
        ];
    }
  }

  Widget _buildStudyCounterTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionFeatureItem {
  final IconData icon;
  final String title;
  final String desc;

  const _VersionFeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

/// Tarjeta limpia de producción para el sistema de actualizaciones OTA (sin simuladores)
class _UpdaterCard extends StatefulWidget {
  const _UpdaterCard();

  @override
  State<_UpdaterCard> createState() => _UpdaterCardState();
}

class _UpdaterCardState extends State<_UpdaterCard> {
  bool _isChecking = false;
  DeviceArchitecture? _arch;
  DateTime? _lastCheckedAt;

  @override
  void initState() {
    super.initState();
    UpdateService.instance.getDeviceArchitecture().then((arch) {
      if (mounted) setState(() => _arch = arch);
    });
  }

  String _formatCheckTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd/$mo/${dt.year} $hh:$mm';
  }

  Future<void> _checkUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final res = await UpdateService.instance.checkForUpdates(isManual: true);

      if (!mounted) return;
      setState(() => _lastCheckedAt = DateTime.now());

      if (res.hasUpdate && res.releaseInfo != null) {
        await UpdateService.instance.showSystemUpdateNotification(
          res.releaseInfo!,
          force: true,
        );
        if (!mounted) return;
        showUpdateDialog(context, res.releaseInfo!);
      } else if (res.isIncompatible) {
        AppSnackBar.show(
          context,
          icon: Icons.phonelink_erase_rounded,
          tone: AppSnackBarTone.warning,
          message: res.message,
          duration: const Duration(seconds: 6),
        );
      } else if (res.status == UpdateStatus.upToDate) {
        AppSnackBar.show(
          context,
          icon: Icons.check_circle_rounded,
          tone: AppSnackBarTone.success,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      } else if (res.status == UpdateStatus.noReleases) {
        AppSnackBar.show(
          context,
          icon: Icons.info_outline_rounded,
          tone: AppSnackBarTone.info,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      } else {
        AppSnackBar.show(
          context,
          icon: Icons.warning_amber_rounded,
          tone: AppSnackBarTone.warning,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentVer = UpdateService.instance.currentVersion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(140),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buscar actualizaciones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Versión actual: v$currentVer • GitHub Releases',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.memory_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _arch != null
                                    ? 'CPU: ${_arch!.readableName}'
                                    : 'Detectando arquitectura...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_lastCheckedAt != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Última verificación: ${_formatCheckTime(_lastCheckedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _isChecking ? null : _checkUpdates,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.system_update_rounded, size: 19),
                  label: Text(
                    _isChecking ? 'Comprobando en GitHub...' : 'Comprobar actualizaciones',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
"""


def build_single_version(spec: dict, analyze_only: bool = False) -> None:
    tag = spec["tag"]
    ver = spec["version"]
    build_num = spec["build_number"]

    print(f"\n{'=' * 72}")
    print(f"  ESTANDARIZANDO Y COMPILANDO Berea Interlineal v{ver}+{build_num} (tag {tag})")
    print(f"{'=' * 72}")

    wt_dir = Path(tempfile.gettempdir()) / f"berea_std_wt_{ver.replace('.', '_')}"
    if wt_dir.exists():
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(wt_dir)],
            cwd=str(ROOT),
            capture_output=True,
        )
        shutil.rmtree(wt_dir, ignore_errors=True)

    run_cmd(["git", "worktree", "add", "--detach", str(wt_dir), tag], cwd=ROOT)

    try:
        # 1. Eliminar paquete Kotlin antiguo com.example y carpetas desktop innecesarias en worktree
        #    (evita que Flutter intente crear .plugin_symlinks de Windows sin Developer Mode)
        old_kotlin = wt_dir / "android/app/src/main/kotlin/com/example"
        if old_kotlin.exists():
            shutil.rmtree(old_kotlin)
        for desktop_dir in ("windows", "linux", "macos"):
            dd = wt_dir / desktop_dir
            if dd.exists():
                shutil.rmtree(dd)

        # 2. Reemplazar recursos Android (mipmap, adaptive icon v26, strings, etc.)
        wt_res = wt_dir / "android/app/src/main/res"
        if wt_res.exists():
            shutil.rmtree(wt_res)
        shutil.copytree(ROOT / "android/app/src/main/res", wt_res)

        # 3. Copiar archivos unificados desde master
        for rel in DIRECT_COPY_FILES:
            src = ROOT / rel
            dst = wt_dir / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)

        # 4. Escribir pubspec.yaml con versión oficial
        (wt_dir / "pubspec.yaml").write_text(make_pubspec(ver, build_num), encoding="utf-8")

        # 5. Inyectar UpdateService con fallbackVersion/fallbackBuildNumber exactos
        patch_update_service(wt_dir, ver, build_num)

        # 6. Parchear StudyService respetando la arquitectura propia de cada versión
        if ver == "1.3.0":
            patch_study_service_130(wt_dir)
        elif ver == "1.3.1":
            patch_study_service_131(wt_dir)

        # 7. Añadir anclas GlobalKey a pantallas de pestaña + SettingsScreen limpio
        patch_feature_screens_for_tour(wt_dir)
        (wt_dir / "lib/features/settings/settings_screen.dart").write_text(
            LEGACY_CLEAN_SETTINGS_SCREEN, encoding="utf-8"
        )

        # 8. Eliminar test legacy de plantilla si hace referencia a logos_k_logos antiguo
        wt_test_dir = wt_dir / "test"
        if wt_test_dir.exists():
            shutil.rmtree(wt_test_dir)

        # 9. Resolver paquetes y validar 0 errores / 0 deprecaciones con flutter analyze
        run_cmd(["flutter", "pub", "get"], cwd=wt_dir)
        run_cmd(["flutter", "analyze"], cwd=wt_dir)

        if analyze_only:
            print(f"  [ANALYZE ONLY OK] v{ver}+{build_num} pasó flutter analyze sin errores.")
            return

        # 10. Compilar split-per-abi y universal en modo release
        run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=wt_dir)
        run_cmd(["flutter", "build", "apk", "--release"], cwd=wt_dir)

        # 11. Recolectar en release_builds/v<ver>/ limpiando APKs/sha1 antiguos
        dest_dir = ROOT / "release_builds" / f"v{ver}"
        dest_dir.mkdir(parents=True, exist_ok=True)
        for old_item in dest_dir.iterdir():
            if old_item.is_file() and (
                old_item.suffix.lower() in {".apk", ".sha1"} or old_item.name == "checksums.txt"
            ):
                old_item.unlink()

        apk_out = wt_dir / "build/app/outputs/flutter-apk"
        mapping = {
            "app-arm64-v8a-release.apk": f"berea_interlineal_{ver}_arm64-v8a.apk",
            "app-armeabi-v7a-release.apk": f"berea_interlineal_{ver}_armeabi-v7a.apk",
            "app-x86_64-release.apk": f"berea_interlineal_{ver}_x86_64.apk",
            "app-release.apk": f"berea_interlineal_{ver}_universal.apk",
        }
        for src_name, dst_name in mapping.items():
            src_file = apk_out / src_name
            if not src_file.exists():
                raise FileNotFoundError(f"No se generó el artefacto esperado: {src_file}")
            shutil.copy2(src_file, dest_dir / dst_name)
            size_mb = (dest_dir / dst_name).stat().st_size / (1024 * 1024)
            print(f"  [OK] Copiado {dst_name} ({size_mb:.2f} MB)")

    finally:
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(wt_dir)],
            cwd=str(ROOT),
            capture_output=True,
        )
        shutil.rmtree(wt_dir, ignore_errors=True)


def main() -> None:
    raw_args = [a for a in sys.argv[1:] if a != "--analyze-only"]
    analyze_only = "--analyze-only" in sys.argv[1:]
    targets = raw_args if raw_args else ["1.3.0", "1.3.1"]
    for spec in VERSIONS_SPEC:
        if spec["version"] in targets or spec["tag"] in targets:
            build_single_version(spec, analyze_only=analyze_only)
    print("\n[COMPLETADO] Compilación retrospectiva estandarizada finalizada con éxito.")


if __name__ == "__main__":
    main()
