import json
import sqlite3
from pathlib import Path

DB_PATH = Path("logos_k_logos.db")
DATA_DIR = Path("data/output")

SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS books (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  testament INTEGER NOT NULL,
  chapters INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  translation TEXT NOT NULL,
  UNIQUE(book_id, chapter, verse)
);

CREATE TABLE IF NOT EXISTS words (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL,
  position INTEGER NOT NULL,
  strong_code INTEGER,
  language TEXT NOT NULL,
  lemma TEXT NOT NULL,
  surface TEXT NOT NULL,
  parsing TEXT NOT NULL,
  translation TEXT NOT NULL,
  FOREIGN KEY(verse_id) REFERENCES verses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS strong_entries (
  language TEXT NOT NULL,
  code INTEGER NOT NULL,
  lemma TEXT NOT NULL,
  pronunciation TEXT,
  derivation TEXT,
  definition TEXT,
  rv_definition TEXT,
  stepbible TEXT,
  PRIMARY KEY(language, code)
);

CREATE TABLE IF NOT EXISTS occurrences (
  language TEXT NOT NULL,
  strong_code INTEGER NOT NULL,
  book_id TEXT NOT NULL,
  verses INTEGER NOT NULL DEFAULT 0,
  occurrences INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(language, strong_code, book_id)
);
"""


def read_jsonl(path: Path):
    if not path.exists():
        return
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)


def import_strong(conn: sqlite3.Connection):
    cur = conn.cursor()

    for lang, filename in [
        ("greek", "strong_greek.jsonl"),
        ("hebrew", "strong_hebrew.jsonl"),
    ]:
        for item in read_jsonl(DATA_DIR / filename):
            cur.execute("""
                INSERT INTO strong_entries (
                    language, code, lemma, pronunciation,
                    derivation, definition, rv_definition, stepbible
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(language, code) DO UPDATE SET
                    lemma=excluded.lemma,
                    pronunciation=excluded.pronunciation,
                    derivation=excluded.derivation,
                    definition=excluded.definition,
                    rv_definition=excluded.rv_definition,
                    stepbible=excluded.stepbible
            """, (
                item["language"],
                item["code"],
                item["lemma"],
                item.get("pronunciation", ""),
                item.get("derivation", ""),
                item.get("definition", ""),
                item.get("rv_definition", ""),
                item.get("stepbible", "")
            ))

    conn.commit()


def import_bible(conn: sqlite3.Connection):
    cur = conn.cursor()

    verse_ids = {}

    for verse in read_jsonl(DATA_DIR / "verses.jsonl"):
        cur.execute("""
            INSERT INTO verses (book_id, chapter, verse, translation)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(book_id, chapter, verse) DO UPDATE SET
                translation=excluded.translation
        """, (
            verse["book"],
            verse["chapter"],
            verse["verse"],
            verse.get("translation", "")
        ))

        verse_id = cur.lastrowid
        if verse_id is None:
            cur.execute("""
                SELECT id FROM verses
                WHERE book_id=? AND chapter=? AND verse=?
            """, (verse["book"], verse["chapter"], verse["verse"]))
            verse_id = cur.fetchone()[0]

        verse_ids[(verse["book"], verse["chapter"], verse["verse"])] = verse_id

    for word in read_jsonl(DATA_DIR / "words.jsonl"):
        key = (word["book"], word["chapter"], word["verse"])
        verse_id = verse_ids.get(key)
        if not verse_id:
            continue

        cur.execute("""
            INSERT INTO words (
                verse_id, position, strong_code, language,
                lemma, surface, parsing, translation
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            verse_id,
            word["position"],
            word.get("strong_code"),
            word["language"],
            word["lemma"],
            word["surface"],
            word["parsing"],
            word["translation"]
        ))

    conn.commit()


def main():
    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)

    import_strong(conn)
    import_bible(conn)

    conn.execute("""
        INSERT OR REPLACE INTO meta (key, value)
        VALUES ('full_dataset_imported', '1')
    """)
    conn.commit()
    conn.close()

    print(f"Base creada en {DB_PATH.resolve()}")


if __name__ == "__main__":
    main()
