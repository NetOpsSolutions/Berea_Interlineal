#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
harvest_and_populate_strong.py
Extracción concurrente de alta velocidad y poblado integral de:
- Derivaciones y Etimologías
- Léxico Académico Extendido (STEPBible / Tyndale)
- Relaciones léxicas (Deriva de, Es raíz de, Comparar con)
- Similitudes y contrastes teológicos
Para las 8.674 palabras en Hebreo y 5.523 palabras en Griego de logos_k_logos.db.
"""

import json
import os
import re
import sqlite3
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from bs4 import BeautifulSoup
import requests

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "data" / "logos_k_logos.db"
CACHE_DB_PATH = ROOT / "tools" / "strong_cache.sqlite"

thread_local = threading.local()

def get_session():
    if not hasattr(thread_local, "session"):
        s = requests.Session()
        s.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "es-ES,es;q=0.9,en;q=0.8",
        })
        adapter = requests.adapters.HTTPAdapter(pool_connections=20, pool_maxsize=20, max_retries=3)
        s.mount("https://", adapter)
        thread_local.session = s
    return thread_local.session

def init_cache():
    conn = sqlite3.connect(CACHE_DB_PATH)
    cur = conn.cursor()
    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("""
    CREATE TABLE IF NOT EXISTS strong_cache (
        language TEXT NOT NULL,
        code INTEGER NOT NULL,
        lemma TEXT,
        pronunciation TEXT,
        derivation TEXT,
        derivation_html TEXT,
        definition TEXT,
        kjv_def TEXT,
        kjv_def_html TEXT,
        step_gloss TEXT,
        step_definition TEXT,
        PRIMARY KEY (language, code)
    );
    """)
    conn.commit()
    conn.close()

def get_cached_keys():
    init_cache()
    conn = sqlite3.connect(CACHE_DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT language, code FROM strong_cache")
    cached = set(cur.fetchall())
    conn.close()
    return cached

def save_batch_to_cache(batch):
    if not batch:
        return
    conn = sqlite3.connect(CACHE_DB_PATH, timeout=30)
    cur = conn.cursor()
    cur.executemany("""
    INSERT OR REPLACE INTO strong_cache (
        language, code, lemma, pronunciation, derivation, derivation_html,
        definition, kjv_def, kjv_def_html, step_gloss, step_definition
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, batch)
    conn.commit()
    conn.close()

def fetch_entry(language, code):
    url = f"https://logosklogos.com/strong_hebrew/{code}" if language == "hebrew" else f"https://logosklogos.com/strongcodes/{code}"
    s = get_session()
    for attempt in range(3):
        try:
            r = s.get(url, timeout=12)
            if r.status_code == 404:
                return (language, code, None)
            if r.status_code != 200:
                time.sleep(0.5 * (attempt + 1))
                continue
            soup = BeautifulSoup(r.text, "html.parser")
            tag = soup.find("script", id="__NEO_STATE__")
            if not tag or not tag.string:
                return (language, code, None)
            data = json.loads(tag.string)
            key = "strongHebrew" if language == "hebrew" else "strongGreek"
            entry = data.get("data", {}).get(key, {}).get("entry")
            if not entry:
                return (language, code, None)
            return (language, code, entry)
        except Exception:
            time.sleep(0.5 * (attempt + 1))
    return (language, code, None)

def crawl_missing_entries(max_workers=35):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT language, code FROM strong_entries ORDER BY language, code")
    all_targets = cur.fetchall()
    conn.close()

    cached = get_cached_keys()
    missing = [t for t in all_targets if t not in cached]
    print(f"[HARVEST] Total objetivos en DB: {len(all_targets)} | Ya en caché: {len(cached)} | Pendientes por descargar: {len(missing)}")

    if not missing:
        print("[HARVEST] Todos los términos ya se encuentran en la caché local.")
        return

    batch = []
    lock = threading.Lock()
    done_count = 0
    total_missing = len(missing)
    t0 = time.time()

    with ThreadPoolExecutor(max_workers=max_workers) as ex:
        futures = {ex.submit(fetch_entry, lang, code): (lang, code) for (lang, code) in missing}
        for fut in as_completed(futures):
            lang, code = futures[fut]
            try:
                res_lang, res_code, entry = fut.result()
            except Exception as e:
                res_lang, res_code, entry = lang, code, None

            row = (
                lang,
                code,
                entry.get("word", "") if entry else "",
                entry.get("transliteral", "") if entry else "",
                entry.get("derivation", "") if entry else "",
                entry.get("derivationHtml", "") if entry else "",
                entry.get("definition", "") if entry else "",
                entry.get("kjvDef", "") if entry else "",
                entry.get("kjvDefHtml", "") if entry else "",
                entry.get("stepGloss", "") if entry else "",
                entry.get("stepDefinition", "") if entry else "",
            )

            with lock:
                batch.append(row)
                done_count += 1
                if len(batch) >= 100:
                    save_batch_to_cache(batch)
                    batch.clear()

                if done_count % 250 == 0 or done_count == total_missing:
                    elapsed = time.time() - t0
                    speed = done_count / elapsed if elapsed > 0 else 0
                    remain = (total_missing - done_count) / speed if speed > 0 else 0
                    print(f"  -> Progreso: {done_count}/{total_missing} ({done_count/total_missing*100:.1f}%) | "
                          f"Velocidad: {speed:.1f} req/s | Restante: {remain/60:.1f} min")

    with lock:
        if batch:
            save_batch_to_cache(batch)
            batch.clear()

    elapsed = time.time() - t0
    print(f"[HARVEST] Descarga completada: {total_missing} procesados en {elapsed:.1f}s ({total_missing/elapsed:.1f} req/s).")

if __name__ == "__main__":
    crawl_missing_entries(max_workers=40)
