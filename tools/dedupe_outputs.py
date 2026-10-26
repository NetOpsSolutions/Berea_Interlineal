"""
Limpia lineas DUPLICADAS de los .jsonl del crawl, conservando la PRIMERA
ocurrencia de cada clave unica. Hace backup .dedupbak antes de reescribir.
build_assets YA dedupea al generar assets; esto solo ordena los archivos de
trabajo para que progress.py y el tamano en disco digan la verdad.

Claves unicas:
  interlinear_*  -> (book, chapter, verse)
  strong_*       -> code
  occurrences    -> (language, strong_code, book_id)

Uso:
  python -X utf8 tools/dedupe_outputs.py            # data/output
  python -X utf8 tools/dedupe_outputs.py data/output
"""
import json
import sys
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/output")


def key_of(fn, d):
    if fn.startswith("interlinear"):
        return (d.get("book"), d.get("chapter"), d.get("verse"))
    if fn.startswith("strong"):
        return d.get("code")
    if fn == "occurrences.jsonl":
        return (d.get("language"), d.get("strong_code"), d.get("book_id"))
    return None


def dedupe_file(p: Path):
    raw_lines = []
    with p.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.strip():
                raw_lines.append(line)

    seen = set()
    kept = []
    dropped_dup = 0
    dropped_bad = 0
    for line in raw_lines:
        try:
            d = json.loads(line)
        except Exception:
            dropped_bad += 1
            continue
        k = key_of(p.name, d)
        if k is None:
            kept.append(line)            # sin clave reconocible -> conservar
            continue
        if k in seen:
            dropped_dup += 1
            continue
        seen.add(k)
        kept.append(line)

    if dropped_dup == 0 and dropped_bad == 0:
        print(f"{p.name:24s} limpio ({len(kept)} lineas unicas)")
        return 0, 0

    bak = p.with_suffix(p.suffix + ".dedupbak")
    if not bak.exists():
        bak.write_text("\n".join(raw_lines) + "\n", encoding="utf-8")
    p.write_text("\n".join(kept) + ("\n" if kept else ""), encoding="utf-8")
    print(f"{p.name:24s} REESCRITO  unicas={len(kept)}  dup_eliminados={dropped_dup}  "
          f"malformadas={dropped_bad}  (backup: {bak.name})")
    return dropped_dup, dropped_bad


def main():
    if not OUT.exists():
        sys.exit(f"No existe la carpeta: {OUT.resolve()}")
    files = sorted(OUT.glob("*.jsonl"))
    if not files:
        print("No hay .jsonl en", OUT.resolve())
        return
    td = tb = 0
    for p in files:
        d, b = dedupe_file(p)
        td += d
        tb += b
    print("-" * 50)
    print(f"TOTAL duplicados eliminados={td}  malformadas descartadas={tb}")
    print("Ahora progress.py mostrara % reales. Los backups .dedupbak estan en", OUT.resolve())


if __name__ == "__main__":
    main()
