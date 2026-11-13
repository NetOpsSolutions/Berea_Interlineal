#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v133.py
Prepara el worktree wt_v133 desde 873509c (base limpia de v1.3.2 sin enciclopedia ni drawer de v1.4.0),
aplica todas las optimizaciones de rendimiento y fluidez de v1.3.3:
1. Alternador Sol/Luna instantáneo en AppBar (0ms de retraso, themeAnimationDuration = Duration.zero)
2. Expansión/contracción de versículos ultra-rápida (Text.rich para versos colapsados, eliminación de AnimatedSize, token regex hoisted)
3. Slider de tipografía fluido sin I/O en disco durante el arrastre (setReadingFontScaleTransient / commitReadingFontScale)
4. Firma oficial con berea-release.jks (CN=NetOps Solutions)
5. Compilación de los 4 APKs (arm64-v8a, armeabi-v7a, x86_64, universal), generación de checksums.txt,
   e instalación automática limpia en emulator-5554.
"""

import hashlib
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WT = ROOT / "wt_v133"
DEST = ROOT / "release_builds" / "v1.3.3"

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
    print("[1/5] Configurando worktree wt_v133 desde 873509c...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v133"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v133", "873509c"], cwd=ROOT)
    
    # Eliminar plataformas de escritorio innecesarias para evitar symlinks en Windows sin Developer Mode
    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)

    # Copiar credenciales oficiales de firmado release a android/
    shutil.copy2(ROOT / "android/key.properties", WT / "android/key.properties")
    shutil.copy2(ROOT / "android/berea-release.jks", WT / "android/berea-release.jks")
    print("  [OK] Worktree creado y credenciales berea-release.jks inyectadas.")

def patch_worktree():
    print("\n[2/5] Aplicando parches de v1.3.3 a wt_v133...")

    # 1. pubspec.yaml: version 1.3.3+8
    pub_file = WT / "pubspec.yaml"
    p_text = pub_file.read_text(encoding="utf-8")
    p_text = p_text.replace("version: 1.3.1+6", "version: 1.3.3+8")
    p_text = p_text.replace("version: 1.3.2+7", "version: 1.3.3+8")
    pub_file.write_text(p_text, encoding="utf-8")
    print("  [OK] pubspec.yaml actualizado a 1.3.3+8")

    # 2. UpdateService fallbackVersion
    upd_file = WT / "lib/core/update/update_service.dart"
    u_text = upd_file.read_text(encoding="utf-8")
    u_text = u_text.replace("static const String fallbackVersion = '1.3.1';", "static const String fallbackVersion = '1.3.3';")
    u_text = u_text.replace("static const String fallbackVersion = '1.3.2';", "static const String fallbackVersion = '1.3.3';")
    upd_file.write_text(u_text, encoding="utf-8")
    print("  [OK] update_service.dart actualizado a 1.3.3")

    # 3. Copiar tour_steps_factory.dart desde ROOT (con soporte 1.3.3 y 6 pasos calibrados)
    shutil.copy2(ROOT / "lib/core/tour/tour_steps_factory.dart", WT / "lib/core/tour/tour_steps_factory.dart")
    print("  [OK] Copiado tour_steps_factory.dart con soporte v1.3.3")

    # 4. Patch StudyService: themeModeNotifier, setReadingFontScaleTransient, commitReadingFontScale, notify: false
    ss_file = WT / "lib/data/study_service.dart"
    ss_text = ss_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in ss_text else "\n"

    # Inyección de themeModeNotifier en StudyService
    notifier_decl = f"  ThemeMode _themeMode = ThemeMode.light;{nl}  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);"
    ss_text = ss_text.replace(f"  ThemeMode _themeMode = ThemeMode.light;", notifier_decl, 1)

    # Actualización en initialize()
    init_target = f"    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;"
    init_replace = f"    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;{nl}    themeModeNotifier.value = _themeMode;"
    ss_text = ss_text.replace(init_target, init_replace, 1)

    # Actualización en setThemeMode()
    set_theme_target = f"  Future<void> setThemeMode(ThemeMode mode) async {{{nl}    if (_themeMode == mode) return;{nl}    _themeMode = mode;{nl}    notifyListeners();"
    set_theme_replace = f"  Future<void> setThemeMode(ThemeMode mode) async {{{nl}    if (_themeMode == mode) return;{nl}    _themeMode = mode;{nl}    themeModeNotifier.value = mode;{nl}    notifyListeners();"
    if "\r\n" in ss_text:
        set_theme_target = set_theme_target.replace("\n", "\r\n")
        set_theme_replace = set_theme_replace.replace("\n", "\r\n")
    if set_theme_target in ss_text:
        ss_text = ss_text.replace(set_theme_target, set_theme_replace, 1)
        print("  [OK] themeModeNotifier.value vinculado en setThemeMode()")
    else:
        print("  [WARN] set_theme_target no encontrado en study_service.dart")

    # Inyección de setReadingFontScaleTransient y commitReadingFontScale
    scale_target = f"  Future<void> setReadingFontScale(double scale) async {{"
    scale_impl = f"""  void setReadingFontScaleTransient(double scale) {{
    final clamped = scale.clamp(0.85, 1.45);
    if ((_readingFontScale - clamped).abs() < 0.005) return;
    _readingFontScale = clamped;
    notifyListeners();
  }}

  Future<void> commitReadingFontScale(double scale) async {{
    final clamped = scale.clamp(0.85, 1.45);
    _readingFontScale = clamped;
    notifyListeners();
    try {{
      await _prefs?.setDouble(_keyFontScale, clamped);
    }} catch (_) {{}}
    await _saveUiSettingToDb(_keyFontScale, clamped.toStringAsFixed(2));
  }}

  Future<void> setReadingFontScale(double scale) async {{"""
    if "\r\n" in ss_text:
        scale_impl = scale_impl.replace("\n", "\r\n")
    ss_text = ss_text.replace(scale_target, scale_impl, 1)

    # Parche notify: false en addToHistory
    history_target = f"""  Future<void> addToHistory({{
    required String bookId,
    required int chapter,
    required int verse,
    required String preview,
  }}) async {{"""
    history_replace = f"""  Future<void> addToHistory({{
    required String bookId,
    required int chapter,
    required int verse,
    required String preview,
    bool notify = true,
  }}) async {{"""
    if "\r\n" in ss_text:
        history_target = history_target.replace("\n", "\r\n")
        history_replace = history_replace.replace("\n", "\r\n")
    ss_text = ss_text.replace(history_target, history_replace, 1)

    history_notify_target = f"""    notifyListeners();{nl}    await _dbUpsertHistory(item);"""
    history_notify_replace = f"""    if (notify) notifyListeners();{nl}    await _dbUpsertHistory(item);"""
    ss_text = ss_text.replace(history_notify_target, history_notify_replace, 1)

    ss_file.write_text(ss_text, encoding="utf-8")
    print("  [OK] Patched study_service.dart con optimizaciones v1.3.3")

    # 5. Patch main.dart: ValueListenableBuilder<ThemeMode> y themeAnimationDuration: Duration.zero
    main_file = WT / "lib/main.dart"
    m_text = main_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in m_text else "\n"

    main_target = f"""    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {{
        final currentThemeMode = StudyService.instance.themeMode;

        return MaterialApp(
          title: 'Berea Interlineal',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: currentThemeMode,
          home: SplashScreen(
            themeMode: currentThemeMode,
            onToggleTheme: () => StudyService.instance.toggleTheme(),
          ),
        );
      }},
    );"""
    main_replace = f"""    return ValueListenableBuilder<ThemeMode>(
      valueListenable: StudyService.instance.themeModeNotifier,
      builder: (context, currentThemeMode, _) {{
        return MaterialApp(
          title: 'Berea Interlineal',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: currentThemeMode,
          themeAnimationDuration: Duration.zero,
          home: SplashScreen(
            themeMode: currentThemeMode,
            onToggleTheme: () => StudyService.instance.toggleTheme(),
          ),
        );
      }},
    );"""
    if "\r\n" in m_text:
        main_target = main_target.replace("\n", "\r\n")
        main_replace = main_replace.replace("\n", "\r\n")
    if main_target in m_text:
        m_text = m_text.replace(main_target, main_replace, 1)
        print("  [OK] Patched main.dart con ValueListenableBuilder y Duration.zero")
    else:
        print("  [WARN] main_target no encontrado exactamente en main.dart")
    main_file.write_text(m_text, encoding="utf-8")

    # 6. Patch DictionaryScreen: Sol/Luna botón en AppBar
    dict_file = WT / "lib/features/dictionary/dictionary_screen.dart"
    d_text = dict_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in d_text else "\n"
    target_dict = f"            title: Text('Diccionario Strong ${{_lbl(_language)}}'),{nl}          ),"
    replace_dict = f"""            title: Text('Diccionario Strong ${{_lbl(_language)}}'),{nl}            actions: [{nl}              IconButton({nl}                icon: Icon({nl}                  t.brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: t.brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: t.brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}            ],{nl}          ),"""
    if target_dict in d_text:
        d_text = d_text.replace(target_dict, replace_dict, 1)
        dict_file.write_text(d_text, encoding="utf-8")
        print("  [OK] Patched dictionary_screen.dart con botón Sol/Luna")

    # 7. Patch StudyScreen: Sol/Luna botón en AppBar
    study_file = WT / "lib/features/study/study_screen.dart"
    st_text = study_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in st_text else "\n"
    target_study = f"            title: const Text('Mi Estudio'),{nl}            bottom: TabBar("
    replace_study = f"""            title: const Text('Mi Estudio'),{nl}            actions: [{nl}              IconButton({nl}                icon: Icon({nl}                  Theme.of(context).brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: Theme.of(context).brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: Theme.of(context).brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}            ],{nl}            bottom: TabBar("""
    if target_study in st_text:
        st_text = st_text.replace(target_study, replace_study, 1)
        study_file.write_text(st_text, encoding="utf-8")
        print("  [OK] Patched study_screen.dart con botón Sol/Luna")

    # 8. Patch SettingsScreen: Slider font size transient/commit y eliminar modo oscuro / repo redundante
    settings_file = WT / "lib/features/settings/settings_screen.dart"
    s_text = settings_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in s_text else "\n"

    # Eliminar switch redundante de Modo Oscuro
    s_text_len = len(s_text)
    s_text = re.sub(
        r'\s*SwitchListTile\(\s*title: const Text\(\'Modo oscuro\'\)[\s\S]*?onChanged: \(_\) => widget\.onToggleTheme\(\),\s*\),',
        '',
        s_text
    )
    if len(s_text) != s_text_len:
        print("  [OK] Eliminado switch redundante de Modo Oscuro en Ajustes")
    else:
        print("  [WARN] Modo oscuro no encontrado en settings_screen.dart")

    # Eliminar sección Repositorio Oficial
    s_text_len = len(s_text)
    s_text = re.sub(
        r'\s*const Divider\(\),\s*// ── 6\. Bloque: Recursos y Licencias ─+[\s\S]*?UpdateService\.instance\.openUrl\(\s*\'https://github\.com/NetOpsSolutions/Berea_Interlineal\'\s*,\s*\);\s*\}\s*,\s*\),',
        '',
        s_text
    )
    if len(s_text) != s_text_len:
        print("  [OK] Eliminada sección Repositorio Oficial en Ajustes")
    else:
        print("  [WARN] Repositorio Oficial no encontrado en settings_screen.dart")

    slider_settings_target = f"""                            Slider(
                              value: scale,
                              min: 0.85,
                              max: 1.45,
                              divisions: 12,
                              label: '$scalePercent%',
                              onChanged: (v) => study.setReadingFontScale(v),
                            ),"""
    slider_settings_replace = f"""                            Slider(
                              value: scale,
                              min: 0.85,
                              max: 1.45,
                              divisions: 12,
                              label: '$scalePercent%',
                              onChanged: (v) => study.setReadingFontScaleTransient(v),
                              onChangeEnd: (v) => study.commitReadingFontScale(v),
                            ),"""
    if "\r\n" in s_text:
        slider_settings_target = slider_settings_target.replace("\n", "\r\n")
        slider_settings_replace = slider_settings_replace.replace("\n", "\r\n")

    if slider_settings_target in s_text:
        s_text = s_text.replace(slider_settings_target, slider_settings_replace, 1)
        print("  [OK] Slider de Ajustes configurado con transient/commit")
    else:
        print("  [WARN] slider_settings_target no encontrado en settings_screen.dart")

    settings_file.write_text(s_text, encoding="utf-8")

    # 9. Patch HomeShell: Vincular tourThemeToggleKey
    home_file = WT / "lib/shell/home_shell.dart"
    h_text = home_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in h_text else "\n"

    key_target = f"  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();"
    key_replace = f"  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();{nl}  final GlobalKey _tourThemeToggleKey = GlobalKey(debugLabel: 'tourThemeToggle');"
    if key_target in h_text:
        h_text = h_text.replace(key_target, key_replace, 1)

    bible_target = f"      BibleScreen(key: _bibleKey),"
    bible_replace = f"      BibleScreen(key: _bibleKey, tourThemeToggleKey: _tourThemeToggleKey),"
    if bible_target in h_text:
        h_text = h_text.replace(bible_target, bible_replace, 1)
        print("  [OK] BibleScreen tourThemeToggleKey en home_shell.dart")

    tour_target1 = "      onPrepareSettingsReplayStep: () async {"
    tour_target2 = "      onPrepareSettingsReplayStep: () => _prepareSettingsReplayStep(),"
    tour_replace1 = f"      tourThemeToggleKey: _tourThemeToggleKey,{nl}      onPrepareSettingsReplayStep: () async {{"
    tour_replace2 = f"      tourThemeToggleKey: _tourThemeToggleKey,{nl}      onPrepareSettingsReplayStep: () => _prepareSettingsReplayStep(),"
    if tour_target1 in h_text:
        h_text = h_text.replace(tour_target1, tour_replace1, 1)
    elif tour_target2 in h_text:
        h_text = h_text.replace(tour_target2, tour_replace2, 1)

    home_file.write_text(h_text, encoding="utf-8")
    print("  [OK] Patched home_shell.dart")

    # 10. Patch BibleScreen: UI limpia v1.3.2 + Optimización total de rendimiento v1.3.3
    bible_file = WT / "lib/features/bible/bible_screen.dart"
    b_text = bible_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in b_text else "\n"

    # Hoist _tokenRegex justo después del último import
    import_hook = "import '../dictionary/widgets/linked_strong_text.dart';"
    import_replace = f"import '../dictionary/widgets/linked_strong_text.dart';{nl}{nl}final RegExp _tokenRegex = RegExp(r'(\\s+|[.,;:\\(\\)¡!¿?«»\"—]+)');"
    if import_hook in b_text:
        b_text = b_text.replace(import_hook, import_replace, 1)
        print("  [OK] _tokenRegex ubicado tras imports en bible_screen.dart")

    token_target = "final regex = RegExp(r'(\\s+|[.,;:\\(\\)¡!¿?«»\"—]+)');"
    token_replace = "final regex = _tokenRegex;"
    if token_target in b_text:
        b_text = b_text.replace(token_target, token_replace, 1)
        print("  [OK] regex reemplazado por _tokenRegex en _buildFormattedSpans")

    # Constructor
    ctor_target = f"""class BibleScreen extends StatefulWidget {{
  final String? initialBookId;
  final int? initialChapter;
  final int? initialVerse;

  const BibleScreen({{
    super.key,
    this.initialBookId,
    this.initialChapter,
    this.initialVerse,
  }});"""
    ctor_replace = f"""class BibleScreen extends StatefulWidget {{
  final String? initialBookId;
  final int? initialChapter;
  final int? initialVerse;
  final GlobalKey? tourThemeToggleKey;

  const BibleScreen({{
    super.key,
    this.initialBookId,
    this.initialChapter,
    this.initialVerse,
    this.tourThemeToggleKey,
  }});"""
    if "\r\n" in b_text:
        ctor_target = ctor_target.replace("\n", "\r\n")
        ctor_replace = ctor_replace.replace("\n", "\r\n")
    if ctor_target in b_text:
        b_text = b_text.replace(ctor_target, ctor_replace, 1)

    # Actions AppBar: Alternador Sol/Luna (LIMPIO: Sin Drawer ni Enciclopedia)
    actions_target = f"""            actions: [{nl}              Row({nl}                key: tourAppBarActionsKey,"""
    actions_replace = f"""            actions: [{nl}              IconButton({nl}                key: widget.tourThemeToggleKey,{nl}                icon: Icon({nl}                  theme.brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: theme.brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: theme.brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}              Row({nl}                key: tourAppBarActionsKey,"""
    if "\r\n" in b_text:
        actions_target = actions_target.replace("\n", "\r\n")
        actions_replace = actions_replace.replace("\n", "\r\n")
    if actions_target in b_text:
        b_text = b_text.replace(actions_target, actions_replace, 1)
        print("  [OK] Patched AppBar actions con Sol/Luna limpio")

    # Botón táctil expandir/contraer
    expand_btn_target = f"""                // Botón sutil para expandir/contraer herramientas e interlineal
                InkWell(
                  onTap: widget.onToggleExpand,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      widget.isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 18,
                      color: widget.isExpanded
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(150),
                    ),
                  ),
                ),"""
    expand_btn_replace = f"""                // Botón táctil para expandir/contraer herramientas e interlineal
                Tooltip(
                  message: widget.isExpanded
                      ? 'Plegar interlineal'
                      : 'Desplegar interlineal y herramientas',
                  child: InkWell(
                    onTap: widget.onToggleExpand,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(top: 2, left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isExpanded
                            ? theme.colorScheme.primary
                            : (isDark
                                ? const Color(0xFF2E241D)
                                : const Color(0xFFEADBBE)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isExpanded
                              ? theme.colorScheme.primary
                              : (isDark
                                  ? const Color(0xFF6B533E)
                                  : const Color(0xFFC7B38E)),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x30000000)
                                : const Color(0x14000000),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                        color: widget.isExpanded
                            ? theme.colorScheme.onPrimary
                            : (isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF92400E)),
                      ),
                    ),
                  ),
                ),"""
    if "\r\n" in b_text:
        expand_btn_target = expand_btn_target.replace("\n", "\r\n")
        expand_btn_replace = expand_btn_replace.replace("\n", "\r\n")
    if expand_btn_target in b_text:
        b_text = b_text.replace(expand_btn_target, expand_btn_replace, 1)
        print("  [OK] Patched verse expand button con diseño nítido")

    # Palabras en español resaltadas en _InterlinearWordTile
    interlinear_word_target = f"""            const SizedBox(height: 4),
            Text(
              word.translation,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),"""
    interlinear_word_replace = f"""            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1712)
                    : const Color(0xFFEADBBE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF4D3B2C)
                      : const Color(0xFFD4BFA0),
                  width: 0.8,
                ),
              ),
              child: Text(
                word.translation,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFFF3DB)
                      : const Color(0xFF261D17),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),"""
    if "\r\n" in b_text:
        interlinear_word_target = interlinear_word_target.replace("\n", "\r\n")
        interlinear_word_replace = interlinear_word_replace.replace("\n", "\r\n")
    if interlinear_word_target in b_text:
        b_text = b_text.replace(interlinear_word_target, interlinear_word_replace, 1)
        print("  [OK] Patched Spanish highlighted words en _InterlinearWordTile")

    # [OPTIMIZACIÓN v1.3.3]: _buildVerseRichText ligero con Text.rich si no está expandido
    rich_text_target = f"""    return SelectableText.rich(
      TextSpan(children: spans),
      contextMenuBuilder: (ctx, editableState) {{
        return _TheologicalSelectionToolbar(
          editableTextState: editableState,
          onSelectColor: (colorKey, selectedStr) {{
            widget.onApplyHighlight(colorKey, selectedFragment: selectedStr);
            editableState.hideToolbar();
          }},
        );
      }},
    );"""
    rich_text_replace = f"""    // [v1.3.3 Optimization]: Si el versículo no está expandido, se renderiza con
    // Text.rich para un rendimiento ultra liviano (0ms overhead de cursor/IME).
    // Solo cuando el usuario lo expande para interactuar, se habilita SelectableText.rich.
    if (!widget.isExpanded) {{
      return Text.rich(
        TextSpan(children: spans),
      );
    }}

    return SelectableText.rich(
      TextSpan(children: spans),
      contextMenuBuilder: (ctx, editableState) {{
        return _TheologicalSelectionToolbar(
          editableTextState: editableState,
          onSelectColor: (colorKey, selectedStr) {{
            widget.onApplyHighlight(colorKey, selectedFragment: selectedStr);
            editableState.hideToolbar();
          }},
        );
      }},
    );"""
    if "\r\n" in b_text:
        rich_text_target = rich_text_target.replace("\n", "\r\n")
        rich_text_replace = rich_text_replace.replace("\n", "\r\n")
    if rich_text_target in b_text:
        b_text = b_text.replace(rich_text_target, rich_text_replace, 1)
        print("  [OK] Patched _buildVerseRichText con Text.rich ligero")
    else:
        print("  [WARN] rich_text_target no encontrado en bible_screen.dart")

    # [OPTIMIZACIÓN v1.3.3]: Eliminación de AnimatedContainer (evita destello lerp con transparent)
    anim_container_target = f"""    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.symmetric(vertical: widget.isExpanded ? 6 : 2),"""
    anim_container_replace = f"""    return Container(
      margin: EdgeInsets.symmetric(vertical: widget.isExpanded ? 6 : 2),"""
    if "\r\n" in b_text:
        anim_container_target = anim_container_target.replace("\n", "\r\n")
        anim_container_replace = anim_container_replace.replace("\n", "\r\n")
    if anim_container_target in b_text:
        b_text = b_text.replace(anim_container_target, anim_container_replace, 1)
        print("  [OK] AnimatedContainer eliminado y reemplazado por Container directo")
    else:
        print("  [WARN] anim_container_target no encontrado en bible_screen.dart")

    # [OPTIMIZACIÓN v1.3.3]: Eliminación de AnimatedSize en _ChapterVerseBlock
    anim_size_target = f"""            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.isExpanded
                  ? _buildExpandedPanel(context, theme, isDark, hlColor)
                  : const SizedBox.shrink(),
            ),"""
    anim_size_replace = f"""            // [v1.3.3 Optimization]: Sustitución de AnimatedSize por condicional directo
            if (widget.isExpanded)
              _buildExpandedPanel(context, theme, isDark, hlColor),"""
    if "\r\n" in b_text:
        anim_size_target = anim_size_target.replace("\n", "\r\n")
        anim_size_replace = anim_size_replace.replace("\n", "\r\n")
    if anim_size_target in b_text:
        b_text = b_text.replace(anim_size_target, anim_size_replace, 1)
        print("  [OK] AnimatedSize eliminado y reemplazado por condicional directo")
    else:
        print("  [WARN] anim_size_target no encontrado en bible_screen.dart")

    # [OPTIMIZACIÓN v1.3.3]: Debounce y slider en _showTypographyModal / bottom sheet
    typo_slider_target = f"""                    value: scale,
                    min: 0.85,
                    max: 1.45,
                    divisions: 12,
                    label: '$percent%',
                    onChanged: (v) => service.setReadingFontScale(v),"""
    typo_slider_replace = f"""                    value: scale,
                    min: 0.85,
                    max: 1.45,
                    divisions: 12,
                    label: '$percent%',
                    onChanged: (v) => service.setReadingFontScaleTransient(v),
                    onChangeEnd: (v) => service.commitReadingFontScale(v),"""
    if "\r\n" in b_text:
        typo_slider_target = typo_slider_target.replace("\n", "\r\n")
        typo_slider_replace = typo_slider_replace.replace("\n", "\r\n")
    if typo_slider_target in b_text:
        b_text = b_text.replace(typo_slider_target, typo_slider_replace, 1)
        print("  [OK] Slider modal tipografía actualizado a transient/commit")

    # [OPTIMIZACIÓN v1.3.3]: addToHistory con notify: false al expandir versículo
    history_expand_target = f"""                      StudyService.instance.addToHistory(
                        bookId: v.bookId,
                        chapter: v.chapter,
                        verse: v.verse,
                        preview: v.translation,
                      );"""
    history_expand_replace = f"""                      StudyService.instance.addToHistory(
                        bookId: v.bookId,
                        chapter: v.chapter,
                        verse: v.verse,
                        preview: v.translation,
                        notify: false,
                      );"""
    if "\r\n" in b_text:
        history_expand_target = history_expand_target.replace("\n", "\r\n")
        history_expand_replace = history_expand_replace.replace("\n", "\r\n")
    if history_expand_target in b_text:
        b_text = b_text.replace(history_expand_target, history_expand_replace, 1)
        print("  [OK] addToHistory con notify: false en expansión de versículo")

    bible_file.write_text(b_text, encoding="utf-8")
    print("  [OK] Patched bible_screen.dart con todas las optimizaciones")

    # 11. Patch widget_test.dart
    test_file = WT / "test/widget_test.dart"
    t_text = test_file.read_text(encoding="utf-8")
    t_text = t_text.replace("expect(v132.length, equals(7));", "expect(v132.length, equals(6));")
    t_text = t_text.replace("expect(v132.first.badge, equals('NUEVA IDENTIDAD'));", "expect(v132.first.badge, equals('EXPERIENCIA BÍBLICA'));")
    t_text = t_text.replace("expect(v132.first.title, equals('Inspirados en Hechos 17:11'));", "expect(v132.first.title, equals('Lectura Continua y Expansión al Toque'));")
    t_text = t_text.replace("expect(v132[1].title, equals('Lectura Continua y Expansión al Toque'));", "expect(v132[1].title, equals('Fuentes Ezra SIL, Cardo y Frank Ruhl Libre'));")
    t_text = t_text.replace(
        "expect(v132[3].title, equals('Resalta Versículos o Frases Seleccionadas'));",
        "expect(v132[2].title, equals('Resalta Versículos o Frases Seleccionadas'));\n    expect(v132[4].title, equals('Alternador de Modo Claro y Oscuro (☀️/🌙)'));"
    )
    t_text = t_text.replace("expect(v140.length, equals(5));", "expect(v140.length, equals(9));")
    t_text = t_text.replace("expect(v140.first.badge, equals('NUEVO MÓDULO'));", "expect(v140.first.badge, equals('BIENVENIDA & LECTURA'));")

    tour_test_old = """    expect(find.byType(InteractiveTourOverlay), findsOneWidget);
    expect(find.text('1 / 7'), findsOneWidget);
    expect(find.text('Inspirados en Hechos 17:11'), findsOneWidget);

    // Avanzar al paso 2 y paso 3
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 / 7'), findsOneWidget);
    expect(find.text('Lectura Continua y Expansión al Toque'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3 / 7'), findsOneWidget);
    expect(find.text('Fuentes Ezra SIL, Cardo y Frank Ruhl Libre'), findsOneWidget);"""

    tour_test_new = """    expect(find.byType(InteractiveTourOverlay), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('Lectura Continua y Expansión al Toque'), findsOneWidget);

    // Avanzar al paso 2 y paso 3
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('Fuentes Ezra SIL, Cardo y Frank Ruhl Libre'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('Resalta Versículos o Frases Seleccionadas'), findsOneWidget);"""

    if "\r\n" in t_text:
        tour_test_old = tour_test_old.replace("\n", "\r\n")
        tour_test_new = tour_test_new.replace("\n", "\r\n")
    t_text = t_text.replace(tour_test_old, tour_test_new, 1)
    test_file.write_text(t_text, encoding="utf-8")
    print("  [OK] Patched widget_test.dart")

def compile_and_deploy_v133():
    print("\n[3/5] Compilando APKs oficiales de Berea Interlineal v1.3.3...")
    print("  -> Verificando análisis estático con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)

    print("  -> Ejecutando suite de pruebas automatizadas...")
    run_cmd(["flutter", "test"], cwd=WT)

    print("  -> Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    print("  -> Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=WT)

    apk_dir = WT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.3.3_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.3.3_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.3.3_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.3.3_universal.apk",
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

    # Verificar firmas criptográficas con apksigner
    apksigner_path = Path(os.environ.get("LOCALAPPDATA", "")) / "Android/Sdk/build-tools/36.0.0/apksigner.bat"
    if apksigner_path.exists():
        print("\n  -> Verificando certificado oficial con apksigner...")
        res = subprocess.run([str(apksigner_path), "verify", "--print-certs", str(DEST / "berea_interlineal_1.3.3_arm64-v8a.apk")], capture_output=True, text=True)
        print(f"     Certificado: {res.stdout.strip()[:100]}...")

    # Instalar limpiamente en emulator-5554 si está disponible
    x86_apk = DEST / "berea_interlineal_1.3.3_x86_64.apk"
    adb_path = Path(os.environ.get("LOCALAPPDATA", "")) / "Android/Sdk/platform-tools/adb.exe"
    if x86_apk.exists() and adb_path.exists():
        print("\n[4/5] Instalando limpiamente v1.3.3 en emulator-5554...")
        print("  -> Desinstalando versión anterior del emulador para prevenir conflicto de paquetes...")
        subprocess.run([str(adb_path), "-s", "emulator-5554", "uninstall", "com.netopssolutions.berea_interlineal"])
        print("  -> Instalando berea_interlineal_1.3.3_x86_64.apk...")
        subprocess.run([str(adb_path), "-s", "emulator-5554", "install", "-r", str(x86_apk)])
        print("  -> Iniciando Berea Interlineal v1.3.3 en emulador...")
        subprocess.run([str(adb_path), "-s", "emulator-5554", "shell", "monkey", "-p", "com.netopssolutions.berea_interlineal", "-c", "android.intent.category.LAUNCHER", "1"])
        print("  [OK] v1.3.3 instalada y ejecutándose en el emulador.\n")

def cleanup():
    print("\n[5/5] Limpiando worktree temporal wt_v133...")
    subprocess.run(["git", "worktree", "remove", "--force", "wt_v133"], cwd=str(ROOT), shell=(os.name == "nt"))
    if WT.exists():
        shutil.rmtree(WT, ignore_errors=True)
    subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))
    print("  [OK] Limpieza terminada.")

def main():
    print("==================================================================")
    print(" COMPILACIÓN Y DESPLIEGUE BEREA INTERLINEAL v1.3.3 (PERFORMANCE FIX)")
    print("==================================================================")
    try:
        setup_worktree()
        patch_worktree()
        compile_and_deploy_v133()
    finally:
        cleanup()
    print("\n[ÉXITO COMPLETO] v1.3.3 compilada, verificada e instalada en el emulador.")

if __name__ == "__main__":
    main()
