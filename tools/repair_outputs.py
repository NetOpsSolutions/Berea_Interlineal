"""
Repara los .jsonl del crawl: lee en binario, conserva SOLO las lineas que
decodifican como UTF-8 valido Y parsean como JSON con las claves minimas
esperadas; descarta lineas truncadas/corruptas (las que dejo el Ctrl+C).
Hace backup .bak de cada archivo antes de reescribirlo.

Uso:
  python -X utf8 tools/repair_outputs.py            # repara data/output
  python -X utf8 tools/repair_outputs.py data/output
"""
import json
import sys
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/output")

# claves minimas que debe traer cada tipo de linea para considerarse valida
REQUIRED = {
    "interlinear_at.jsonl": {"book", "chapter", "verse"},
    "interlinear_nt.jsonl": {"book", "chapter", "verse"},
    "interlinear.jsonl":    {"book", "chapter", "verse"},
    "strong_greek.jsonl":   {"language", "code"},
    "strong_hebrew.jsonl":  {"language", "code"},
    "occurrences.jsonl":    {"language", "strong_code", "book_id"},
}


def is_valid(obj, keys):
    if not isinstance(obj, dict):
        return False
    return all(k in obj for k in keys)


def repair_file(p: Path):
    keys = REQUIRED.get(p.name)
    raw = p.read_bytes()
    good, bad = [], 0
    for chunk in raw.split(b"\n"):
        chunk = chunk.strip()
        if not chunk:
            continue
        try:
            text = chunk.decode("utf-8")          # strict: rechaza byte huérfano
        except UnicodeDecodeError:
            bad += 1
            continue
        try:
            obj = json.loads(text)
        except Exception:
            bad += 1
            continue
        if keys is not None and not is_valid(obj, keys):
            bad += 1
            continue
        good.append(text)                          # reutilizamos el texto ya decodificado

    kept = len(good)
    if bad == 0:
        print(f"{p.name:24s} OK  ({kept} lineas, 0 corruptas) — sin cambios")
        return kept, 0

    # backup + reescritura limpia
    bak = p.with_suffix(p.suffix + ".bak")
    bak.write_bytes(raw)
    p.write_text("\n".join(good) + ("\n" if good else ""), encoding="utf-8")
    print(f"{p.name:24s} REPARADO  conservadas={kept}  descartadas={bad}  (backup: {bak.name})")
    return kept, bad


def main():
    if not OUT.exists():
        sys.exit(f"No existe la carpeta: {OUT.resolve()}")
    files = sorted(OUT.glob("*.jsonl"))
    if not files:
        print("No hay .jsonl en", OUT.resolve())
        return
    tot_keep = tot_bad = 0
    for p in files:
        k, b = repair_file(p)
        tot_keep += k
        tot_bad += b
    print("-" * 50)
    print(f"TOTAL conservadas={tot_keep}  descartadas={tot_bad}")
    print("Las lineas descartadas se re-descargaran solas al relanzar el crawler")
    print("(no estan en el checkpoint 'done').")


if __name__ == "__main__":
    main()
