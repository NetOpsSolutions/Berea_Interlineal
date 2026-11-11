#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
populate_strong_v137.py
Genera y puebla:
1. Tabla relacional `strong_relations` (derives_from, parent_of, compares_with, synonym)
2. Nuevas columnas en `strong_entries`: similarities, compare_codes, derived_codes
3. Extracción de vínculos léxicos bidireccionales y familias de palabras
4. Inyección del módulo exegético de contrastes teológicos (Hebreo y Griego)
"""

import json
import os
import re
import sqlite3
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "data" / "logos_k_logos.db"
CACHE_PATH = ROOT / "tools" / "strong_cache.sqlite"

# Contrastes teológicos canónicos de alto valor exegético
THEOLOGICAL_STUDIES = [
    # HEBREO
    {
        "language": "hebrew",
        "codes": [776, 127, 8398],
        "note": "⚖️ Distinción del concepto 'Tierra':\n• #H776 (érets): Tierra en sentido geopolítico, nacional o territorial soberano (la tierra prometida, las tierras de las naciones).\n• #H127 (adamáh): El suelo físico arable, la tierra fértil de cultivo y la materia prima de donde Yahvé formó al ser humano (#H120).\n• #H8398 (tebél): El orbe cósmico habitable en su totalidad, el mundo fructífero sustentado por la providencia divina."
    },
    {
        "language": "hebrew",
        "codes": [1254, 6213, 3335],
        "note": "⚖️ Distinción de la obra creadora divina:\n• #H1254 (bará): Crear de la nada (ex nihilo). Acto soberano y fundacional atribuido en las Escrituras exclusivamente a Dios.\n• #H6213 (asáh): Hacer, fabricar o ensamblar utilizando elementos o materia preexistente.\n• #H3335 (yatsár): Modelar, moldear y esculpir con detalle artístico y propósito personal (como el alfarero sobre el barro)."
    },
    {
        "language": "hebrew",
        "codes": [2617, 7356, 2580],
        "note": "⚖️ Las dimensiones de la Gracia y Misericordia:\n• #H2617 (jésed): Amor leal, fidelidad incondicional emanada del pacto eterno; misericordia inquebrantable de Dios hacia su pueblo.\n• #H7356 (rájam): Compasión profunda y entrañable (derivada de la raíz de matriz materna), piedad visceral ante la fragilidad del necesitado.\n• #H2580 (jen): Gracia soberana, favor benevolente inmerecido hallado a los ojos de un superior."
    },
    {
        "language": "hebrew",
        "codes": [5315, 7307, 3820],
        "note": "⚖️ Antropología Bíblica Hebrea:\n• #H5315 (néfesh): El alma viviente, el individuo en su totalidad orgánica que respira, siente apetitos, afectos y deseos.\n• #H7307 (rúaj): El espíritu, el aliento divino invisible comunicado por el Creador que confiere vida, discernimiento y fuerza espiritual.\n• #H3820 (lev / leváv): El corazón como centro unificado de la voluntad deliberada, la mente racional y la decisión moral del ser humano."
    },
    {
        "language": "hebrew",
        "codes": [120, 376, 1397, 582],
        "note": "⚖️ Vocabulario para el Hombre en el Antiguo Testamento:\n• #H120 (adám): La humanidad en general, el linaje humano salido del polvo terrenal (#H127).\n• #H376 (ish): El individuo masculino específico, el varón en distinción a la mujer (#H802 isháh).\n• #H1397 (guéber): El varón fuerte, esforzado, con capacidad combativa y vigor físico.\n• #H582 (enósh): El hombre en su fragilidad mortal, debilidad intrínseca e impermanencia terrenal."
    },
    {
        "language": "hebrew",
        "codes": [2403, 5771, 6588],
        "note": "⚖️ La Anatomía del Pecado en el AT:\n• #H2403 (jattá): Pecado como errar el blanco, desviarse del camino trazado por Dios.\n• #H5771 (avón): Iniquidad, perversión interior, culpa moral que corrompe la rectitud del corazón.\n• #H6588 (pésha): Rebelión deliberada, desacato consciente y transgresión voluntaria contra la soberanía divina."
    },
    {
        "language": "hebrew",
        "codes": [7965, 7999],
        "note": "⚖️ Plenitud y Restauración del Pacto:\n• #H7965 (shalóm): Paz integral, armonía, bienestar relacional completo con Dios, los semejantes y la creación.\n• #H7999 (shalám): Completar, compensar, restituir lo adeudado y llevar a su cabal terminación una alianza."
    },

    # GRIEGO
    {
        "language": "greek",
        "codes": [25, 26, 5368, 5373, 4694],
        "note": "⚖️ Las Cuatro Dimensiones del Amor en el NT:\n• #G25 (agapáo) / #G26 (agápē): El amor supremo de pacto y abnegación sacrificial, de origen divino, fundamentado en la voluntad y la cruz; busca el bien del otro sin exigir reciprocidad.\n• #G5368 (philéo) / #G5373 (philía): El afecto entrañable, cariño fraternal cálido y recíproco compartido entre amigos y hermanos en la fe.\n• #G4694 (storgē): El afecto biológico natural y filial que une a los miembros de una familia de sangre."
    },
    {
        "language": "greek",
        "codes": [3056, 4487],
        "note": "⚖️ La Palabra Divina:\n• #G3056 (lógos): El Verbo divino increado (Jn 1:1), la revelación cósmica total y sustancial de la mente de Dios, el pensamiento encarnado.\n• #G4487 (rhēma): La declaración viva, el dicho o palabra hablada de forma específica, proclamada y aplicada por el Espíritu Santo en un momento concreto de la experiencia."
    },
    {
        "language": "greek",
        "codes": [2222, 2198, 979, 5590],
        "note": "⚖️ Las Categorías Bíblicas de la Vida:\n• #G2222 (zōē) / #G2198 (zaō): La vida increada, eterna y divina en Cristo; la vida indestructible que trasciende el sepulcro.\n• #G979 (bíos): La existencia física terrenal, el ciclo biológico temporal y los medios materiales de sustento diario.\n• #G5590 (psychē): La vida del alma humana, el centro individual de la personalidad consciente, intelecto y emociones."
    },
    {
        "language": "greek",
        "codes": [4151, 5590, 4561],
        "note": "⚖️ Antropología Paulina y Neotestamentaria:\n• #G4151 (pneuma): El espíritu humano renovado, órgano mediante el cual el creyente adora y se comunica en íntima comunión con el Espíritu Santo.\n• #G5590 (psychē): El alma, sede de las funciones volitivas, afectivas y psicológicas de la persona.\n• #G4561 (sarx): La carne en sentido biológico o la debilidad moral heredada propensa a actuar con independencia de Dios."
    },
    {
        "language": "greek",
        "codes": [1484, 2992, 1218],
        "note": "⚖️ Comunidades Humanas en el NT:\n• #G1484 (ethnos): Las naciones gentiles paganas fuera del pacto mosaico; los pueblos étnicos de la tierra.\n• #G2992 (laos): El pueblo elegido y constituido en pacto sacerdotal para la gloria de Dios (la Iglesia o Israel).\n• #G1218 (dēmos): La ciudadanía política reunida en asamblea pública popular de una polis griega o romana."
    },
    {
        "language": "greek",
        "codes": [266, 3847, 458],
        "note": "⚖️ Clasificación Neotestamentaria del Pecado:\n• #G266 (hamartía): Pecar como errar el blanco perfecto establecido por la santidad divina.\n• #G3847 (parábasis): Transgresión, dar un paso adelante atravesando conscientemente la línea trazada por la ley revelada.\n• #G458 (anomía): Iniquidad, espíritu de anarquía y rebeldía sistemática que rechaza toda norma o señorío divino."
    },
    {
        "language": "greek",
        "codes": [4678, 5428, 1108],
        "note": "⚖️ Las Facultades de la Sabiduría Espiritual:\n• #G4678 (sophía): La sabiduría suprema para comprender los misterios y designios eternos de Dios según su beneplácito.\n• #G5428 (phrónēsis): La prudencia práctica, el buen juicio espiritual para aplicar los principios de la Palabra en la conducta diaria.\n• #G1108 (gnōsis): El conocimiento objetivo de las verdades reveladas."
    },
]

def add_columns_if_missing(cur):
    cur.execute("PRAGMA table_info(strong_entries)")
    cols = {r[1] for r in cur.fetchall()}
    for col, ctype in [("similarities", "TEXT"), ("compare_codes", "TEXT"), ("derived_codes", "TEXT")]:
        if col not in cols:
            print(f"[SCHEMA] Agregando columna '{col}' a strong_entries...")
            cur.execute(f"ALTER TABLE strong_entries ADD COLUMN {col} {ctype} DEFAULT ''")

def create_relations_table(cur):
    cur.execute("""
    CREATE TABLE IF NOT EXISTS strong_relations (
        source_language TEXT NOT NULL,
        source_code INTEGER NOT NULL,
        target_code INTEGER NOT NULL,
        relation_type TEXT NOT NULL, -- 'derives_from', 'parent_of', 'compares_with', 'synonym'
        PRIMARY KEY(source_language, source_code, target_code, relation_type)
    );
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_relations_source ON strong_relations(source_language, source_code);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_relations_target ON strong_relations(source_language, target_code);")

def extract_relations_from_cache(c_cur):
    c_cur.execute("""
    SELECT language, code, derivation, derivation_html, kjv_def, kjv_def_html
    FROM strong_cache
    """)
    rows = c_cur.fetchall()

    relations = set()

    for lang, code, deriv, deriv_html, kjv, kjv_html in rows:
        d_html = deriv_html or ""
        k_html = kjv_html or ""
        d_txt = deriv or ""
        k_txt = kjv or ""

        # 1. Derivaciones desde HTML (enlaces exactos)
        if lang == "greek":
            targets = [int(m) for m in re.findall(r'/strongcodes/(\d+)', d_html)]
        else:
            targets = [int(m) for m in re.findall(r'/strong_hebrew/(\d+)', d_html)]

        # Fallback a texto plano si no hubo HTML: "de 3004", "de lo mismo que 7218"
        if not targets:
            text_matches = re.findall(r'\bde\s+(?:lo\s+mismo\s+que\s+)?(\d{1,5})\b', d_txt, re.IGNORECASE)
            for tm in text_matches:
                t_code = int(tm)
                if t_code != code and 1 <= t_code <= 8674:
                    targets.append(t_code)

        for target in targets:
            if target != code:
                # Código actual deriva de target
                relations.add((lang, code, target, 'derives_from'))
                # target es raíz/padre de código actual (Familia de palabras)
                relations.add((lang, target, code, 'parent_of'))

        # 2. Comparaciones desde kjv_def_html o kjv_def ("comparar 5368")
        comp_targets = [int(m) for m in re.findall(r'/strongcodes/(\d+)', k_html)] if lang == "greek" else [int(m) for m in re.findall(r'/strong_hebrew/(\d+)', k_html)]
        comp_text = re.findall(r'comparar\s+(\d{1,5})', f"{k_txt} {d_txt}", re.IGNORECASE)
        for ct in comp_text:
            c_code = int(ct)
            if c_code != code and 1 <= c_code <= 8674:
                comp_targets.append(c_code)

        for c_target in set(comp_targets):
            if c_target != code:
                relations.add((lang, code, c_target, 'compares_with'))
                relations.add((lang, c_target, code, 'compares_with'))

    return relations

def main():
    if not DB_PATH.exists():
        print(f"[ERROR] No existe {DB_PATH}")
        sys.exit(1)

    print(f"[INFO] Abriendo base de datos {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    add_columns_if_missing(cur)
    create_relations_table(cur)

    # Limpiar tabla de relaciones previa para carga limpia
    cur.execute("DELETE FROM strong_relations")

    relations = set()

    # Si la caché existe, extraer relaciones de ella
    if CACHE_PATH.exists():
        print(f"[INFO] Extrayendo relaciones léxicas desde la caché {CACHE_PATH}...")
        c_conn = sqlite3.connect(CACHE_PATH)
        c_cur = c_conn.cursor()
        extracted = extract_relations_from_cache(c_cur)
        relations.update(extracted)
        c_conn.close()
        print(f"[INFO] Relaciones etimológicas y léxicas extraídas: {len(extracted)}")

    # Inyectar contrastes teológicos de alta calidad
    print(f"[INFO] Inyectando {len(THEOLOGICAL_STUDIES)} estudios teológicos comparativos...")
    for study in THEOLOGICAL_STUDIES:
        lang = study["language"]
        codes = study["codes"]
        note = study["note"]

        for i, c1 in enumerate(codes):
            # Asignar nota a cada palabra del estudio
            cur.execute("""
            UPDATE strong_entries 
            SET similarities = ?
            WHERE language = ? AND code = ?
            """, (note, lang, c1))

            # Interconectar todas las palabras entre sí
            for j, c2 in enumerate(codes):
                if c1 != c2:
                    relations.add((lang, c1, c2, 'compares_with'))
                    relations.add((lang, c1, c2, 'synonym'))

    print(f"[INFO] Insertando {len(relations)} relaciones en strong_relations...")
    cur.executemany("""
    INSERT OR REPLACE INTO strong_relations (source_language, source_code, target_code, relation_type)
    VALUES (?, ?, ?, ?)
    """, list(relations))

    # Ahora agregamos compare_codes y derived_codes en strong_entries para ultra-rápida lectura
    print("[INFO] Computando y agregando 'compare_codes' y 'derived_codes' en strong_entries...")
    cur.execute("""
    SELECT source_language, source_code, relation_type, target_code
    FROM strong_relations
    """)
    rel_rows = cur.fetchall()

    compares_by_entry = {}
    derived_by_entry = {}

    for lang, src, rel_type, tgt in rel_rows:
        key = (lang, src)
        if rel_type in ('compares_with', 'synonym'):
            compares_by_entry.setdefault(key, set()).add(tgt)
        elif rel_type == 'parent_of':
            derived_by_entry.setdefault(key, set()).add(tgt)

    update_tuples = []
    cur.execute("SELECT language, code FROM strong_entries")
    all_entries = cur.fetchall()

    for lang, code in all_entries:
        key = (lang, code)
        comp_str = ",".join(str(c) for c in sorted(compares_by_entry.get(key, [])))
        deriv_str = ",".join(str(c) for c in sorted(derived_by_entry.get(key, [])))
        if comp_str or deriv_str:
            update_tuples.append((comp_str, deriv_str, lang, code))

    cur.executemany("""
    UPDATE strong_entries
    SET compare_codes = ?, derived_codes = ?
    WHERE language = ? AND code = ?
    """, update_tuples)

    conn.commit()

    # Estadísticas finales
    cur.execute("SELECT COUNT(*) FROM strong_relations")
    total_rel = cur.fetchone()[0]
    cur.execute("SELECT relation_type, COUNT(*) FROM strong_relations GROUP BY relation_type")
    type_counts = cur.fetchall()
    cur.execute("SELECT COUNT(*) FROM strong_entries WHERE length(similarities) > 0")
    total_sim = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM strong_entries WHERE length(derived_codes) > 0")
    total_deriv_fam = cur.fetchone()[0]

    print("\n================ ESTADÍSTICAS V1.3.7 ================")
    print(f"Total registros en strong_relations: {total_rel}")
    for t, c in type_counts:
        print(f"  • {t:15s}: {c}")
    print(f"Entradas con estudio de Similitud:    {total_sim}")
    print(f"Entradas con Familia Derivada:        {total_deriv_fam}")

    # Muestra de verificación
    print("\n================ VERIFICACIÓN EXEGÉTICA ================")
    cur.execute("""
    SELECT s.code, s.lemma, s.pronunciation, s.similarities, s.compare_codes, s.derived_codes
    FROM strong_entries s
    WHERE s.language = 'hebrew' AND s.code = 776
    """)
    h776 = cur.fetchone()
    if h776:
        print(f"\n[#H{h776[0]} {h776[1]} ({h776[2]})]")
        print(f"  Códigos comparados: {h776[4]}")
        print(f"  Familia derivada:   {h776[5][:80]}...")
        print(f"  Estudio similitud:\n{h776[3]}")

    cur.execute("""
    SELECT s.code, s.lemma, s.pronunciation, s.similarities, s.compare_codes, s.derived_codes
    FROM strong_entries s
    WHERE s.language = 'greek' AND s.code = 25
    """)
    g25 = cur.fetchone()
    if g25:
        print(f"\n[#G{g25[0]} {g25[1]} ({g25[2]})]")
        print(f"  Códigos comparados: {g25[4]}")
        print(f"  Familia derivada:   {g25[5][:80]}...")
        print(f"  Estudio similitud:\n{g25[3]}")

    conn.close()
    print("\n[ÉXITO] Actualización v1.3.7 finalizada con éxito.")

if __name__ == "__main__":
    main()
