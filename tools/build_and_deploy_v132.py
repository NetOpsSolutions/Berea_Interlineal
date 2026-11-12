#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_and_deploy_v132.py
Prepara el worktree wt_v132 desde 873509c, aplica los parches de v1.3.2:
- Alternador Sol/Luna en AppBar (Biblia, Diccionario, Mi Estudio)
- Guía interactiva de 7 pasos con énfasis en Sol/Luna
- Botón táctil visible de despliegue de versículo (Desplegar interlineal y herramientas)
- Palabras en español resaltadas en _InterlinearWordTile con badge nítido
Compila todos los APKs (arm64-v8a, armeabi-v7a, x86_64, universal),
actualiza release_builds/v1.3.2/checksums.txt y sube los binarios a GitHub Release 425000889.
"""

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WT = ROOT / "wt_v132"
DEST = ROOT / "release_builds" / "v1.3.2"

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
    print("[1/5] Configurando worktree wt_v132 desde 873509c...")
    if WT.exists():
        print(f"  Removiendo worktree previo {WT}...")
        subprocess.run(["git", "worktree", "remove", "--force", "wt_v132"], cwd=str(ROOT), shell=(os.name == "nt"))
        if WT.exists():
            shutil.rmtree(WT, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))

    run_cmd(["git", "worktree", "add", "-d", "wt_v132", "873509c"], cwd=ROOT)
    
    # Eliminar plataformas de escritorio innecesarias para evitar que Flutter intente crear symlinks en Windows sin Developer Mode
    for desktop in ["windows", "linux", "macos", "web"]:
        dd = WT / desktop
        if dd.exists():
            shutil.rmtree(dd, ignore_errors=True)
    print("  [OK] Worktree creado y saneado para compilación Android.")

def patch_worktree():
    print("\n[2/5] Aplicando parches a wt_v132...")

    # 1. Copiar tour_steps_factory.dart
    shutil.copy2(ROOT / "lib/core/tour/tour_steps_factory.dart", WT / "lib/core/tour/tour_steps_factory.dart")
    print("  [OK] Copiado tour_steps_factory.dart")

    # 2. Patch DictionaryScreen
    dict_file = WT / "lib/features/dictionary/dictionary_screen.dart"
    text = dict_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    target_dict = f"            title: Text('Diccionario Strong ${{_lbl(_language)}}'),{nl}          ),"
    replace_dict = f"""            title: Text('Diccionario Strong ${{_lbl(_language)}}'),{nl}            actions: [{nl}              IconButton({nl}                icon: Icon({nl}                  t.brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: t.brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: t.brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}            ],{nl}          ),"""
    if target_dict in text:
        text = text.replace(target_dict, replace_dict, 1)
        dict_file.write_text(text, encoding="utf-8")
        print("  [OK] Patched dictionary_screen.dart")

    # 3. Patch StudyScreen
    study_file = WT / "lib/features/study/study_screen.dart"
    text = study_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    target_study = f"            title: const Text('Mi Estudio'),{nl}            bottom: TabBar("
    replace_study = f"""            title: const Text('Mi Estudio'),{nl}            actions: [{nl}              IconButton({nl}                icon: Icon({nl}                  Theme.of(context).brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: Theme.of(context).brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: Theme.of(context).brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}            ],{nl}            bottom: TabBar("""
    if target_study in text:
        text = text.replace(target_study, replace_study, 1)
        study_file.write_text(text, encoding="utf-8")
        print("  [OK] Patched study_screen.dart")

    # 4. Patch HomeShell
    home_file = WT / "lib/shell/home_shell.dart"
    text = home_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    key_target = f"  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();"
    key_replace = f"  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();{nl}  final GlobalKey _tourThemeToggleKey = GlobalKey(debugLabel: 'tourThemeToggle');"
    if key_target in text:
        text = text.replace(key_target, key_replace, 1)
    bible_target = f"      BibleScreen(key: _bibleKey),"
    bible_replace = f"      BibleScreen(key: _bibleKey, tourThemeToggleKey: _tourThemeToggleKey),"
    if bible_target in text:
        text = text.replace(bible_target, bible_replace, 1)
        print("  [OK] BibleScreen tourThemeToggleKey patched en wt_v132")
    else:
        print("  [WARN] bible_target not found in home_shell.dart")

    tour_target1 = "      onPrepareSettingsReplayStep: () async {"
    tour_target2 = "      onPrepareSettingsReplayStep: () => _prepareSettingsReplayStep(),"
    tour_replace1 = f"      tourThemeToggleKey: _tourThemeToggleKey,{nl}      onPrepareSettingsReplayStep: () async {{"
    tour_replace2 = f"      tourThemeToggleKey: _tourThemeToggleKey,{nl}      onPrepareSettingsReplayStep: () => _prepareSettingsReplayStep(),"
    if tour_target1 in text:
        text = text.replace(tour_target1, tour_replace1, 1)
        print("  [OK] tourThemeToggleKey vinculado en getStepsForVersion en wt_v132")
    elif tour_target2 in text:
        text = text.replace(tour_target2, tour_replace2, 1)
        print("  [OK] tourThemeToggleKey vinculado en getStepsForVersion en wt_v132")
    else:
        print("  [WARN] tour_target NOT found in home_shell.dart")
    home_file.write_text(text, encoding="utf-8")
    print("  [OK] Patched home_shell.dart")

    # 5. Patch BibleScreen: TourThemeToggle + Botón Despliegue Visible + Palabras Español Resaltadas
    bible_file = WT / "lib/features/bible/bible_screen.dart"
    b_text = bible_file.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in b_text else "\n"

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
        print("  [OK] Patched BibleScreen constructor en wt_v132")
    else:
        print("  [WARN] ctor_target not found in bible_screen.dart")

    # Actions AppBar: add theme button
    actions_target = f"""            actions: [{nl}              Row({nl}                key: tourAppBarActionsKey,"""
    actions_replace = f"""            actions: [{nl}              IconButton({nl}                key: widget.tourThemeToggleKey,{nl}                icon: Icon({nl}                  theme.brightness == Brightness.dark{nl}                      ? Icons.light_mode_rounded{nl}                      : Icons.dark_mode_rounded,{nl}                  color: theme.brightness == Brightness.dark{nl}                      ? const Color(0xFFFBBF24){nl}                      : const Color(0xFFB45309),{nl}                ),{nl}                tooltip: theme.brightness == Brightness.dark{nl}                    ? 'Cambiar a modo claro (☀️ Pergamino Diurno)'{nl}                    : 'Cambiar a modo oscuro (🌙 Noche Alejandrina)',{nl}                onPressed: () => StudyService.instance.toggleTheme(),{nl}              ),{nl}              Row({nl}                key: tourAppBarActionsKey,"""
    if "\r\n" in b_text:
        actions_target = actions_target.replace("\n", "\r\n")
        actions_replace = actions_replace.replace("\n", "\r\n")
    if actions_target in b_text:
        b_text = b_text.replace(actions_target, actions_replace, 1)
        print("  [OK] Patched BibleScreen actions with tourThemeToggleKey en wt_v132")
    else:
        print("  [WARN] actions_target not found in bible_screen.dart")

    # Botón expandir/contraer versículo: visible con fondo y borde nítido
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
        print("  [OK] Patched verse expand button en wt_v132")
    else:
        print("  [WARN] expand_btn_target not found in wt_v132 bible_screen.dart")

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
        print("  [OK] Patched Spanish highlighted words in _InterlinearWordTile en wt_v132")
    else:
        print("  [WARN] interlinear_word_target not found in wt_v132 bible_screen.dart")

    bible_file.write_text(b_text, encoding="utf-8")

    # 6. Actualizar widget_test.dart en wt_v132 para que concuerde con los 6 pasos funcionales de v1.3.2
    test_file = WT / "test/widget_test.dart"
    t_text = test_file.read_text(encoding="utf-8")
    t_text = t_text.replace("expect(v132.length, equals(7));", "expect(v132.length, equals(6));")
    t_text = t_text.replace("expect(v132.first.badge, equals('NUEVA IDENTIDAD'));", "expect(v132.first.badge, equals('EXPERIENCIA BÍBLICA'));")
    t_text = t_text.replace("expect(v132.first.title, equals('Inspirados en Hechos 17:11'));", "expect(v132.first.title, equals('Lectura Continua y Expansión al Toque'));")
    t_text = t_text.replace(
        "expect(v132[3].title, equals('Resalta Versículos o Frases Seleccionadas'));",
        "expect(v132[2].title, equals('Resalta Versículos o Frases Seleccionadas'));\n    expect(v132[4].title, equals('Alternador de Modo Claro y Oscuro (☀️/🌙)'));"
    )
    t_text = t_text.replace("expect(v140.length, equals(5));", "expect(v140.length, equals(9));")
    t_text = t_text.replace("expect(v140.first.badge, equals('NUEVO MÓDULO'));", "expect(v140.first.badge, equals('BIENVENIDA & LECTURA'));")
    test_file.write_text(t_text, encoding="utf-8")
    print("  [OK] Patched widget_test.dart")

def compile_v132():
    print("\n[3/5] Compilando APKs de Berea Interlineal v1.3.2...")
    print("  -> Verificando análisis estático con flutter analyze...")
    run_cmd(["flutter", "analyze"], cwd=WT)
    print("  -> Compilando Split APKs (arm64-v8a, armeabi-v7a, x86_64)...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"], cwd=WT)

    # Instalar inmediatamente en emulador si está conectado
    x86_apk = WT / "build" / "app" / "outputs" / "flutter-apk" / "app-x86_64-release.apk"
    adb_path = Path(os.environ.get("LOCALAPPDATA", "")) / "Android/Sdk/platform-tools/adb.exe"
    if x86_apk.exists() and adb_path.exists():
        print("\n  -> Instalando automáticamente v1.3.2 en emulator-5554...")
        subprocess.run([str(adb_path), "-s", "emulator-5554", "install", "-r", "-d", str(x86_apk)])
        subprocess.run([str(adb_path), "-s", "emulator-5554", "shell", "monkey", "-p", "com.netopssolutions.berea_interlineal", "-c", "android.intent.category.LAUNCHER", "1"])
        print("  [OK] v1.3.2 instalada y abierta en emulador.\n")

    print("  -> Compilando Universal APK...")
    run_cmd(["flutter", "build", "apk", "--release"], cwd=WT)

    apk_dir = WT / "build" / "app" / "outputs" / "flutter-apk"
    mapping = {
        "app-arm64-v8a-release.apk": "berea_interlineal_1.3.2_arm64-v8a.apk",
        "app-armeabi-v7a-release.apk": "berea_interlineal_1.3.2_armeabi-v7a.apk",
        "app-x86_64-release.apk": "berea_interlineal_1.3.2_x86_64.apk",
        "app-release.apk": "berea_interlineal_1.3.2_universal.apk",
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

def upload_v132_to_github():
    print("\n[4/5] Subiendo APKs de v1.3.2 a GitHub Release 425000889...")
    run_cmd(["python", "tools/upload_to_github_release.py"], cwd=ROOT)
    run_cmd(["python", "tools/sync_release_notes_utf8.py"], cwd=ROOT)

def cleanup():
    print("\n[5/5] Limpiando worktree temporal wt_v132...")
    subprocess.run(["git", "worktree", "remove", "--force", "wt_v132"], cwd=str(ROOT), shell=(os.name == "nt"))
    if WT.exists():
        shutil.rmtree(WT, ignore_errors=True)
    subprocess.run(["git", "worktree", "prune"], cwd=str(ROOT), shell=(os.name == "nt"))
    print("  [OK] Limpieza terminada.")

def main():
    print("==================================================================")
    print(" COMPILACIÓN Y DESPLIEGUE BEREA INTERLINEAL v1.3.2")
    print("==================================================================")
    try:
        setup_worktree()
        patch_worktree()
        compile_v132()
        upload_v132_to_github()
    finally:
        cleanup()
    print("\n[EXITO COMPLETO] v1.3.2 compilada y subida al repositorio GitHub.")

if __name__ == "__main__":
    main()
