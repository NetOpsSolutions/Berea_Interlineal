"""
Diagnostico v5: inspecciona UNA pagina y dice que parser aplica.
 - interlineal  -> tabla (5 col) + traduccion (linea anterior a 'Interlineal de')
 - diccionario  -> layout posicional 'lemma - Strong NNNN'
Uso:
  python -X utf8 tools/diag_page.py https://logosklogos.com/AT/Gn/1/1
  python -X utf8 tools/diag_page.py https://logosklogos.com/NT/Jn/1/1
  python -X utf8 tools/diag_page.py https://logosklogos.com/strongcodes/3056
  python -X utf8 tools/diag_page.py https://logosklogos.com/strong_hebrew/3068
"""
import sys
from pathlib import Path

import requests
from bs4 import BeautifulSoup

from crawl_logosklogos import (parse_table_words, parse_translation,
                               parse_strong, parse_occurrences, text_lines)

URL = sys.argv[1] if len(sys.argv) > 1 else "https://logosklogos.com/AT/Gn/1/1"

r = requests.get(URL, headers={"User-Agent": "LogosKLogosDiag/5.0"}, timeout=60)
print("HTTP", r.status_code, "len(html) =", len(r.text))
soup = BeautifulSoup(r.text, "html.parser")

is_strong = ("/strong" in URL.lower())

if is_strong:
    lang = "hebrew" if "hebrew" in URL.lower() else "greek"
    e = parse_strong(soup, lang)
    print("== DICCIONARIA ==")
    print("entry:", e)
    print("ocurrencias (sitio, residual):", len(parse_occurrences(soup, lang)))
else:
    words = parse_table_words(soup)
    trans = parse_translation(soup)
    print("== INTERLINEAL ==")
    print("palabras encontradas:", len(words))
    for w in words[:14]:
        print("  ", w)
    print("traduccion:", repr(trans))

print("---- lineas de bloque (primeras 30) ----")
for l in text_lines(soup)[:30]:
    print(repr(l))

dbg = Path("data/debug")
dbg.mkdir(parents=True, exist_ok=True)
slug = "_".join(URL.rstrip("/").split("/")[-3:]) or "page"
(dbg / f"{slug}_raw.html").write_text(r.text, encoding="utf-8")
(dbg / f"{slug}_lines.txt").write_text("\n".join(text_lines(soup)), encoding="utf-8")
print("Debug guardado en:", dbg.resolve())
