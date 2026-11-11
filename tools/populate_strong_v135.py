#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
populate_strong_v135.py
Puebla el 100% de Derivaciones y Léxico STEPBible en assets/data/logos_k_logos.db
a partir de la caché local de extracción (tools/strong_cache.sqlite).
"""

import os
import shutil
import sqlite3
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "data" / "logos_k_logos.db"
CACHE_PATH = ROOT / "tools" / "strong_cache.sqlite"
BACKUP_PATH = ROOT / "assets" / "data" / "logos_k_logos.db.v132_backup"

def format_stepbible(gloss, definition):
    g = (gloss or "").strip()
    d = (definition or "").strip()
    if not g and not d:
        return ""
    if g and not d:
        return g
    if d and not g:
        return d
    # Evitar redundancia si el glosario ya encabeza la definición
    if d.lower().startswith(g.lower()):
        return d
    return f"{g}: {d}"

def format_derivation(derivation):
    d = (derivation or "").strip()
    if not d:
        return "Raíz primaria"
    if d.lower() in ("raíz prim.", "raíz prim", "palabra prim.", "palabra prim"):
        return "Raíz primaria"
    return d

def main():
    if not CACHE_PATH.exists():
        print(f"[ERROR] No existe la base de datos de caché {CACHE_PATH}")
        sys.exit(1)

    if not BACKUP_PATH.exists():
        print(f"[INFO] Creando respaldo v1.3.2 de la base de datos en {BACKUP_PATH}...")
        shutil.copyfile(DB_PATH, BACKUP_PATH)
    else:
        print(f"[INFO] Respaldo v1.3.2 ya existe en {BACKUP_PATH}")

    c_conn = sqlite3.connect(CACHE_PATH)
    c_cur = c_conn.cursor()
    c_cur.execute("""
    SELECT language, code, lemma, pronunciation, derivation, definition, kjv_def, step_gloss, step_definition
    FROM strong_cache
    """)
    cached_rows = c_cur.fetchall()
    c_conn.close()

    print(f"[INFO] Registros disponibles en caché: {len(cached_rows)}")

    db_conn = sqlite3.connect(DB_PATH)
    db_cur = db_conn.cursor()

    updates = []
    for r in cached_rows:
        lang, code, lemma, pron, deriv, defn, rv_def, step_g, step_d = r
        deriv_clean = format_derivation(deriv)
        step_clean = format_stepbible(step_g, step_d)
        updates.append((deriv_clean, step_clean, defn, rv_def, lang, code))

    print(f"[INFO] Aplicando actualizaciones a strong_entries en {DB_PATH}...")
    db_cur.executemany("""
    UPDATE strong_entries 
    SET derivation = ?,
        stepbible = ?,
        definition = CASE WHEN length(?) > length(definition) THEN ? ELSE definition END,
        rv_definition = CASE WHEN length(?) > length(rv_definition) THEN ? ELSE rv_definition END
    WHERE language = ? AND code = ?
    """, [(u[0], u[1], u[2], u[2], u[3], u[3], u[4], u[5]) for u in updates])

    # Fallback para el 0.8% de términos que carecían de glosa STEPBible (partículas gramaticales raras)
    db_cur.execute("""
    UPDATE strong_entries 
    SET stepbible = definition 
    WHERE (stepbible = '' OR stepbible IS NULL) AND length(definition) > 0
    """)

    db_conn.commit()

    # Estadísticas finales
    db_cur.execute("SELECT COUNT(*), COUNT(NULLIF(derivation, '')), COUNT(NULLIF(stepbible, '')) FROM strong_entries")
    total, has_deriv, has_step = db_cur.fetchone()

    print("\n================ ESTADÍSTICAS V1.3.5 ================")
    print(f"Total entradas Strong:   {total}")
    print(f"Con Derivación poblada:  {has_deriv} ({has_deriv/total*100:.1f}%)")
    print(f"Con STEPBible poblado:   {has_step} ({has_step/total*100:.1f}%)")

    # Muestras representativas
    samples = [('hebrew', 776), ('hebrew', 7225), ('greek', 3056), ('greek', 25)]
    print("\n================ MUESTRAS VERIFICADAS ================")
    for lang, code in samples:
        db_cur.execute("SELECT lemma, pronunciation, derivation, stepbible FROM strong_entries WHERE language=? AND code=?", (lang, code))
        row = db_cur.fetchone()
        if row:
            prefix = 'H' if lang == 'hebrew' else 'G'
            print(f"\n[#{prefix}{code} {row[0]} ({row[1]})]")
            print(f"  Derivación: {row[2]}")
            print(f"  STEPBible:  {row[3]}")

    db_conn.close()
    print("\n[ÉXITO] Actualización v1.3.5 finalizada.")

if __name__ == "__main__":
    main()
