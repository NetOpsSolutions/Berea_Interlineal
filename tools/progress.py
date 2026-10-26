"""
Progreso HONESTO del crawl (v10).
- Cuenta versos/codes UNICOS (dedupe por clave), no lineas crudas.
- Metas REALES: AT~23145, NT~7957, strong_greek 5624, strong_hebrew 8680.
- Muestra tambien lineas crudas y duplicados (= crudas - unicos).
Uso:  python -X utf8 tools/progress.py [data/output]
"""
import json
import sys
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/output")

# metas reales (aprox; pequenas variaciones segun edicion de Salmos/etc.)
META = {
    "interlinear_at.jsonl": 23145,
    "interlinear_nt.jsonl": 7957,
    "strong_greek.jsonl": 5624,
    "strong_hebrew.jsonl": 8680,
}

# funcion que extrae la clave UNICA de cada linea segun el archivo
def key_of(fn, d):
    if fn.startswith("interlinear"):
        return (d.get("book"), d.get("chapter"), d.get("verse"))
    if fn.startswith("strong"):
        return d.get("code")
    if fn == "occurrences.jsonl":
        return (d.get("language"), d.get("strong_code"), d.get("book_id"))
    return None


def scan(p: Path):
    """Devuelve (lineas_crudas, unicos, ejemplos_dup)."""
    raw = 0
    seen = set()
    dups = 0
    if not p.exists():
        return 0, 0, 0
    with p.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            raw += 1
            try:
                d = json.loads(line)
            except Exception:
                continue
            k = key_of(p.name, d)
            if k is None:
                continue
            if k in seen:
                dups += 1
            else:
                seen.add(k)
    return raw, len(seen), dups


print("== progreso (unicos) ", OUT.resolve(), "==")
print(f"{'archivo':24s} {'unicos':>7s} / {'meta':>7s}  {'%':>6s}   {'crudas':>7s} {'dup':>6s}")
tot_u = tot_m = 0
for fn, meta in META.items():
    raw, uniq, dups = scan(OUT / fn)
    pct = 100.0 * uniq / meta if meta else 0
    print(f"{fn:24s} {uniq:7d} / {meta:7d}  {pct:5.1f}%   {raw:7d} {dups:6d}")
    tot_u += uniq
    tot_m += meta
print(f"{'TOTAL':24s} {tot_u:7d} / {tot_m:7d}  {100.0*tot_u/tot_m:5.1f}%")
print()
print("NOTA: 'unicos' = versos/codes distintos reales. 'dup' = lineas repetidas")
print("por correr varios procesos a la vez; build_assets las ignora al generar")
print("assets. Para limpiar los .jsonl en disco:  python -X utf8 tools/dedupe_outputs.py")
print("El AT aun NO termino (meta real ~23145); el NT ya esta casi completo en unicos.")
