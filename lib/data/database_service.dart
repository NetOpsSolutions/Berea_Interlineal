import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'book_catalog.dart';
import 'models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;
  bool _initialized = false;
  bool _memoryMode = false;

  // Completer para evitar doble inicialización concurrente
  Completer<void>? _initCompleter;

  static const List<String> _strongAssets = [
    'assets/data/strong_greek.json',
    'assets/data/strong_hebrew.json',
  ];
  static const List<String> _interlinearAssets = [
    'assets/data/interlinear_at.json',
    'assets/data/interlinear_nt.json',
  ];
  static const String _occAsset = 'assets/data/occurrences.json';

  // Modo memoria (web/Chrome).
  final List<Verse> _memVerses = [];
  final Map<String, Verse> _verseIndex = {};
  final Map<String, int> _maxVerseIndex = {};
  final List<StrongEntry> _memStrong = [];
  final Map<String, StrongEntry> _strongIndex = {};
  final List<Occurrence> _memOcc = [];
  final Map<String, List<Occurrence>> _occIndex = {};
  int _nextVerseId = 1;
  int _nextWordId = 1;

  /// Deduce el idioma a partir del nombre del asset (fallback cuando el JSON
  /// no trae 'language' por palabra). at/hebrew -> hebreo; nt/greek -> griego.
  static String _langFromAsset(String asset) {
    final a = asset.toLowerCase();
    if (a.contains('hebrew') || a.contains('_at')) return 'hebrew';
    if (a.contains('greek') || a.contains('_nt')) return 'greek';
    return '';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    // Si ya hay una inicialización en curso, esperar a que termine
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      if (kIsWeb) {
        _memoryMode = true;
        await _initMemory();
      } else {
        try {
          _db = await _initSqlite();
        } catch (e) {
          // Fallback a modo memoria si sqflite no está disponible (ej. entorno de pruebas host)
          _memoryMode = true;
          await _initMemory();
        }
      }
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      final c = _initCompleter!;
      _initCompleter = null;
      c.completeError(e);
      rethrow;
    }
  }

  Future<Database> get database async {
    await initialize();
    if (_memoryMode) {
      throw UnsupportedError('SQLite no disponible en web; usa los metodos de alto nivel.');
    }
    return _db!;
  }

  // -------------------------------------------------------------------------
  // SQLITE (Android / iOS / desktop)
  // -------------------------------------------------------------------------
  /// Asset path de la BD pre-construida empaquetada con la app.
  static const String _prebuiltDbAsset = 'assets/data/logos_k_logos.db';

  Future<Database> _initSqlite() async {
    final dbPath = join(await getDatabasesPath(), 'logos_k_logos.db');

    // Comprobar si existe y si coincide en tamaño con el asset empaquetado
    final exists = await databaseExists(dbPath);
    final data = await rootBundle.load(_prebuiltDbAsset);
    final assetBytes = data.lengthInBytes;
    bool needsCopy = !exists;

    if (exists) {
      final file = File(dbPath);
      final currentLength = await file.length();
      if (currentLength != assetBytes) {
        needsCopy = true;
      }
    }

    if (needsCopy) {
      if (kDebugMode) debugPrint('DB: copiando desde asset ($assetBytes bytes)...');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await Directory(dirname(dbPath)).create(recursive: true);
      await File(dbPath).writeAsBytes(bytes, flush: true);
      if (kDebugMode) debugPrint('DB: copiada.');
    }

    final db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
        await d.execute('PRAGMA temp_store = MEMORY');
        await d.execute('PRAGMA synchronous = NORMAL');
        try {
          await d.rawQuery('PRAGMA cache_size = -8000');
          await d.rawQuery('PRAGMA mmap_size = 268435456');
        } catch (e) {
          if (kDebugMode) debugPrint('Ignored pragma error: $e');
        }
      },
    );
    return db;
  }

  Future<String?> _loadAsset(String asset) async {
    try {
      return await rootBundle.loadString(asset);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // MEMORIA (web)
  // -------------------------------------------------------------------------
  Future<void> _initMemory() async {
    // Strong
    for (final asset in _strongAssets) {
      try {
        final raw = await _loadAsset(asset);
        if (raw == null) continue;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final language = (data['language'] as String?) ?? _langFromAsset(asset);
        final entries = (data['entries'] as List?) ?? [];
        for (final item in entries) {
          final m = Map<String, Object?>.from(item as Map);
          final code = (m['code'] as int?) ?? 0;
          final entry = StrongEntry(
            language: language,
            code: code,
            lemma: (m['lemma'] as String?) ?? '',
            pronunciation: (m['pronunciation'] as String?) ?? '',
            derivation: (m['derivation'] as String?) ?? '',
            definition: (m['definition'] as String?) ?? '',
            rvDefinition: (m['rv_definition'] as String?) ?? '',
            stepbible: (m['stepbible'] as String?) ?? '',
          );
          _memStrong.add(entry);
          _strongIndex['$language:$code'] = entry;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('WARN strong $asset: $e');
      }
    }
    _memStrong.sort((a, b) => a.code.compareTo(b.code));

    // Interlineal
    for (final asset in _interlinearAssets) {
      try {
        final raw = await _loadAsset(asset);
        if (raw == null) continue;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final assetLang = _langFromAsset(asset);
        final verses = (data['verses'] as List?) ?? [];
        for (final verseItem in verses) {
          final v = Map<String, Object?>.from(verseItem as Map);
          final vLang = (v['language'] as String?) ?? assetLang;
          final wordsJson = (v['words'] as List?) ?? [];
          final verseId = _nextVerseId++;
          final words = <WordToken>[];
          var idx = 0;
          for (final wordItem in wordsJson) {
            idx++;
            final w = Map<String, Object?>.from(wordItem as Map);
            words.add(WordToken(
              id: _nextWordId++,
              verseId: verseId,
              position: (w['position'] as int?) ?? idx,
              strongCode: w['strong_code'] as int?,
              language: (w['language'] as String?) ?? vLang,
              lemma: (w['lemma'] as String?) ?? '',
              surface: (w['surface'] as String?) ?? '',
              parsing: (w['parsing'] as String?) ?? '',
              translation: (w['translation'] as String?) ?? '',
            ));
          }
          final verse = Verse(
            id: verseId,
            bookId: (v['book'] as String?) ?? '',
            chapter: (v['chapter'] as int?) ?? 0,
            verse: (v['verse'] as int?) ?? 0,
            translation: (v['translation'] as String?) ?? '',
            words: words,
          );
          _memVerses.add(verse);
          _verseIndex['${verse.bookId}:${verse.chapter}:${verse.verse}'] = verse;
          final maxKey = '${verse.bookId}:${verse.chapter}';
          final cur = _maxVerseIndex[maxKey] ?? 0;
          if (verse.verse > cur) _maxVerseIndex[maxKey] = verse.verse;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('WARN interlinear $asset: $e');
      }
    }

    // Occurrences
    try {
      final raw = await _loadAsset(_occAsset);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final occ = (data['occurrences'] as List?) ?? [];
        for (final item in occ) {
          final m = Map<String, Object?>.from(item as Map);
          final o = Occurrence(
            language: (m['language'] as String?) ?? '',
            strongCode: (m['strong_code'] as int?) ?? 0,
            bookId: (m['book_id'] as String?) ?? '',
            verses: (m['verses'] as int?) ?? 0,
            occurrences: (m['occurrences'] as int?) ?? 0,
          );
          _memOcc.add(o);
          final key = '${o.language}:${o.strongCode}';
          _occIndex.putIfAbsent(key, () => <Occurrence>[]).add(o);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('WARN occurrences: $e');
    }

    // Fallback ligero con sample.json si no se cargaron Strong ni versos (modo prueba/web ligero)
    if (_memStrong.isEmpty && _memVerses.isEmpty) {
      try {
        final raw = await _loadAsset('assets/data/sample.json');
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final strongList = (data['strong'] as List?) ?? [];
          for (final item in strongList) {
            final m = Map<String, Object?>.from(item as Map);
            final language = (m['language'] as String?) ?? 'hebrew';
            final code = (m['code'] as int?) ?? 0;
            final entry = StrongEntry(
              language: language,
              code: code,
              lemma: (m['lemma'] as String?) ?? '',
              pronunciation: (m['pronunciation'] as String?) ?? '',
              derivation: (m['derivation'] as String?) ?? '',
              definition: (m['definition'] as String?) ?? '',
              rvDefinition: (m['rv_definition'] as String?) ?? '',
              stepbible: (m['stepbible'] as String?) ?? '',
            );
            _memStrong.add(entry);
            _strongIndex['$language:$code'] = entry;
          }
          final versesList = (data['verses'] as List?) ?? [];
          for (final verseItem in versesList) {
            final v = Map<String, Object?>.from(verseItem as Map);
            final vLang = (v['language'] as String?) ?? 'hebrew';
            final wordsJson = (v['words'] as List?) ?? [];
            final verseId = _nextVerseId++;
            final words = <WordToken>[];
            var idx = 0;
            for (final wordItem in wordsJson) {
              idx++;
              final w = Map<String, Object?>.from(wordItem as Map);
              words.add(WordToken(
                id: _nextWordId++,
                verseId: verseId,
                position: (w['position'] as int?) ?? idx,
                strongCode: w['strong_code'] as int?,
                language: (w['language'] as String?) ?? vLang,
                lemma: (w['lemma'] as String?) ?? '',
                surface: (w['surface'] as String?) ?? '',
                parsing: (w['parsing'] as String?) ?? '',
                translation: (w['translation'] as String?) ?? '',
              ));
            }
            final verse = Verse(
              id: verseId,
              bookId: (v['book'] as String?) ?? '',
              chapter: (v['chapter'] as int?) ?? 0,
              verse: (v['verse'] as int?) ?? 0,
              translation: (v['translation'] as String?) ?? '',
              words: words,
            );
            _memVerses.add(verse);
            _verseIndex['${verse.bookId}:${verse.chapter}:${verse.verse}'] = verse;
            final maxKey = '${verse.bookId}:${verse.chapter}';
            final cur = _maxVerseIndex[maxKey] ?? 0;
            if (verse.verse > cur) _maxVerseIndex[maxKey] = verse.verse;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('WARN sample.json fallback: $e');
      }
    }
  }

  // -------------------------------------------------------------------------
  // API de alto nivel (igual en memoria y SQLite)
  // -------------------------------------------------------------------------
  Future<int> getMaxVerse(String bookId, int chapter) async {
    await initialize();
    if (_memoryMode) return _maxVerseIndex['$bookId:$chapter'] ?? 1;
    final db = _db!;
    final r = await db.rawQuery(
      'SELECT MAX(verse) AS m FROM verses WHERE book_id = ? AND chapter = ?',
      [bookId, chapter],
    );
    final v = r.first['m'];
    return v == null ? 1 : v as int;
  }

  Future<Verse?> getVerse(String bookId, int chapter, int verse) async {
    await initialize();
    if (_memoryMode) return _verseIndex['$bookId:$chapter:$verse'];
    final db = _db!;
    final vr = await db.query('verses',
        where: 'book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [bookId, chapter, verse], limit: 1);
    if (vr.isEmpty) return null;
    final vm = vr.first;
    final vid = vm['id'] as int;
    final wr = await db.query('words', where: 'verse_id = ?',
        whereArgs: [vid], orderBy: 'position ASC');
    return Verse(
      id: vid,
      bookId: (vm['book_id'] as String?) ?? '',
      chapter: (vm['chapter'] as int?) ?? 0,
      verse: (vm['verse'] as int?) ?? 0,
      translation: (vm['translation'] as String?) ?? '',
      words: wr.map((w) => WordToken.fromMap(w)).toList(),
    );
  }

  /// Carga todos los versículos y tokens léxicos de un capítulo completo en bloque
  /// utilizando consultas indexadas (~6 ms incluso en Salmos 119).
  Future<List<Verse>> getChapterVerses(String bookId, int chapter) async {
    await initialize();
    if (_memoryMode) {
      final list = _memVerses
          .where((v) => v.bookId == bookId && v.chapter == chapter)
          .toList()
        ..sort((a, b) => a.verse.compareTo(b.verse));
      return list;
    }

    final db = _db!;
    final vRows = await db.query(
      'verses',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC',
    );
    if (vRows.isEmpty) return [];

    final verseIds = vRows.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(verseIds.length, '?').join(',');
    final wRows = await db.rawQuery(
      'SELECT id, verse_id, position, strong_code, language, lemma, surface, parsing, translation '
      'FROM words WHERE verse_id IN ($placeholders) ORDER BY verse_id ASC, position ASC',
      verseIds,
    );

    final Map<int, List<WordToken>> wordsByVerse = {};
    for (final w in wRows) {
      final token = WordToken.fromMap(w);
      wordsByVerse.putIfAbsent(token.verseId, () => <WordToken>[]).add(token);
    }

    return vRows.map((vm) {
      final vid = vm['id'] as int;
      return Verse(
        id: vid,
        bookId: (vm['book_id'] as String?) ?? '',
        chapter: (vm['chapter'] as int?) ?? 0,
        verse: (vm['verse'] as int?) ?? 0,
        translation: (vm['translation'] as String?) ?? '',
        words: wordsByVerse[vid] ?? const <WordToken>[],
      );
    }).toList();
  }

  Future<List<StrongEntry>> searchStrong(String language, String query) async {
    await initialize();
    final q = query.trim();
    if (_memoryMode) {
      if (q.isEmpty) {
        final out = <StrongEntry>[];
        for (final e in _memStrong) {
          if (e.language == language) {
            out.add(e);
            if (out.length >= 100) break;
          }
        }
        return out;
      }
      final lower = q.toLowerCase();
      final numeric = int.tryParse(q.replaceAll(RegExp(r'[^0-9]'), ''));
      final out = <StrongEntry>[];
      for (final e in _memStrong) {
        if (e.language != language) continue;
        bool match = false;
        if (numeric != null && e.code == numeric) match = true;
        if (!match && e.lemma.toLowerCase().contains(lower)) match = true;
        if (!match && e.pronunciation.toLowerCase().contains(lower)) match = true;
        if (!match && e.definition.toLowerCase().contains(lower)) match = true;
        if (!match && e.rvDefinition.toLowerCase().contains(lower)) match = true;
        if (!match && e.stepbible.toLowerCase().contains(lower)) match = true;
        if (match) {
          out.add(e);
          if (out.length >= 100) break;
        }
      }
      return out;
    }
    final db = _db!;
    if (q.isEmpty) {
      final r = await db.query('strong_entries', where: 'language = ?',
          whereArgs: [language], orderBy: 'code ASC', limit: 100);
      return r.map((e) => StrongEntry.fromMap(e)).toList();
    }
    final numericCode = int.tryParse(q.replaceAll(RegExp(r'[^0-9]'), ''));
    final like = '%$q%';
    List<Map<String, Object?>> r;
    if (numericCode != null) {
      r = await db.rawQuery('''
        SELECT * FROM strong_entries WHERE language = ? AND (
          code = ? OR lemma LIKE ? OR pronunciation LIKE ? OR definition LIKE ?
          OR rv_definition LIKE ? OR stepbible LIKE ?)
        ORDER BY code ASC LIMIT 100
      ''', [language, numericCode, like, like, like, like, like]);
    } else {
      r = await db.rawQuery('''
        SELECT * FROM strong_entries WHERE language = ? AND (
          lemma LIKE ? OR pronunciation LIKE ? OR definition LIKE ?
          OR rv_definition LIKE ? OR stepbible LIKE ?)
        ORDER BY code ASC LIMIT 100
      ''', [language, like, like, like, like, like]);
    }
    return r.map((e) => StrongEntry.fromMap(e)).toList();
  }

  Future<StrongEntry?> getStrong(String language, int code) async {
    await initialize();
    if (_memoryMode) return _strongIndex['$language:$code'];
    final db = _db!;
    final r = await db.query('strong_entries',
        where: 'language = ? AND code = ?', whereArgs: [language, code], limit: 1);
    return r.isEmpty ? null : StrongEntry.fromMap(r.first);
  }

  Future<List<Occurrence>> getOccurrences(String language, int code) async {
    await initialize();
    if (_memoryMode) return _occIndex['$language:$code'] ?? [];
    final db = _db!;
    final r = await db.query('occurrences',
        where: 'language = ? AND strong_code = ?',
        whereArgs: [language, code], orderBy: 'book_id ASC');
    return r.map((e) => Occurrence.fromMap(e)).toList();
  }

  Future<List<Verse>> getVersesForStrong(String language, int code, {String? bookId}) async {
    await initialize();
    if (_memoryMode) {
      final results = <Verse>[];
      for (final v in _memVerses) {
        if (bookId != null && bookId.isNotEmpty && v.bookId != bookId) {
          continue;
        }
        final matches = v.words.any((w) => w.language == language && w.strongCode == code);
        if (matches) {
          results.add(v);
        }
      }
      return results;
    }

    final db = _db!;
    String query = '''
      SELECT DISTINCT v.id, v.book_id, v.chapter, v.verse, v.translation
      FROM verses v
      JOIN words w ON w.verse_id = v.id
      WHERE w.language = ? AND w.strong_code = ?
    ''';
    final List<Object?> args = [language, code];
    if (bookId != null && bookId.isNotEmpty) {
      query += ' AND v.book_id = ?';
      args.add(bookId);
    }
    query += ' ORDER BY v.chapter ASC, v.verse ASC';

    final rows = await db.rawQuery(query, args);
    final results = <Verse>[];
    for (final r in rows) {
      final vid = r['id'] as int;
      final wr = await db.query(
        'words',
        where: 'verse_id = ?',
        whereArgs: [vid],
        orderBy: 'position ASC',
      );
      results.add(Verse(
        id: vid,
        bookId: (r['book_id'] as String?) ?? '',
        chapter: (r['chapter'] as int?) ?? 1,
        verse: (r['verse'] as int?) ?? 1,
        translation: (r['translation'] as String?) ?? '',
        words: wr.map((w) => WordToken.fromMap(w)).toList(),
      ));
    }
    return results;
  }

  // -------------------------------------------------------------------------
  // BÚSQUEDA GLOBAL (Biblia + Strong)
  // -------------------------------------------------------------------------
  Future<VerseSearchResult?> parseDirectReference(String query) async {
    await initialize();
    final q = query.trim();
    if (q.isEmpty) return null;

    final reg = RegExp(
      r'^(\d?\s*[a-zA-ZáéíóúÁÉÍÓÚñÑ]+)\s+(\d+)(?:[:,\.\s]+(\d+))?$',
    );
    final match = reg.firstMatch(q);
    if (match != null) {
      final bookStr = match.group(1)!.trim();
      final chapStr = match.group(2)!;
      final verseStr = match.group(3);

      final book = BookCatalog.findByNameOrId(bookStr);
      if (book != null) {
        final chapter = int.tryParse(chapStr) ?? 1;
        final verseNum = verseStr != null ? (int.tryParse(verseStr) ?? 1) : 1;
        final v = await getVerse(book.id, chapter, verseNum);
        if (v != null) {
          return VerseSearchResult(
            bookId: v.bookId,
            bookName: book.name,
            chapter: v.chapter,
            verse: v.verse,
            translation: v.translation,
          );
        }
      }
    }
    return null;
  }

  Future<List<VerseSearchResult>> searchVerses(String query, {int limit = 50}) async {
    await initialize();
    final q = query.trim();
    if (q.isEmpty) return [];

    if (_memoryMode) {
      final lower = q.toLowerCase();
      final results = <VerseSearchResult>[];
      for (final v in _memVerses) {
        if (v.translation.toLowerCase().contains(lower)) {
          final bName = BookCatalog.nameById(v.bookId);
          results.add(VerseSearchResult(
            bookId: v.bookId,
            bookName: bName,
            chapter: v.chapter,
            verse: v.verse,
            translation: v.translation,
          ));
          if (results.length >= limit) break;
        }
      }
      return results;
    }

    final db = _db!;
    final r = await db.query(
      'verses',
      columns: ['book_id', 'chapter', 'verse', 'translation'],
      where: 'translation LIKE ?',
      whereArgs: ['%$q%'],
      limit: limit,
      orderBy: 'book_id ASC, chapter ASC, verse ASC',
    );
    return r.map((m) {
      final bId = (m['book_id'] as String?) ?? '';
      return VerseSearchResult(
        bookId: bId,
        bookName: BookCatalog.nameById(bId),
        chapter: (m['chapter'] as int?) ?? 1,
        verse: (m['verse'] as int?) ?? 1,
        translation: (m['translation'] as String?) ?? '',
      );
    }).toList();
  }

  Future<GlobalSearchResult> globalSearch(String query, {int verseLimit = 40, int strongLimit = 20}) async {
    await initialize();
    final q = query.trim();
    if (q.isEmpty) {
      return const GlobalSearchResult(
        query: '',
        verses: [],
        greekEntries: [],
        hebrewEntries: [],
      );
    }

    final directRef = await parseDirectReference(q);

    String? forcedLang;
    int? forcedCode;
    final strongMatch = RegExp(r'^([GgHh])?\s*#?\s*(\d+)$').firstMatch(q);
    if (strongMatch != null) {
      final prefix = strongMatch.group(1)?.toUpperCase();
      forcedCode = int.tryParse(strongMatch.group(2) ?? '');
      if (prefix == 'G') forcedLang = 'greek';
      if (prefix == 'H') forcedLang = 'hebrew';
    }

    List<StrongEntry> greek = [];
    List<StrongEntry> hebrew = [];

    if (forcedLang == 'greek' && forcedCode != null) {
      final e = await getStrong('greek', forcedCode);
      if (e != null) greek = [e];
    } else if (forcedLang == 'hebrew' && forcedCode != null) {
      final e = await getStrong('hebrew', forcedCode);
      if (e != null) hebrew = [e];
    } else {
      final gFuture = searchStrong('greek', q);
      final hFuture = searchStrong('hebrew', q);
      final strongResults = await Future.wait([gFuture, hFuture]);
      greek = strongResults[0].take(strongLimit).toList();
      hebrew = strongResults[1].take(strongLimit).toList();
    }

    final verses = await searchVerses(q, limit: verseLimit);

    return GlobalSearchResult(
      query: q,
      directReference: directRef,
      verses: verses,
      greekEntries: greek,
      hebrewEntries: hebrew,
    );
  }
}
