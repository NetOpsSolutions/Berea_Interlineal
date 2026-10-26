"""
Reporte de huecos del corpus (sin tocar los archivos de trabajo).

Modo default (SOLO disco, sin red):
  - Conteos reales por dataset vs meta.
  - Huecos INTERNOS del interlineal: versos ausentes entre 1 y el max observado
    de cada capitulo ya crawlado (esos son perdida real por warn/err).
  - Codigos strong ausentes vs el rango 1..max (ojo: Strong tiene huecos
    naturales; usa --probe para saber cuales son inexistente vs recuperable).

Modo --probe (hace red SOLO sobre los codes strong ausentes, con delay):
  - Clasifica cada code ausente en: inexistente(404) / recuperable(error de red
    o 200 parseable) / vacio(200 sin entrada parseable).
  - Imprime la lista de RECUPERABLES para relanzar el crawler sobre ellos.

Uso:
  python -X utf8 tools/report_gaps.py                 # solo disco
  python -X utf8 tools/report_gaps.py --probe         # disco + clasificacion
  python -X utf8 tools/report_gaps.py --probe --delay 1.0 --out data/output
"""
import argparse
import json
import sys
import time
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# reutilizamos el parser del crawler para clasificar paginas 200
sys.path.insert(0, str(Path(__file__).resolve().parent))
from crawl_logosklogos import (BASE, UA, CHAPTERS, AT_BOOKS, NT_BOOKS,
                               parse_strong, text_lines)

STRONG_MAX = {"greek": 5624, "hebrew": 8674}   # maximo codigo REAL de Strong
META = {
    "interlinear_at.jsonl": None,    # se estima por capitulos*versos observados
    "interlinear_nt.jsonl": None,
    "strong_greek.jsonl": STRONG_MAX["greek"],
    "strong_hebrew.jsonl": STRONG_MAX["hebrew"],
}


def read_jsonl(p):
    p = Path(p)
    if not p.exists():
        return
    with p.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    yield json.loads(line)
                except Exception:
                    pass


def count_lines(p):
    p = Path(p)
    if not p.exists():
        return 0
    n = 0
    with p.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            if line.strip():
                n += 1
    return n


def disk_counts(out):
    return {
        "interlinear_at.jsonl": count_lines(out / "interlinear_at.jsonl"),
        "interlinear_nt.jsonl": count_lines(out / "interlinear_nt.jsonl"),
        "interlinear.jsonl":    count_lines(out / "interlinear.jsonl"),
        "strong_greek.jsonl":   count_lines(out / "strong_greek.jsonl"),
        "strong_hebrew.jsonl":  count_lines(out / "strong_hebrew.jsonl"),
        "occurrences.jsonl":    count_lines(out / "occurrences.jsonl"),
    }


def strong_codes_present(out):
    pres = {"greek": set(), "hebrew": set()}
    for lang, fn in [("greek", "strong_greek.jsonl"), ("hebrew", "strong_hebrew.jsonl")]:
        for e in read_jsonl(out / fn):
            c = e.get("code")
            if isinstance(c, int):
                pres[lang].add(c)
    return pres


def interlinear_internal_gaps(out):
    """Versos ausentes en [1, max_observado] por (libro,capitulo) ya crawlado."""
    groups = {}
    for fn in ["interlinear_at.jsonl", "interlinear_nt.jsonl", "interlinear.jsonl"]:
        for v in read_jsonl(out / fn):
            key = (v.get("book"), v.get("chapter"))
            vs = v.get("verse")
            if key[0] is None or key[1] is None or not isinstance(vs, int):
                continue
            groups.setdefault(key, set()).add(vs)
    gaps = []
    total_missing = 0
    for (book, ch), verses in sorted(groups.items()):
        mx = max(verses)
        missing = [x for x in range(1, mx + 1) if x not in verses]
        if missing:
            total_missing += len(missing)
            gaps.append((book, ch, mx, missing))
    return gaps, total_missing


def probe_missing(out, lang, missing_codes, delay, timeout=30):
    s = requests.Session()
    s.headers.update({"User-Agent": UA})
    path = "strongcodes" if lang == "greek" else "strong_hebrew"
    nonexistent, recoverable, empty = [], [], []
    for i, code in enumerate(missing_codes, 1):
        time.sleep(delay)
        url = f"{BASE}/{path}/{code}"
        try:
            r = s.get(url, timeout=timeout)
        except requests.exceptions.RequestException:
            recoverable.append(code)            # fallo de red -> relanzar
            continue
        if r.status_code == 404:
            nonexistent.append(code)            # hueco legitimo de Strong
            continue
        if r.status_code >= 500 or r.status_code == 429:
            recoverable.append(code)            # servidor ocupado -> relanzar
            continue
        try:
            r.raise_for_status()
        except requests.exceptions.RequestException:
            recoverable.append(code)
            continue
        soup = BeautifulSoup(r.text, "html.parser")
        e = parse_strong(soup, lang)
        if e and e.get("code") == code:
            recoverable.append(code)            # 200 parseable pero no se guardo -> relanzar
        else:
            empty.append(code)                  # 200 sin entrada parseable
        if i % 50 == 0:
            print(f"  ...probe {lang} {i}/{len(missing_codes)}")
    return nonexistent, recoverable, empty


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/output")
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--delay", type=float, default=0.8)
    a = ap.parse_args()
    out = Path(a.out)

    print("== conteos en disco ==", out.resolve())
    dc = disk_counts(out)
    for fn, n in dc.items():
        meta = META.get(fn)
        pct = f"  {100.0*n/meta:5.1f}%" if meta else ""
        met = f" / {meta}" if meta else ""
        print(f"{fn:24s} {n:6d}{met}{pct}")

    gaps, total_missing = interlinear_internal_gaps(out)
    print(f"\n== huecos INTERNOS del interlineal: {total_missing} versos faltantes "
          f"en {len(gaps)} capitulos ==")
    for book, ch, mx, missing in gaps[:25]:
        show = missing[:12]
        more = " ..." if len(missing) > 12 else ""
        print(f"  {book} {ch} (max {mx}): faltan {len(missing)} -> {show}{more}")
    if total_missing:
        print("  (estos SON perdida real por warn/err; se recuperan relanzando el crawler)")

    pres = strong_codes_present(out)
    print("\n== codes strong ausentes vs rango ==")
    missing_map = {}
    for lang in ["greek", "hebrew"]:
        mx = STRONG_MAX[lang]
        missing = sorted(set(range(1, mx + 1)) - pres[lang])
        missing_map[lang] = missing
        note = " (incluye huecos NATURALES de Strong; usa --probe para clasificar)"
        print(f"  {lang:6s}: presentes={len(pres[lang])}  ausentes={len(missing)}{note}")
        if missing and len(missing) <= 40:
            print("           ", missing)

    if not a.probe:
        print("\n>> Corre con --probe para saber cuales ausentes son recuperables.")
        return

    print("\n== PROBE (red solo sobre ausentes) ==")
    for lang in ["greek", "hebrew"]:
        missing = missing_map[lang]
        if not missing:
            print(f"  {lang}: sin ausentes.")
            continue
        print(f"  probando {lang}: {len(missing)} codes...")
        ne, rec, emp = probe_missing(out, lang, missing, a.delay)
        print(f"  {lang}: inexistente(404)={len(ne)}  recuperable={len(rec)}  vacio(200)={len(emp)}")
        if rec:
            print(f"    RECUPERABLES (relanza el crawler): {rec[:60]}{' ...' if len(rec)>60 else ''}")
        if ne:
            print(f"    INEXISTENTES (hueco legitimo, ignorar): {ne[:40]}{' ...' if len(ne)>40 else ''}")


if __name__ == "__main__":
    main()
