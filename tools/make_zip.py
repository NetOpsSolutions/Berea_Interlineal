"""
Empaqueta el proyecto en LogosKLogos.zip (en el Escritorio), excluyendo
carpetas pesadas/temporales (build, .dart_tool, data/output crudo, caches).
Uso: python tools/make_zip.py [ruta_base]
"""
import os
import sys
import zipfile
from pathlib import Path

EXCLUDE_DIRS = {".git", "build", ".dart_tool", ".idea", ".vscode",
                "node_modules", "__pycache__", "data"}
EXCLUDE_FILES = {".DS_Store", "Thumbs.db"}


def zip_project(base, dest):
    base = Path(base)
    n = 0
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(base):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            for f in files:
                if f in EXCLUDE_FILES: continue
                fp = Path(root) / f
                rel = fp.relative_to(base.parent)
                z.write(fp, rel)
                n += 1
    print(f"{n} archivos -> {dest}")


def main():
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        r"D:\user\Desktop\SMART FILES\OCHOA MORA\TRABAJOS EN PHYTON\LogosKLogos")
    desktop = Path(os.path.expanduser("~")) / "Desktop"
    if not desktop.exists(): desktop = base
    dest = desktop / "LogosKLogos.zip"
    zip_project(base, dest)


if __name__ == "__main__":
    main()
