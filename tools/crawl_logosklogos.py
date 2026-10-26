"""
Crawler v7 de logosklogos.com (rapido, concurrenTE, sin perder datos).
 - Interlineal = TABLA HTML (Texto original | Lema | Traduccion | Strong | Morfologia).
 - Morfologia en espanol -> campo "parsing" tal cual.
 - Diccionario = layout posicional 'lemma - Strong NNNN'.
 - 'Donde aparece' se DERIVA luego en build_assets (el sitio ya no la publica).
SOLO usar si el sitio es tuyo o tienes permiso explicito.

Salida (en --out):
  interlinear_at.jsonl   atomos AT   {book,chapter,verse,translation,language,words:[...]}
  interlinear_nt.jsonl   atomos NT   idem
  strong_greek.jsonl     {language,code,lemma,pronunciation,derivation,definition,rv_definition,stepbible}
  strong_hebrew.jsonl    idem
  occurrences.jsonl      residual (la concordancia real la deriva build_assets)

Ejemplos:
  # una sola ventana, 6 hilos
  python -X utf8 tools/crawl_logosklogos.py --out data/output --workers 6 --delay 0.5

  # cuatro ventanas en paralelo (maximo throughput, sin colision):
  #   T1: --only bible --testament 1 --workers 3 --delay 0.6
  #   T2: --only bible --testament 2 --workers 3 --delay 0.6
  #   T3: --only greek  --workers 3 --delay 0.6
  #   T4: --only hebrew --workers 3 --delay 0.6
"""
import argparse
import json
import random
import re
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib import robotparser

import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter

BASE = "https://logosklogos.com"
UA = "LogosKLogosDev/7.0 (authorized research bot)"

AT_BOOKS = ["Gn","Ex","Lv","Nm","Dt","Jos","Jue","Rt","1S","2S","1R","2R","1Cr","2Cr",
            "Esd","Neh","Est","Job","Sal","Pr","Ec","Cnt","Is","Jer","Lm","Ez","Dn",
            "Os","Jl","Am","Abd","Jon","Mi","Nah","Hab","Sof","Ha","Zac","Mal"]
NT_BOOKS = ["Mt","Mr","Lc","Jn","Hch","Ro","1Co","2Co","Ga","Ef","Fil","Col","1Ts","2Ts",
            "1Ti","2Ti","Tit","Flm","He","Stg","1P","2P","1Jn","2Jn","3Jn","Jud","Ap"]
CHAPTERS = {"Gn":50,"Ex":40,"Lv":27,"Nm":36,"Dt":34,"Jos":24,"Jue":21,"Rt":4,"1S":31,"2S":24,
    "1R":22,"2R":25,"1Cr":29,"2Cr":36,"Esd":10,"Neh":13,"Est":10,"Job":42,"Sal":150,"Pr":31,
    "Ec":12,"Cnt":8,"Is":66,"Jer":52,"Lm":5,"Ez":48,"Dn":12,"Os":14,"Jl":3,"Am":9,"Abd":1,
    "Jon":4,"Mi":7,"Nah":3,"Hab":3,"Sof":3,"Ha":1,"Zac":14,"Mal":4,
    "Mt":28,"Mr":16,"Lc":24,"Jn":21,"Hch":28,"Ro":16,"1Co":16,"2Co":13,"Ga":6,"Ef":6,
    "Fil":4,"Col":4,"1Ts":5,"2Ts":3,"1Ti":6,"2Ti":4,"Tit":3,"Flm":1,"He":13,"Stg":5,
    "1P":5,"2P":3,"1Jn":5,"2Jn":1,"3Jn":1,"Jud":1,"Ap":22}

BOOK_NAME_TO_ID = {
 "Génesis":"Gn","Éxodo":"Ex","Levítico":"Lv","Números":"Nm","Deuteronomio":"Dt","Josué":"Jos",
 "Jueces":"Jue","Rut":"Rt","1ra Samuel":"1S","2da Samuel":"2S","1ra Reyes":"1R","2da Reyes":"2R",
 "1ra Crónicas":"1Cr","2da Crónicas":"2Cr","Esdras":"Esd","Nehemías":"Neh","Ester":"Est","Job":"Job",
 "Salmos":"Sal","Proverbios":"Pr","Eclesiastés":"Ec","Cantares":"Cnt","Isaías":"Is","Jeremías":"Jer",
 "Lamentaciones":"Lm","Ezequiel":"Ez","Daniel":"Dn","Oseas":"Os","Joel":"Jl","Amós":"Am",
 "Abdías":"Abd","Jonás":"Jon","Miqueas":"Mi","Nahúm":"Nah","Habacuc":"Hab","Sofonías":"Sof",
 "Hageo":"Ha","Zacarías":"Zac","Malaquías":"Mal","Mateo":"Mt","Marcos":"Mr","Lucas":"Lc","Juan":"Jn",
 "Hechos":"Hch","Romanos":"Ro","1ra Corintios":"1Co","2da Corintios":"2Co","Gálatas":"Ga","Efesios":"Ef",
 "Filipenses":"Fil","Colosenses":"Col","1ra Tesalonicenses":"1Ts","2da Tesalonicenses":"2Ts",
 "1ra Timoteo":"1Ti","2da Timoteo":"2Ti","Tito":"Tit","Filemón":"Flm","Hebreos":"He","Santiago":"Stg",
 "1ra Pedro":"1P","2da Pedro":"2P","1ra Juan":"1Jn","2da Juan":"2Jn","3ra Juan":"3Jn","Judas":"Jud",
 "Apocalipsis":"Ap"}

_NAV_PREFIX = (
    "LogosKLogos:", "Inicio", "Nuevo Testamento", "Antiguo Testamento",
    "Diccionario Strong", "Acerca de", "Atajos de", "Calendario de",
    "Declaración de", "Los libros", "Links útiles", "Política de",
    "Strong griego página", "Strong hebreo página", "Siguiente:", "Anterior:",
    "Interlineal de", "Texto original", "Lema", "Traducción", "Strong", "Morfología",
)
_BREADCRUMB_RE = re.compile(r"^\d{1,5}\s+\S.{0,40}$")
_TITLE_RE = re.compile(r"^(.*?)\s*[—\-–]\s*Strong\s*[:#]?\s*(\d{1,5})\s*$")
_BREADCRUMB_STRONG_RE = re.compile(r"Strong\s*[:#]\s*(\d{1,5})\s+(.*)$")


def _is_nav(line):
    s = line.strip()
    if not s or s.startswith(_NAV_PREFIX):
        return True
    if _BREADCRUMB_RE.match(s) and len(s) < 40:
        return True
    return False


def text_lines(soup):
    return [l.strip() for l in soup.get_text("\n").splitlines() if l.strip()]


# --------------------------------------------------------------------------- PARSE
def parse_table_words(soup):
    words = []
    for table in soup.find_all("table"):
        cand = []
        for tr in table.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) != 5:
                continue
            surface = tds[0].get_text(" ", strip=True)
            lemma = tds[1].get_text(" ", strip=True)
            translation = tds[2].get_text(" ", strip=True)
            strong = tds[3].get_text(" ", strip=True)
            morph = tds[4].get_text(" ", strip=True)
            if not re.fullmatch(r"\d{1,5}", strong):
                continue
            cand.append({"strong_code": int(strong), "lemma": lemma, "surface": surface,
                         "parsing": morph, "translation": translation})
        if cand:
            words = cand
            break
    for pos, w in enumerate(words, start=1):
        w["position"] = pos
    return words


def parse_translation(soup):
    lines = text_lines(soup)
    for i, l in enumerate(lines):
        if l.startswith("Interlineal de") and i > 0:
            prev = lines[i - 1]
            if len(prev) >= 12 and not _is_nav(prev):
                return prev
    for i, l in enumerate(lines):
        if re.match(r"^.+\s\d+:\d+$", l) and i + 1 < len(lines):
            nxt = lines[i + 1]
            if len(nxt) >= 12 and not _is_nav(nxt):
                return nxt
    return ""


def parse_strong(soup, language):
    lines = text_lines(soup)
    e = {"language": language, "code": None, "lemma": "", "pronunciation": "",
         "derivation": "", "definition": "", "rv_definition": "", "stepbible": ""}
    if not lines:
        return None
    title_idx = None
    for i in range(min(6, len(lines))):
        m = _TITLE_RE.match(lines[i])
        if m:
            title_idx = i
            e["lemma"] = m.group(1).strip()
            e["code"] = int(m.group(2))
            break
    if title_idx is None:
        m = _BREADCRUMB_STRONG_RE.search(lines[0])
        if m:
            title_idx = 0
            e["code"] = int(m.group(1))
            e["lemma"] = m.group(2).strip()
    if e["code"] is None:
        return None
    after = [lines[k] for k in range(title_idx + 1, min(title_idx + 9, len(lines)))
             if not _is_nav(lines[k])]
    e["pronunciation"] = after[0] if len(after) > 0 else ""
    e["definition"] = after[1] if len(after) > 1 else ""
    e["rv_definition"] = after[2] if len(after) > 2 else ""
    for i, l in enumerate(lines):
        nxt = lines[i + 1] if i + 1 < len(lines) else ""
        if l.startswith("Léxico STEPBible"):
            e["stepbible"] = nxt
        elif l == "Derivación":
            e["derivation"] = nxt
    return e


def parse_occurrences(soup, language):
    lines = text_lines(soup)
    occ = []
    started = False
    for l in lines:
        if l.startswith("Aparece en"):
            started = True
            continue
        if not started:
            continue
        if _is_nav(l):
            break
        m = re.match(r"^(.+?)(\d+)\s*vers[íi]culos?(?:\s*\((\d+)\s*veces?\))?\s*$", l)
        if not m:
            continue
        bid = BOOK_NAME_TO_ID.get(m.group(1).strip())
        if bid:
            occ.append({"language": language, "book_id": bid,
                        "verses": int(m.group(2)), "occurrences": int(m.group(3) or 0)})
    return occ


# --------------------------------------------------------------------------- RED
class Crawler:
    def __init__(self, delay, workers, connect_timeout, read_timeout, retries, out):
        self.delay = delay
        self.workers = max(1, workers)
        self.connect_timeout = connect_timeout
        self.read_timeout = read_timeout
        self.retries = retries
        self.out = Path(out)
        self.out.mkdir(parents=True, exist_ok=True)
        self.last_status = None

        self.s = requests.Session()
        self.s.headers.update({"User-Agent": UA, "Accept-Encoding": "gzip, deflate"})
        adapter = HTTPAdapter(pool_connections=self.workers + 2,
                              pool_maxsize=self.workers * 2 + 4, max_retries=0)
        self.s.mount("http://", adapter)
        self.s.mount("https://", adapter)

        self.rp = robotparser.RobotFileParser()
        self.rp.set_url(BASE + "/robots.txt")
        try:
            self.rp.read()
        except Exception:
            pass

        # backoff adaptativo global
        self._lock = threading.Lock()
        self._penalty = 0.0
        # escritura serializada
        self._write_lock = threading.Lock()
        # checkpoint en memoria (protegido)
        self._done_lock = threading.Lock()
        self._done = set()
        # contadores
        self._ok = 0
        self._warn = 0
        self._err = 0

    def allowed(self, url):
        try:
            return self.rp.can_fetch(UA, url)
        except Exception:
            return True

    def _sleep(self):
        with self._lock:
            pen = self._penalty
        time.sleep(self.delay + random.uniform(0, self.delay * 0.5) + pen)

    def _fail(self):
        with self._lock:
            self._penalty = min(self._penalty * 1.6 + 0.4, 8.0)
            self._err += 1

    def _good(self):
        with self._lock:
            self._penalty *= 0.7
            if self._penalty < 0.05:
                self._penalty = 0.0

    def get(self, url):
        self.last_status = None
        if not self.allowed(url):
            print("ROBOTS-BLOCK", url)
            return "blocked"
        for k in range(self.retries):
            self._sleep()
            try:
                r = self.s.get(url, timeout=(self.connect_timeout, self.read_timeout))
                self.last_status = r.status_code
                if r.status_code == 404:
                    self._good()
                    return None  # no-existente (fin de capitulo / hueco real)
                if r.status_code == 429 or r.status_code >= 500:
                    self._fail()
                    time.sleep(min(2 ** k, 20))
                    continue
                r.raise_for_status()
                self._good()
                return r.text
            except requests.exceptions.RequestException:
                self._fail()
                time.sleep(min(2 ** k, 20))
        return "error"  # fallo de red tras reintentos -> ir a cola diferida

    # ---- checkpoint / escritura ----
    def load_done_from(self, paths, keyfn):
        for p in paths:
            p = Path(p)
            if not p.exists():
                continue
            with p.open("r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        self._done.add(keyfn(json.loads(line)))
                    except Exception:
                        pass

    def is_done(self, key):
        with self._done_lock:
            return key in self._done

    def mark_done(self, key):
        with self._done_lock:
            self._done.add(key)

    def write_atom(self, fh, atom):
        with self._write_lock:
            fh.write(json.dumps(atom, ensure_ascii=False) + "\n")
            fh.flush()

    def write_line(self, fh, obj):
        with self._write_lock:
            fh.write(json.dumps(obj, ensure_ascii=False) + "\n")
            fh.flush()

    def bump_ok(self):
        with self._lock:
            self._ok += 1
            return self._ok

    def bump_warn(self):
        with self._lock:
            self._warn += 1


# --------------------------------------------------------------------------- DRIVERS
def _bible_tasks(testament_filter):
    tasks = []
    for testament, prefix, books in [(1, "AT", AT_BOOKS), (2, "NT", NT_BOOKS)]:
        if testament_filter and testament_filter != testament:
            continue
        language = "hebrew" if testament == 1 else "greek"
        for book in books:
            for ch in range(1, CHAPTERS.get(book, 1) + 1):
                tasks.append((prefix, book, ch, language))
    return tasks


def do_chapter(cr, prefix, book, chapter, language):
    """Recorre los versiculos de un capitulo en serie (descubriendo el fin por 404).
    Escribe atomos incrementalemente; salta los ya 'done'. Devuelve True si el
    capitulo completo (llego a 404) o si solo quedo pendiente por red."""
    verse = 1
    cons_err = 0
    completed = False
    while True:
        key = (book, chapter, verse)
        if cr.is_done(key):
            verse += 1
            # no sabemos el fin si saltamos todo; seguimos hasta 404
        url = f"{BASE}/{prefix}/{book}/{chapter}/{verse}"
        html = cr.get(url)
        if html == "blocked":
            return False
        if html is None:  # 404 -> fin natural del capitulo
            completed = True
            break
        if html == "error":
            cons_err += 1
            if cons_err >= 3:
                break  # reencolar capitulo entero (los done parciales se saltaran)
            verse += 1
            continue
        cons_err = 0
        soup = BeautifulSoup(html, "html.parser")
        words = parse_table_words(soup)
        if not words:
            blob = soup.get_text(" ")
            if "Texto original" not in blob and "Interlineal" not in blob:
                completed = True
                break  # verso inexistente -> fin de capitulo
            cr.bump_warn()
            verse += 1
            continue
        translation = parse_translation(soup)
        atom = {"book": book, "chapter": chapter, "verse": verse,
                "translation": translation, "language": language, "words": words}
        with cr._write_lock:
            pass  # el fd se pasa via closure abajo; ver crawl_bible
        # escritura con el handle adecuado (se inyecta en crawl_bible via attr)
        cr._bible_fh[language].write(json.dumps(atom, ensure_ascii=False) + "\n")
        cr._bible_fh[language].flush()
        cr.mark_done(key)
        n = cr.bump_ok()
        if n % 100 == 0:
            print("bible ok", n, "warn", cr._warn, "err", cr._err, book, chapter, verse)
        verse += 1
    return completed


def crawl_bible(cr, workers, testament_filter, max_rounds=2):
    # abre handles por idioma (at=hebrew, nt=greek)
    cr._bible_fh = {
        "hebrew": (cr.out / "interlinear_at.jsonl").open("a", encoding="utf-8"),
        "greek": (cr.out / "interlinear_nt.jsonl").open("a", encoding="utf-8"),
    }
    # carga checkpoint desde TODOS los interlinear*.jsonl (conserva lo de v6)
    cr.load_done_from(sorted(cr.out.glob("interlinear*.jsonl")),
                      lambda d: (d["book"], d["chapter"], d["verse"]))
    print("atomos ya hechos:", len(cr._done))

    pending = _bible_tasks(testament_filter)
    rounds = 0
    while pending and rounds < max_rounds:
        rounds += 1
        if rounds > 1:
            print(f"== ronda de reintentos {rounds}: {len(pending)} capitulos pendientes ==")
        next_pending = []
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futs = {ex.submit(do_chapter, cr, p, b, c, lang): (p, b, c, lang)
                    for (p, b, c, lang) in pending}
            for fut in as_completed(futs):
                p, b, c, lang = futs[fut]
                try:
                    ok = fut.result()
                except Exception as e:
                    print("ERR cap", b, c, e)
                    ok = False
                if not ok:
                    next_pending.append((p, b, c, lang))
        pending = next_pending
    for fh in cr._bible_fh.values():
        fh.close()
    print("FIN bible. ok =", cr._ok, " warn =", cr._warn, " err =", cr._err,
          " capitulos aun pendientes =", len(pending))


def do_strong(cr, path, language, code):
    url = f"{BASE}/{path}/{code}"
    html = cr.get(url)
    if html is None:
        return "skip"  # 404 real: el codigo no existe en el sitio -> no reencolar
    if html in ("blocked", "error"):
        return None    # fallo de red / robots -> reencolar (recuperable)
    soup = BeautifulSoup(html, "html.parser")
    e = parse_strong(soup, language)
    if not e:
        return "skip"  # pagina sin entrada parseable -> no reencolar
    occ = parse_occurrences(soup, language)
    for o in occ:
        o["strong_code"] = code
    with cr._write_lock:
        cr._strong_fh.write(json.dumps(e, ensure_ascii=False) + "\n")
        cr._strong_fh.flush()
        for o in occ:
            cr._occ_fh.write(json.dumps(o, ensure_ascii=False) + "\n")
        cr._occ_fh.flush()
    cr.mark_done(code)
    n = cr.bump_ok()
    if n % 200 == 0:
        print("strong", language, code, "ok", n, "err", cr._err)
    return "ok"


def crawl_strong(cr, workers, language, path, max_code, max_rounds=2):
    cr._strong_fh = (cr.out / f"strong_{language}.jsonl").open("a", encoding="utf-8")
    cr._occ_fh = (cr.out / "occurrences.jsonl").open("a", encoding="utf-8")
    cr._done.clear()
    cr.load_done_from([cr.out / f"strong_{language}.jsonl"], lambda d: d["code"])
    print("strong", language, "ya hechos:", len(cr._done))
    cr._ok = 0
    cr._err = 0

    pending = [c for c in range(1, max_code + 1) if not cr.is_done(c)]
    rounds = 0
    while pending and rounds < max_rounds:
        rounds += 1
        if rounds > 1:
            print(f"== strong {language} ronda {rounds}: {len(pending)} pendientes ==")
        next_pending = []
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futs = {ex.submit(do_strong, cr, path, language, c): c for c in pending}
            for fut in as_completed(futs):
                c = futs[fut]
                try:
                    r = fut.result()
                except Exception as e:
                    print("ERR strong", c, e)
                    r = None
                if r is None:  # error de red / blocked -> reencolar
                    next_pending.append(c)
        pending = next_pending
    cr._strong_fh.close()
    cr._occ_fh.close()
    print("FIN strong", language, "nuevos =", cr._ok, " err =", cr._err,
          " pendientes =", len(pending))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/output")
    ap.add_argument("--delay", type=float, default=0.6)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--connect-timeout", type=float, default=10.0)
    ap.add_argument("--read-timeout", type=float, default=30.0)
    ap.add_argument("--retries", type=int, default=3)
    ap.add_argument("--limit", type=int, default=None, help="solo para prueba: topes de capitulos")
    ap.add_argument("--testament", type=int, choices=[1, 2], default=None)
    ap.add_argument("--only", choices=["bible", "greek", "hebrew", "all"], default="all")
    a = ap.parse_args()

    cr = Crawler(a.delay, a.workers, a.connect_timeout, a.read_timeout, a.retries, a.out)
    print(f"workers={a.workers} delay={a.delay} retries={a.retries} "
          f"timeouts=({a.connect_timeout},{a.read_timeout}) out={a.out}")

    if a.only in ("bible", "all"):
        crawl_bible(cr, a.workers, a.testament)
    if a.only in ("greek", "all"):
        crawl_strong(cr, a.workers, "greek", "strongcodes", 5624)
    if a.only in ("hebrew", "all"):
        crawl_strong(cr, a.workers, "hebrew", "strong_hebrew", 8680)

    print("Listo. Ahora:  python -X utf8 tools/build_assets.py --in", a.out, "--out assets/data")


if __name__ == "__main__":
    main()
