#!/usr/bin/env python3
"""
tools/rebrand_and_build_legacy.py

Automates the complete rebranding, cleanup, and compilation of legacy versions
(v1.3.1 and v1.3.0) to align with v1.3.2 standards:
1. Rebrand to 'Berea Interlineal' with official mipmaps and splash screen.
2. Remove debug option 'Vista previa visual (Simulador de diseño)' from Settings.
3. Sanitize in-app update dialog (no packaging tables or SHA-256 blocks; button strictly 'Actualizar').
4. Add android.permission.POST_NOTIFICATIONS to AndroidManifest.xml.
5. Apply high-contrast dark theme to update notification SnackBar.
6. Configure signing with production keystore (berea-release.jks).
7. Compile split APKs (arm64-v8a, armeabi-v7a, x86_64) and universal APK.
8. Place compiled APKs in release_builds/v{tag}/.
"""

import os
import sys
import shutil
import subprocess
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
APP_ID = "com.netopssolutions.berea_interlineal"
APP_NAME = "Berea Interlineal"

def run_cmd(cmd, cwd=None, check=True):
    cmd_str = " ".join(cmd) if isinstance(cmd, list) else cmd
    print(f"--> Running: {cmd_str}")
    res = subprocess.run(
        cmd_str,
        cwd=cwd or str(REPO_ROOT),
        shell=True,
        text=True,
        capture_output=True,
        encoding="utf-8",
        errors="replace"
    )
    if check and res.returncode != 0:
        print(f"ERROR: Command failed with exit code {res.returncode}")
        print(f"STDOUT:\n{res.stdout}")
        print(f"STDERR:\n{res.stderr}")
        raise RuntimeError(f"Command failed: {cmd}")
    return res

def backup_master_assets(backup_dir: Path):
    print(">>> Backing up master assets...")
    if backup_dir.exists():
        shutil.rmtree(backup_dir)
    backup_dir.mkdir(parents=True, exist_ok=True)

    # 1. res (mipmaps, drawables)
    res_src = REPO_ROOT / "android" / "app" / "src" / "main" / "res"
    shutil.copytree(res_src, backup_dir / "res")

    # 2. Splash image
    icon_src = REPO_ROOT / "assets" / "images" / "berea_interlineal_icon.jpg"
    shutil.copy2(icon_src, backup_dir / "berea_interlineal_icon.jpg")

    # 3. Splash screen Dart code
    splash_src = REPO_ROOT / "lib" / "features" / "splash" / "splash_screen.dart"
    shutil.copy2(splash_src, backup_dir / "splash_screen.dart")

    # 4. Keystore & key.properties
    shutil.copy2(REPO_ROOT / "android" / "berea-release.jks", backup_dir / "berea-release.jks")
    shutil.copy2(REPO_ROOT / "android" / "key.properties", backup_dir / "key.properties")

def apply_branding_and_cleanup(tag: str, backup_dir: Path):
    print(f">>> Applying branding and UI cleanups to {tag}...")

    # 1. Inject res (mipmaps)
    res_dst = REPO_ROOT / "android" / "app" / "src" / "main" / "res"
    shutil.rmtree(res_dst, ignore_errors=True)
    shutil.copytree(backup_dir / "res", res_dst)

    # 2. Inject berea_interlineal_icon.jpg
    images_dir = REPO_ROOT / "assets" / "images"
    images_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(backup_dir / "berea_interlineal_icon.jpg", images_dir / "berea_interlineal_icon.jpg")

    # 3. Update pubspec.yaml to include berea_interlineal_icon.jpg
    pubspec_path = REPO_ROOT / "pubspec.yaml"
    pubspec_text = pubspec_path.read_text(encoding="utf-8")
    if "berea_interlineal_icon.jpg" not in pubspec_text:
        pubspec_text = pubspec_text.replace(
            "assets/data/sample.json",
            "assets/data/sample.json\n    - assets/images/berea_interlineal_icon.jpg"
        )
        pubspec_path.write_text(pubspec_text, encoding="utf-8")
        print("  -> pubspec.yaml updated with berea_interlineal_icon.jpg")

    # 4. Inject splash_screen.dart
    splash_dst = REPO_ROOT / "lib" / "features" / "splash" / "splash_screen.dart"
    shutil.copy2(backup_dir / "splash_screen.dart", splash_dst)
    print("  -> Injected official splash_screen.dart")

    # 5. AndroidManifest.xml
    manifest_path = REPO_ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    manifest = manifest_path.read_text(encoding="utf-8")
    manifest = manifest.replace('android:label="logos_k_logos"', f'android:label="{APP_NAME}"')
    manifest = manifest.replace('android:label="Logos K Logos"', f'android:label="{APP_NAME}"')
    if "POST_NOTIFICATIONS" not in manifest:
        manifest = manifest.replace(
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>',
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
        )
    if 'android:roundIcon=' not in manifest:
        manifest = manifest.replace(
            'android:icon="@mipmap/ic_launcher"',
            'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"'
        )
    if 'android:name=".MainActivity"' in manifest and f'android:label="{APP_NAME}"' not in manifest:
        manifest = re.sub(
            r'<activity\s+android:name="\.MainActivity"',
            f'<activity\n            android:name=".MainActivity"\n            android:label="{APP_NAME}"\n            android:icon="@mipmap/ic_launcher"\n            android:roundIcon="@mipmap/ic_launcher_round"',
            manifest
        )
    manifest_path.write_text(manifest, encoding="utf-8")
    print("  -> AndroidManifest.xml updated with Berea Interlineal and POST_NOTIFICATIONS")

    # 6. lib/main.dart
    main_dart = REPO_ROOT / "lib" / "main.dart"
    if main_dart.exists():
        md = main_dart.read_text(encoding="utf-8")
        md = re.sub(r"title:\s*['\"]Logos K Logos['\"]", f"title: '{APP_NAME}'", md)
        md = md.replace("'logos_k_logos'", f"'{APP_NAME}'")
        main_dart.write_text(md, encoding="utf-8")
        print("  -> lib/main.dart updated with Berea Interlineal title")

    # 7. lib/features/settings/settings_screen.dart
    settings_dart = REPO_ROOT / "lib" / "features" / "settings" / "settings_screen.dart"
    if settings_dart.exists():
        sd = settings_dart.read_text(encoding="utf-8")
        sd = sd.replace("Logos K Logos", APP_NAME)
        # Remove demo/simulator ListTile and Divider across all versions
        demo_tile_pattern = r"const\s+Divider\([^)]*\),\s*ListTile\([\s\S]*?onTap:\s*_openDemo,\s*\),"
        sd = re.sub(demo_tile_pattern, "", sd)
        # Remove _openDemo method
        demo_method_pattern = r"void\s+_openDemo\(\)\s*\{[^}]*\}"
        sd = re.sub(demo_method_pattern, "", sd, flags=re.DOTALL)
        settings_dart.write_text(sd, encoding="utf-8")
        print("  -> settings_screen.dart: Removed 'Vista previa visual' simulator and updated titles")

    # 8. lib/core/update/update_dialog.dart (IN-PLACE modification)
    update_dialog_path = REPO_ROOT / "lib" / "core" / "update" / "update_dialog.dart"
    if update_dialog_path.exists():
        ud = update_dialog_path.read_text(encoding="utf-8")

        # 8a. Button label: strictly 'Actualizar'
        ud = re.sub(r"Text\('Actualizar \(\$\{widget\.release\.apkAbi\}\)'\)", "const Text('Actualizar')", ud)
        ud = re.sub(r'Text\("Actualizar \(\$\{widget\.release\.apkAbi\}\)"\)', "const Text('Actualizar')", ud)
        ud = re.sub(r"Text\('S[íi], descargar \(\$\{widget\.release\.apkAbi\}\)'\)", "const Text('Actualizar')", ud)
        ud = re.sub(r'Text\("S[íi], descargar \(\$\{widget\.release\.apkAbi\}\)"\)', "const Text('Actualizar')", ud)
        ud = ud.replace("label: Text('Actualizar (${widget.release.apkAbi})')", "label: const Text('Actualizar')")
        ud = ud.replace("label: Text('Sí, descargar (${widget.release.apkAbi})')", "label: const Text('Actualizar')")

        # 8b. Downloading progress text: clean without technical ABI
        ud = ud.replace("Descargando ${widget.release.apkAbi}...", "Descargando actualización...")

        # 8c. Release notes view: break before technical distribution table and checksums
        sanitizer_code = """      final line = rawLine.trimRight();
      final trimmed = line.trim();

      // Omitir tablas tecnicas de distribucion y bloques de checksums para el usuario
      if (trimmed.contains('\u00bfQu\u00e9 paquete descargar?') ||
          trimmed.contains('Verificaci\u00f3n de Integridad') ||
          trimmed.contains('SHA-256 Checksums') ||
          trimmed.startsWith('| Archivo') ||
          trimmed.startsWith('|---|') ||
          trimmed.startsWith('| `')) {
        break;
      }"""
        if "trimmed.contains" not in ud:
            ud = ud.replace("      final line = rawLine.trimRight();", sanitizer_code)

        update_dialog_path.write_text(ud, encoding="utf-8")
        print("  -> update_dialog.dart: Sanitized release notes and standardized button to 'Actualizar'")

    # 9. lib/shell/home_shell.dart (Dark mode SnackBar)
    home_shell_path = REPO_ROOT / "lib" / "shell" / "home_shell.dart"
    if home_shell_path.exists():
        hs = home_shell_path.read_text(encoding="utf-8")
        new_snack = """ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 6,
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.1),
            ),
            duration: const Duration(seconds: 10),
            content: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Color(0xFFFCD34D), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nueva versi\\u00f3n ${release.tagName} disponible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VER NOVEDADES',
              textColor: const Color(0xFFFDE047),
              onPressed: () {
                showUpdateDialog(context, release);
              },
            ),
          ),
        );"""
        old_snack_regex = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\([\s\S]*?duration:\s*const\s*Duration\(seconds:\s*10\),\s*behavior:\s*SnackBarBehavior\.floating,\s*\),\s*\);"
        if re.search(old_snack_regex, hs):
            hs = re.sub(old_snack_regex, lambda m: new_snack, hs)
            home_shell_path.write_text(hs, encoding="utf-8")
            print("  -> home_shell.dart: Injected dark slate update SnackBar")

    # 9b. lib/core/theme.dart (Default snackBarTheme)
    theme_dart_path = REPO_ROOT / "lib" / "core" / "theme.dart"
    if theme_dart_path.exists():
        tc = theme_dart_path.read_text(encoding="utf-8")
        if "snackBarTheme:" not in tc:
            snack_theme_code = """    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: const Color(0xFFFDE047),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF3B82F6), width: 1.1),
      ),
    ),
  );
}"""
            tc = re.sub(r"\);\s*\}\s*$", lambda m: snack_theme_code, tc)
            theme_dart_path.write_text(tc, encoding="utf-8")
            print("  -> theme.dart: Added default dark snackBarTheme")

    # 10. lib/core/update/update_service.dart (Method channel)
    update_svc = REPO_ROOT / "lib" / "core" / "update" / "update_service.dart"
    if update_svc.exists():
        usc = update_svc.read_text(encoding="utf-8")
        usc = usc.replace("MethodChannel('com.example.logos_k_logos/updater')", f"MethodChannel('{APP_ID}/updater')")
        usc = usc.replace("Logos K Logos", APP_NAME)
        usc = usc.replace("LogosKLogos", "BereaInterlineal")
        update_svc.write_text(usc, encoding="utf-8")
        print("  -> update_service.dart: Updated channel and names")

    # 11. android/app/build.gradle.kts (App ID and signing config)
    gradle_path = REPO_ROOT / "android" / "app" / "build.gradle.kts"
    gc = gradle_path.read_text(encoding="utf-8")
    if "keystoreProperties" not in gc:
        header = """import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""
        gc = header + gc

    if 'create("release")' not in gc:
        signing_block = """    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { 
                val f = file(it)
                if (f.exists()) f else rootProject.file(it)
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
"""
        gc = gc.replace("android {", f"android {{\n{signing_block}")

    gc = re.sub(r'namespace\s*=\s*"[^"]+"', f'namespace = "{APP_ID}"', gc)
    gc = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{APP_ID}"', gc)
    gc = gc.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
    gradle_path.write_text(gc, encoding="utf-8")
    print("  -> build.gradle.kts: Configured release signing and package ID")

    # 12. MainActivity.kt relocation
    kotlin_dir = REPO_ROOT / "android" / "app" / "src" / "main" / "kotlin" / "com" / "netopssolutions" / "berea_interlineal"
    kotlin_dir.mkdir(parents=True, exist_ok=True)
    old_main = REPO_ROOT / "android" / "app" / "src" / "main" / "kotlin" / "com" / "example" / "logos_k_logos" / "MainActivity.kt"
    if old_main.exists():
        kt = old_main.read_text(encoding="utf-8")
        kt = kt.replace("package com.example.logos_k_logos", f"package {APP_ID}")
        kt = kt.replace('"com.example.logos_k_logos/updater"', f'"{APP_ID}/updater"')
        kt = kt.replace('"logos_ota_updates"', '"berea_ota_updates"')
        kt = kt.replace('"com.example.logos_k_logos.ACTION_OPEN_OTA_UPDATE"', f'"{APP_ID}.ACTION_OPEN_OTA_UPDATE"')
        (kotlin_dir / "MainActivity.kt").write_text(kt, encoding="utf-8")
        shutil.rmtree(REPO_ROOT / "android" / "app" / "src" / "main" / "kotlin" / "com" / "example", ignore_errors=True)
        print("  -> MainActivity.kt relocated to com.netopssolutions.berea_interlineal")

def compile_and_collect(tag: str):
    print(f">>> Compiling {tag}...")

    # Build split APKs
    print(f"  -> Building split per ABI for {tag}...")
    run_cmd(["flutter", "build", "apk", "--release", "--split-per-abi"])

    # Build universal APK
    print(f"  -> Building universal release for {tag}...")
    run_cmd(["flutter", "build", "apk", "--release"])

    # Output paths
    build_out = REPO_ROOT / "build" / "app" / "outputs" / "flutter-apk"
    dest_dir = REPO_ROOT / "release_builds" / f"v{tag}"
    dest_dir.mkdir(parents=True, exist_ok=True)

    if tag == "1.3.1":
        shutil.copy2(build_out / "app-arm64-v8a-release.apk", dest_dir / "logos_k_logos_1.3.1_arm64-v8a.apk")
        shutil.copy2(build_out / "app-armeabi-v7a-release.apk", dest_dir / "logos_k_logos_1.3.1_armeabi-v7a.apk")
        shutil.copy2(build_out / "app-x86_64-release.apk", dest_dir / "logos_k_logos_1.3.1_x86_64.apk")
        shutil.copy2(build_out / "app-release.apk", dest_dir / "logos_k_logos_1.3.1_universal.apk")
    elif tag == "1.3.0":
        shutil.copy2(build_out / "app-arm64-v8a-release.apk", dest_dir / "app-arm64-v8a-release.apk")
        shutil.copy2(build_out / "app-armeabi-v7a-release.apk", dest_dir / "app-armeabi-v7a-release.apk")
        shutil.copy2(build_out / "app-x86_64-release.apk", dest_dir / "app-x86_64-release.apk")
        shutil.copy2(build_out / "app-release.apk", dest_dir / "app-release.apk")
        shutil.copy2(build_out / "app-release.apk", dest_dir / "app-universal-release.apk")

    print(f">>> [SUCCESS] Successfully compiled and collected APKs for v{tag} into {dest_dir}")

def process_version(tag: str, backup_dir: Path):
    branch_name = f"temp_rebrand_{tag.replace('.', '')}"
    print(f"\n=======================================================")
    print(f" PROCESSING VERSION {tag}")
    print(f"=======================================================")

    try:
        run_cmd(["git", "checkout", "-f", "master"])
        run_cmd(["git", "checkout", "-B", branch_name, tag])

        # Ensure keystore & key.properties are in android/
        dest_android = REPO_ROOT / "android"
        shutil.copy2(backup_dir / "berea-release.jks", dest_android / "berea-release.jks")
        shutil.copy2(backup_dir / "key.properties", dest_android / "key.properties")

        apply_branding_and_cleanup(tag, backup_dir)
        compile_and_collect(tag)

    finally:
        print(f">>> Cleaning up branch {branch_name} and returning to master...")
        run_cmd(["git", "checkout", "-f", "master"])
        subprocess.run(["git", "branch", "-D", branch_name], cwd=str(REPO_ROOT), capture_output=True)

def main():
    if len(sys.argv) > 1:
        tags = [sys.argv[1]]
    else:
        tags = ["1.3.1", "1.3.0"]

    backup_dir = Path(os.environ.get("TEMP", "/tmp")) / "berea_master_assets_backup"
    
    # 1. Back up assets while on master
    run_cmd(["git", "checkout", "-f", "master"])
    backup_master_assets(backup_dir)

    # 2. Process requested tags
    for tag in tags:
        process_version(tag, backup_dir)

    print("\n>>> ALL REQUESTED VERSIONS COMPILED AND COLLECTED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
