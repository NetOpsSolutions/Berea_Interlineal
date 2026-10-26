"""
Normaliza la salida del crawler a los assets que lee la app.
v7: lee el GLOB interlinear*.jsonl (at + nt + el viejo interlinear.jsonl de v6),
deduplica por (libro,cap,verso), propaga 'language' a versiculo y palabra,
merge-protege la semilla y DERIVA la concordancia. Opcional: genera .db.

Uso:
  python -X utf8 tools/build_assets.py --in data/output --out assets/data
  python -X utf8 tools/build_assets.py --in data/output --out assets/data --db logos_k_logos.db
"""
import argparse
import json
import sqlite3
from collections import defaultdict
from pathlib import Path

AT_ORDER = ["Gn","Ex","Lv","Nm","Dt","Jos","Jue","Rt","1S","2S","1R","2R","1Cr","2Cr","Esd","Neh",
    "Est","Job","Sal","Pr","Ec","Cnt","Is","Jer","Lm","Ez","Dn","Os","Jl","Am","Abd","Jon","Mi",
    "Nah","Hab","Sof","Ha","Zac","Mal"]
NT_ORDER = ["Mt","Mr","Lc","Jn","Hch","Ro","1Co","2Co","Ga","Ef","Fil","Col","1Ts","2Ts","1Ti","2Ti",
    "Tit","Flm","He","Stg","1P","2P","1Jn","2Jn","3Jn","Jud","Ap"]
AT_SET = set(AT_ORDER)
NT_SET = set(NT_ORDER)


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


def read_glob(pattern):
    for p in sorted(Path(".").glob(pattern)):
        yield from read_jsonl(p)


def load_json_if_exists(p):
    p = Path(p)
    if not p.exists():
        return None
    try:
        with p.open("r", encoding="utf-8", errors="replace") as f:
            return json.load(f)
    except Exception:
        return None


def _lang_for_book(book):
    if book in AT_SET:
        return "hebrew"
    if book in NT_SET:
        return "greek"
    return ""


def build_strong(inp, out):
    for lang, fn in [("greek", "strong_greek.jsonl"), ("hebrew", "strong_hebrew.jsonl")]:
        base = {}
        existing = load_json_if_exists(Path(out) / f"strong_{lang}.json")
        if existing:
            for e in existing.get("entries", []):
                base[e["code"]] = e
        for e in read_jsonl(Path(inp) / fn):
            base[e["code"]] = {"code": e["code"], "lemma": e.get("lemma", ""),
                "pronunciation": e.get("pronunciation", ""), "derivation": e.get("derivation", ""),
                "definition": e.get("definition", ""), "rv_definition": e.get("rv_definition", ""),
                "stepbible": e.get("stepbible", "")}
        entries = sorted(base.values(), key=lambda x: x["code"])
        Path(out).mkdir(parents=True, exist_ok=True)
        with (Path(out) / f"strong_{lang}.json").open("w", encoding="utf-8") as f:
            json.dump({"language": lang, "entries": entries}, f, ensure_ascii=False)
        print("strong", lang, len(entries))


def build_interlinear(inp, out):
    verses = {}
    # 1) semilla existente (proteger)
    for fname in ["interlinear_at.json", "interlinear_nt.json"]:
        existing = load_json_if_exists(Path(out) / fname)
        if existing:
            for v in existing.get("verses", []):
                ref = (v["book"], v["chapter"], v["verse"])
                v.setdefault("language", _lang_for_book(v["book"]))
                for w in v.get("words", []):
                    w.setdefault("language", v["language"])
                verses[ref] = v
    # 2) crawl: GLOB interlinear*.jsonl (at + nt + viejo), dedupe, gana el que trae palabras
    n_new = 0
    for v in read_glob(str(Path(inp) / "interlinear*.jsonl")):
        ref = (v["book"], v["chapter"], v["verse"])
        words = v.get("words", [])
        lang = v.get("language") or _lang_for_book(v["book"])
        if words or ref not in verses:
            for w in words:
                w["language"] = w.get("language") or lang
            verses[ref] = {"book": v["book"], "chapter": v["chapter"], "verse": v["verse"],
                           "translation": v.get("translation", ""), "language": lang,
                           "words": words}
            if words:
                n_new += 1
    at, nt = [], []
    for v in verses.values():
        v.setdefault("words", []).sort(key=lambda x: x.get("position", 0))
        (at if v["book"] in AT_SET else nt).append(v)
    at.sort(key=lambda x: (AT_ORDER.index(x["book"]), x["chapter"], x["verse"]))
    nt.sort(key=lambda x: (NT_ORDER.index(x["book"]), x["chapter"], x["verse"]))
    Path(out).mkdir(parents=True, exist_ok=True)
    with (Path(out) / "interlinear_at.json").open("w", encoding="utf-8") as f:
        json.dump({"testament": 1, "language": "hebrew", "verses": at}, f, ensure_ascii=False)
    with (Path(out) / "interlinear_nt.json").open("w", encoding="utf-8") as f:
        json.dump({"testament": 2, "language": "greek", "verses": nt}, f, ensure_ascii=False)
    print("interlinear AT", len(at), "NT", len(nt), "(nuevos con palabras:", n_new, ")")


def build_occurrences(inp, out):
    agg = defaultdict(lambda: {"verses": 0, "occurrences": 0})
    for o in read_jsonl(Path(inp) / "occurrences.jsonl"):
        k = (o["language"], o["strong_code"], o["book_id"])
        agg[k]["verses"] = max(agg[k]["verses"], o.get("verses", 0))
        agg[k]["occurrences"] = max(agg[k]["occurrences"], o.get("occurrences", 0))
    seen_verses = set()
    for v in read_glob(str(Path(inp) / "interlinear*.jsonl")):
        lang = v.get("language") or _lang_for_book(v["book"])
        book = v["book"]
        for w in v.get("words", []):
            sc = w.get("strong_code")
            if sc is None:
                continue
            k = (lang, sc, book)
            agg[k]["occurrences"] += 1
            vk = (k, v["chapter"], v["verse"])
            if vk not in seen_verses:
                seen_verses.add(vk)
                agg[k]["verses"] += 1
    rows = [{"language": l, "strong_code": c, "book_id": b,
             "verses": val["verses"], "occurrences": val["occurrences"]}
            for (l, c, b), val in agg.items()]
    rows.sort(key=lambda r: (r["language"], r["strong_code"], r["book_id"]))
    Path(out).mkdir(parents=True, exist_ok=True)
    with (Path(out) / "occurrences.json").open("w", encoding="utf-8") as f:
        json.dump({"occurrences": rows}, f, ensure_ascii=False)
    print("occurrences", len(rows), "(derivadas del interlineal + sitio)")


SCHEMA = """
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS books (id TEXT PRIMARY KEY, name TEXT NOT NULL, testament INTEGER NOT NULL, chapters INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS verses (id INTEGER PRIMARY KEY AUTOINCREMENT, book_id TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL, translation TEXT NOT NULL, UNIQUE(book_id, chapter, verse));
CREATE TABLE IF NOT EXISTS words (id INTEGER PRIMARY KEY AUTOINCREMENT, verse_id INTEGER NOT NULL, position INTEGER NOT NULL, strong_code INTEGER, language TEXT NOT NULL, lemma TEXT NOT NULL, surface TEXT NOT NULL, parsing TEXT NOT NULL, translation TEXT NOT NULL, FOREIGN KEY(verse_id) REFERENCES verses(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS strong_entries (language TEXT NOT NULL, code INTEGER NOT NULL, lemma TEXT NOT NULL, pronunciation TEXT, derivation TEXT, definition TEXT, rv_definition TEXT, stepbible TEXT, PRIMARY KEY(language, code));
CREATE TABLE IF NOT EXISTS occurrences (language TEXT NOT NULL, strong_code INTEGER NOT NULL, book_id TEXT NOT NULL, verses INTEGER NOT NULL DEFAULT 0, occurrences INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(language, strong_code, book_id));
"""


def build_db(inp, out, db_path):
    conn = sqlite3.connect(db_path)
    conn.executescript(SCHEMA)
    cur = conn.cursor()
    for lang, fn in [("greek", "strong_greek.jsonl"), ("hebrew", "strong_hebrew.jsonl")]:
        for e in read_jsonl(Path(inp) / fn):
            cur.execute("""INSERT OR REPLACE INTO strong_entries
              (language,code,lemma,pronunciation,derivation,definition,rv_definition,stepbible)
              VALUES (?,?,?,?,?,?,?,?)""",
              (lang, e["code"], e.get("lemma",""), e.get("pronunciation",""),
               e.get("derivation",""), e.get("definition",""), e.get("rv_definition",""),
               e.get("stepbible","")))
    vids = {}
    for v in read_glob(str(Path(inp) / "interlinear*.jsonl")):
        if not v.get("words"):
            continue
        cur.execute("""INSERT OR REPLACE INTO verses (book_id,chapter,verse,translation)
          VALUES (?,?,?,?)""", (v["book"], v["chapter"], v["verse"], v.get("translation","")))
        vids[(v["book"], v["chapter"], v["verse"])] = cur.lastrowid
    for v in read_glob(str(Path(inp) / "interlinear*.jsonl")):
        vid = vids.get((v["book"], v["chapter"], v["verse"]))
        if not vid:
            continue
        vlang = v.get("language") or _lang_for_book(v["book"])
        for w in v.get("words", []):
            cur.execute("""INSERT INTO words
              (verse_id,position,strong_code,language,lemma,surface,parsing,translation)
              VALUES (?,?,?,?,?,?,?,?)""",
              (vid, w.get("position",0), w.get("strong_code"),
               w.get("language") or vlang, w.get("lemma",""), w.get("surface",""),
               w.get("parsing",""), w.get("translation","")))
    agg = defaultdict(lambda: {"verses": 0, "occurrences": 0})
    seen = set()
    for v in read_glob(str(Path(inp) / "interlinear*.jsonl")):
        lang = v.get("language") or _lang_for_book(v["book"]); book = v["book"]
        for w in v.get("words", []):
            sc = w.get("strong_code")
            if sc is None: continue
            k = (lang, sc, book)
            agg[k]["occurrences"] += 1
            vk = (k, v["chapter"], v["verse"])
            if vk not in seen:
                seen.add(vk); agg[k]["verses"] += 1
    for (l, c, b), val in agg.items():
        cur.execute("""INSERT OR REPLACE INTO occurrences
          (language,strong_code,book_id,verses,occurrences) VALUES (?,?,?,?,?)""",
          (l, c, b, val["verses"], val["occurrences"]))
    conn.commit()
    conn.close()
    print("db ->", db_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", default="data/output")
    ap.add_argument("--out", default="assets/data")
    ap.add_argument("--db", default=None)
    a = ap.parse_args()
    build_strong(a.inp, a.out)
    build_interlinear(a.inp, a.out)
    build_occurrences(a.inp, a.out)
    if a.db:
        build_db(a.inp, a.out, a.db)
    print("OK. Assets (glob + dedupe + language por palabra + occurrences) en", a.out)
    print("Web: relanza flutter run -d chrome (los assets se re-empaquedan al compilar).")
    print("Android/iOS: borra datos de la app para re-sembrar SQLite.")


if __name__ == "__main__":
    main()
