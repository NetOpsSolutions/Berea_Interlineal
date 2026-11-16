#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/verify_bible_integrity.py

Verifica rigurosamente la integridad de assets/data/logos_k_logos.db:
1. Exactamente 66 libros canónicos.
2. Exactamente 1.189 capítulos (929 en AT, 260 en NT).
3. Cero huecos en versículos: cada capítulo inicia en verso 1 y es estrictamente continuo.
4. Cobertura del 100% de traducción e interlineal poblado en cada versículo.

Devuelve exit code 0 únicamente si todas las verificaciones son exitosas.
"""

import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "data" / "logos_k_logos.db"

def main():
    print("=" * 70)
    print("🔍 AUDITORÍA DE INTEGRIDAD CANÓNICA BÍBLICA: LOGOS_K_LOGOS.DB")
    print("=" * 70)

    if not DB_PATH.exists():
        print(f"❌ Error: No existe el archivo {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    errors = []

    # 1. Verificar libros
    c.execute("SELECT COUNT(*), COUNT(DISTINCT id) FROM books")
    total_books, distinct_books = c.fetchone()
    print(f"1. Libros canónicos registrados: {total_books} / 66 esperados.")
    if total_books != 66 or distinct_books != 66:
        errors.append(f"Número de libros inválido: {total_books} (esperado 66)")

    # 2. Verificar capítulos
    c.execute("SELECT COUNT(DISTINCT book_id || ':' || chapter) FROM verses")
    total_chapters = c.fetchone()[0]
    print(f"2. Capítulos con versículos: {total_chapters} / 1.189 esperados.")
    if total_chapters != 1189:
        errors.append(f"Número de capítulos con versículos inválido: {total_chapters} (esperado 1189)")

    # Capítulos por testamento
    c.execute("""
        SELECT b.testament, COUNT(DISTINCT v.book_id || ':' || v.chapter)
        FROM verses v
        JOIN books b ON v.book_id = b.id
        GROUP BY b.testament
    """)
    testament_caps = dict(c.fetchall())
    at_caps = testament_caps.get(1, 0)
    nt_caps = testament_caps.get(2, 0)
    print(f"   • Antiguo Testamento: {at_caps} capítulos (esperado 929)")
    print(f"   • Nuevo Testamento: {nt_caps} capítulos (esperado 260)")
    if at_caps != 929 or nt_caps != 260:
        errors.append(f"Capítulos por testamento inválidos: AT={at_caps} (esperado 929), NT={nt_caps} (esperado 260)")

    # 3. Verificar continuidad estricta y ausencia total de huecos
    c.execute("SELECT id, name, testament, chapters FROM books ORDER BY testament, rowid")
    books = c.fetchall()

    total_verses = 0
    empty_translations = 0
    verses_without_words = 0
    gaps_found = []

    for b_id, name, test, ch_count in books:
        for ch in range(1, ch_count + 1):
            c.execute("SELECT verse, translation, id FROM verses WHERE book_id = ? AND chapter = ? ORDER BY verse", (b_id, ch))
            v_rows = c.fetchall()
            if not v_rows:
                gaps_found.append(f"Capítulo completamente vacío: {b_id} {ch}")
                continue

            v_nums = [r[0] for r in v_rows]
            min_v = v_nums[0]
            max_v = v_nums[-1]

            if min_v != 1:
                gaps_found.append(f"{b_id} {ch} no inicia en verso 1 (inicia en {min_v})")

            expected_set = set(range(1, max_v + 1))
            actual_set = set(v_nums)
            missing_in_ch = expected_set - actual_set
            if missing_in_ch:
                gaps_found.append(f"{b_id} {ch} tiene versículos faltantes: {sorted(missing_in_ch)}")

            for vs, trans, v_id in v_rows:
                total_verses += 1
                if not trans or not trans.strip():
                    empty_translations += 1
                c.execute("SELECT COUNT(*) FROM words WHERE verse_id = ?", (v_id,))
                w_count = c.fetchone()[0]
                if w_count == 0:
                    verses_without_words += 1

    print(f"3. Continuidad de capítulos y versículos:")
    if gaps_found:
        print(f"   ❌ Se encontraron {len(gaps_found)} anomalías de continuidad:")
        for g in gaps_found[:15]:
            print(f"      - {g}")
        errors.extend(gaps_found)
    else:
        print("   ✅ Cero huecos. Todos los 1.189 capítulos inician en verso 1 y son 100% continuos.")

    print(f"4. Estadísticas del Texto Sagrado:")
    print(f"   • Total de versículos auditados: {total_verses}")
    print(f"   • Versículos sin traducción: {empty_translations}")
    print(f"   • Versículos sin palabras interlineales: {verses_without_words}")

    if empty_translations > 0:
        errors.append(f"Hay {empty_translations} versículos sin traducción.")
    if verses_without_words > 0:
        errors.append(f"Hay {verses_without_words} versículos sin palabras interlineales.")

    # Conteo total de palabras
    c.execute("SELECT COUNT(*) FROM words")
    total_words = c.fetchone()[0]
    print(f"   • Total de palabras interlineales: {total_words}")

    conn.close()

    print("=" * 70)
    if errors:
        print(f"❌ AUDITORÍA FALLIDA CON {len(errors)} ERROR(ES).")
        sys.exit(1)
    else:
        print("🎉 AUDITORÍA EXITOSA: La base de datos cumple al 100% con todos los estándares canónicos.")
        sys.exit(0)

if __name__ == "__main__":
    main()
