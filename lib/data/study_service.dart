// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'book_catalog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de datos de usuario
// ─────────────────────────────────────────────────────────────────────────────

class BookmarkItem {
  final String id; // '${bookId}:${chapter}:${verse}'
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String preview;
  final DateTime createdAt;

  BookmarkItem({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.preview,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'book_name': bookName,
        'chapter': chapter,
        'verse': verse,
        'preview': preview,
        'created_at': createdAt.toIso8601String(),
      };

  factory BookmarkItem.fromMap(Map<String, dynamic> map) => BookmarkItem(
        id: map['id'] as String? ?? '',
        bookId: map['book_id'] as String? ?? '',
        bookName: map['book_name'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        preview: map['preview'] as String? ?? '',
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  // Compatibilidad: lee también el formato JSON antiguo de SharedPreferences
  factory BookmarkItem.fromLegacyMap(Map<String, dynamic> map) => BookmarkItem(
        id: map['id'] as String? ?? '',
        bookId: map['bookId'] as String? ?? '',
        bookName: map['bookName'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        preview: map['preview'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class VerseNoteItem {
  final String id; // '${bookId}:${chapter}:${verse}'
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String note;
  final DateTime updatedAt;

  VerseNoteItem({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.note,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'book_name': bookName,
        'chapter': chapter,
        'verse': verse,
        'note': note,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VerseNoteItem.fromMap(Map<String, dynamic> map) => VerseNoteItem(
        id: map['id'] as String? ?? '',
        bookId: map['book_id'] as String? ?? '',
        bookName: map['book_name'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        note: map['note'] as String? ?? '',
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  factory VerseNoteItem.fromLegacyMap(Map<String, dynamic> map) => VerseNoteItem(
        id: map['id'] as String? ?? '',
        bookId: map['bookId'] as String? ?? '',
        bookName: map['bookName'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        note: map['note'] as String? ?? '',
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class StrongNoteItem {
  final String id; // '${language}:${code}'
  final String language;
  final int code;
  final String lemma;
  final String note;
  final DateTime updatedAt;

  StrongNoteItem({
    required this.id,
    required this.language,
    required this.code,
    required this.lemma,
    required this.note,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'language': language,
        'code': code,
        'lemma': lemma,
        'note': note,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StrongNoteItem.fromMap(Map<String, dynamic> map) => StrongNoteItem(
        id: map['id'] as String? ?? '',
        language: map['language'] as String? ?? 'greek',
        code: (map['code'] as int?) ?? 0,
        lemma: map['lemma'] as String? ?? '',
        note: map['note'] as String? ?? '',
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  factory StrongNoteItem.fromLegacyMap(Map<String, dynamic> map) => StrongNoteItem(
        id: map['id'] as String? ?? '',
        language: map['language'] as String? ?? 'greek',
        code: (map['code'] as int?) ?? 0,
        lemma: map['lemma'] as String? ?? '',
        note: map['note'] as String? ?? '',
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class HistoryItem {
  final String id; // '${bookId}:${chapter}:${verse}'
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String preview;
  final DateTime visitedAt;

  HistoryItem({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.preview,
    required this.visitedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'book_name': bookName,
        'chapter': chapter,
        'verse': verse,
        'preview': preview,
        'visited_at': visitedAt.toIso8601String(),
      };

  factory HistoryItem.fromMap(Map<String, dynamic> map) => HistoryItem(
        id: map['id'] as String? ?? '',
        bookId: map['book_id'] as String? ?? '',
        bookName: map['book_name'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        preview: map['preview'] as String? ?? '',
        visitedAt: map['visited_at'] != null
            ? DateTime.tryParse(map['visited_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  factory HistoryItem.fromLegacyMap(Map<String, dynamic> map) => HistoryItem(
        id: map['id'] as String? ?? '',
        bookId: map['bookId'] as String? ?? '',
        bookName: map['bookName'] as String? ?? '',
        chapter: (map['chapter'] as int?) ?? 1,
        verse: (map['verse'] as int?) ?? 1,
        preview: map['preview'] as String? ?? '',
        visitedAt: map['visitedAt'] != null
            ? DateTime.tryParse(map['visitedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StudyService — Persistencia real en SQLite (Fase 2)
//
// • Los datos de usuario (marcadores, notas, historial) se guardan en una base
//   de datos SQLite DEDICADA: logos_user_data.db
//   → DISTINTA a logos_k_logos.db (base bíblica, solo lectura).
// • Las preferencias de UI (tema, modo lectura fluida) siguen en
//   SharedPreferences porque son configuración, no datos personales del usuario.
// • En el primer arranque con datos legacy, el migrador importa automáticamente
//   los registros desde SharedPreferences y luego elimina las claves antiguas.
// ─────────────────────────────────────────────────────────────────────────────
class StudyService extends ChangeNotifier {
  static final StudyService instance = StudyService._();
  StudyService._();

  // ── Claves de SharedPreferences (solo UI / config) ─────────────────────────
  static const String _keyFluentMode = 'logos_fluent_mode_v1';
  static const String _keyThemeMode = 'logos_theme_mode_v1';

  // ── Claves legacy (solo para migración; se borran tras importar) ───────────
  static const String _legacyKeyBookmarks = 'logos_bookmarks_v1';
  static const String _legacyKeyVerseNotes = 'logos_verse_notes_v1';
  static const String _legacyKeyStrongNotes = 'logos_strong_notes_v1';
  static const String _legacyKeyHistory = 'logos_history_v1';

  // ── Nombre de la BD de usuario (independiente de la bíblica) ──────────────
  static const String _userDbName = 'logos_user_data.db';
  static const int _userDbVersion = 1;

  // ── Estado interno ─────────────────────────────────────────────────────────
  bool _initialized = false;
  Database? _userDb;
  SharedPreferences? _prefs;

  // Caché en memoria para acceso reactivo desde la UI
  final Map<String, BookmarkItem> _bookmarks = {};
  final Map<String, VerseNoteItem> _verseNotes = {};
  final Map<String, StrongNoteItem> _strongNotes = {};
  final List<HistoryItem> _history = [];

  bool _fluentReadingMode = false;
  ThemeMode _themeMode = ThemeMode.dark;

  // ── Getters públicos ───────────────────────────────────────────────────────
  bool get isInitialized => _initialized;
  bool get fluentReadingMode => _fluentReadingMode;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  List<BookmarkItem> get bookmarks =>
      _bookmarks.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<VerseNoteItem> get verseNotes =>
      _verseNotes.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<StrongNoteItem> get strongNotes =>
      _strongNotes.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<HistoryItem> get history => List.unmodifiable(_history);

  // ─────────────────────────────────────────────────────────────────────────
  // Inicialización
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();

      // Preferencias de UI (siempre en SharedPreferences)
      _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? false;
      final tRaw = _prefs?.getString(_keyThemeMode);
      _themeMode = tRaw == 'light' ? ThemeMode.light : ThemeMode.dark;

      // Abrir / crear la base de datos de usuario
      if (!kIsWeb) {
        await _openUserDatabase();
        await _createUserTables();
        await _migrateLegacySharedPreferences();
        await _loadAllFromDb();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error en initialize: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Abre logos_user_data.db en el directorio estándar de bases de datos.
  Future<void> _openUserDatabase() async {
    final dbPath = join(await getDatabasesPath(), _userDbName);
    _userDb = await openDatabase(
      dbPath,
      version: _userDbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
      },
    );
  }

  /// Crea las tablas de usuario si no existen (idempotente).
  Future<void> _createUserTables() async {
    final db = _userDb;
    if (db == null) return;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_bookmarks (
        id        TEXT PRIMARY KEY,
        book_id   TEXT NOT NULL,
        book_name TEXT NOT NULL,
        chapter   INTEGER NOT NULL,
        verse     INTEGER NOT NULL,
        preview   TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_verse_notes (
        id        TEXT PRIMARY KEY,
        book_id   TEXT NOT NULL,
        book_name TEXT NOT NULL,
        chapter   INTEGER NOT NULL,
        verse     INTEGER NOT NULL,
        note      TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_strong_notes (
        id       TEXT PRIMARY KEY,
        language TEXT NOT NULL,
        code     INTEGER NOT NULL,
        lemma    TEXT NOT NULL,
        note     TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_history (
        id        TEXT PRIMARY KEY,
        book_id   TEXT NOT NULL,
        book_name TEXT NOT NULL,
        chapter   INTEGER NOT NULL,
        verse     INTEGER NOT NULL,
        preview   TEXT NOT NULL,
        visited_at TEXT NOT NULL
      )
    ''');

    // Índices para acelerar consultas de historial ordenado por fecha
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_visited ON user_history(visited_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_created ON user_bookmarks(created_at DESC)');
  }

  /// Migra datos legacy de SharedPreferences → SQLite (se ejecuta solo una vez).
  Future<void> _migrateLegacySharedPreferences() async {
    final prefs = _prefs;
    final db = _userDb;
    if (prefs == null || db == null) return;

    bool migrated = false;

    // ── Marcadores ──────────────────────────────────────────────────────────
    final bRaw = prefs.getString(_legacyKeyBookmarks);
    if (bRaw != null && bRaw.isNotEmpty) {
      try {
        final list = jsonDecode(bRaw) as List;
        await db.transaction((txn) async {
          for (final item in list) {
            final b = BookmarkItem.fromLegacyMap(Map<String, dynamic>.from(item as Map));
            await txn.insert(
              'user_bookmarks',
              b.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });
        await prefs.remove(_legacyKeyBookmarks);
        migrated = true;
        if (kDebugMode) debugPrint('[StudyService] Migrados ${list.length} marcadores a SQLite.');
      } catch (e) {
        if (kDebugMode) debugPrint('[StudyService] Error migrando marcadores: $e');
      }
    }

    // ── Notas de versículos ─────────────────────────────────────────────────
    final vnRaw = prefs.getString(_legacyKeyVerseNotes);
    if (vnRaw != null && vnRaw.isNotEmpty) {
      try {
        final list = jsonDecode(vnRaw) as List;
        await db.transaction((txn) async {
          for (final item in list) {
            final vn = VerseNoteItem.fromLegacyMap(Map<String, dynamic>.from(item as Map));
            await txn.insert(
              'user_verse_notes',
              vn.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });
        await prefs.remove(_legacyKeyVerseNotes);
        migrated = true;
        if (kDebugMode) debugPrint('[StudyService] Migradas ${list.length} notas de versículo a SQLite.');
      } catch (e) {
        if (kDebugMode) debugPrint('[StudyService] Error migrando notas de versículo: $e');
      }
    }

    // ── Notas Strong ────────────────────────────────────────────────────────
    final snRaw = prefs.getString(_legacyKeyStrongNotes);
    if (snRaw != null && snRaw.isNotEmpty) {
      try {
        final list = jsonDecode(snRaw) as List;
        await db.transaction((txn) async {
          for (final item in list) {
            final sn = StrongNoteItem.fromLegacyMap(Map<String, dynamic>.from(item as Map));
            await txn.insert(
              'user_strong_notes',
              sn.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });
        await prefs.remove(_legacyKeyStrongNotes);
        migrated = true;
        if (kDebugMode) debugPrint('[StudyService] Migradas ${list.length} notas Strong a SQLite.');
      } catch (e) {
        if (kDebugMode) debugPrint('[StudyService] Error migrando notas Strong: $e');
      }
    }

    // ── Historial ───────────────────────────────────────────────────────────
    final hRaw = prefs.getString(_legacyKeyHistory);
    if (hRaw != null && hRaw.isNotEmpty) {
      try {
        final list = jsonDecode(hRaw) as List;
        await db.transaction((txn) async {
          for (final item in list) {
            final h = HistoryItem.fromLegacyMap(Map<String, dynamic>.from(item as Map));
            await txn.insert(
              'user_history',
              h.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });
        await prefs.remove(_legacyKeyHistory);
        migrated = true;
        if (kDebugMode) debugPrint('[StudyService] Migrados ${list.length} registros de historial a SQLite.');
      } catch (e) {
        if (kDebugMode) debugPrint('[StudyService] Error migrando historial: $e');
      }
    }

    if (migrated) {
      if (kDebugMode) debugPrint('[StudyService] ✅ Migración legacy → SQLite completada.');
    }
  }

  /// Carga todos los datos desde SQLite hacia el caché en memoria.
  Future<void> _loadAllFromDb() async {
    final db = _userDb;
    if (db == null) return;

    // Marcadores
    _bookmarks.clear();
    final bRows = await db.query('user_bookmarks');
    for (final row in bRows) {
      final b = BookmarkItem.fromMap(Map<String, dynamic>.from(row));
      _bookmarks[b.id] = b;
    }

    // Notas de versículos
    _verseNotes.clear();
    final vnRows = await db.query('user_verse_notes');
    for (final row in vnRows) {
      final vn = VerseNoteItem.fromMap(Map<String, dynamic>.from(row));
      _verseNotes[vn.id] = vn;
    }

    // Notas Strong
    _strongNotes.clear();
    final snRows = await db.query('user_strong_notes');
    for (final row in snRows) {
      final sn = StrongNoteItem.fromMap(Map<String, dynamic>.from(row));
      _strongNotes[sn.id] = sn;
    }

    // Historial (ordenado por fecha de visita desc)
    _history.clear();
    final hRows = await db.query('user_history', orderBy: 'visited_at DESC', limit: 60);
    for (final row in hRows) {
      _history.add(HistoryItem.fromMap(Map<String, dynamic>.from(row)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Preferencias de UI (SharedPreferences — no son datos de usuario)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setFluentReadingMode(bool value) async {
    if (_fluentReadingMode == value) return;
    _fluentReadingMode = value;
    notifyListeners();
    await _prefs?.setBool(_keyFluentMode, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_keyThemeMode, mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Marcadores — CRUD SQLite
  // ─────────────────────────────────────────────────────────────────────────

  String _verseKey(String bookId, int chapter, int verse) => '$bookId:$chapter:$verse';

  bool isBookmarked(String bookId, int chapter, int verse) {
    return _bookmarks.containsKey(_verseKey(bookId, chapter, verse));
  }

  Future<bool> toggleBookmark({
    required String bookId,
    required int chapter,
    required int verse,
    required String preview,
  }) async {
    final key = _verseKey(bookId, chapter, verse);
    final bool added;

    if (_bookmarks.containsKey(key)) {
      // Eliminar de caché y BD
      _bookmarks.remove(key);
      added = false;
      await _dbDeleteBookmark(key);
    } else {
      // Insertar en caché y BD
      final name = BookCatalog.nameById(bookId);
      final item = BookmarkItem(
        id: key,
        bookId: bookId,
        bookName: name.isNotEmpty ? name : bookId,
        chapter: chapter,
        verse: verse,
        preview: preview,
        createdAt: DateTime.now(),
      );
      _bookmarks[key] = item;
      added = true;
      await _dbInsertBookmark(item);
    }

    notifyListeners();
    return added;
  }

  Future<void> removeBookmark(String key) async {
    if (_bookmarks.remove(key) != null) {
      notifyListeners();
      await _dbDeleteBookmark(key);
    }
  }

  Future<void> _dbInsertBookmark(BookmarkItem item) async {
    try {
      await _userDb?.insert(
        'user_bookmarks',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error insertando marcador: $e');
    }
  }

  Future<void> _dbDeleteBookmark(String id) async {
    try {
      await _userDb?.delete('user_bookmarks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error eliminando marcador: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notas de versículos — CRUD SQLite
  // ─────────────────────────────────────────────────────────────────────────

  VerseNoteItem? getVerseNote(String bookId, int chapter, int verse) {
    return _verseNotes[_verseKey(bookId, chapter, verse)];
  }

  Future<void> saveVerseNote({
    required String bookId,
    required int chapter,
    required int verse,
    required String note,
  }) async {
    final key = _verseKey(bookId, chapter, verse);
    final text = note.trim();
    if (text.isEmpty) {
      await deleteVerseNote(bookId, chapter, verse);
      return;
    }
    final name = BookCatalog.nameById(bookId);
    final item = VerseNoteItem(
      id: key,
      bookId: bookId,
      bookName: name.isNotEmpty ? name : bookId,
      chapter: chapter,
      verse: verse,
      note: text,
      updatedAt: DateTime.now(),
    );
    _verseNotes[key] = item;
    notifyListeners();
    await _dbUpsertVerseNote(item);
  }

  Future<void> deleteVerseNote(String bookId, int chapter, int verse) async {
    final key = _verseKey(bookId, chapter, verse);
    if (_verseNotes.remove(key) != null) {
      notifyListeners();
      await _dbDeleteVerseNote(key);
    }
  }

  Future<void> _dbUpsertVerseNote(VerseNoteItem item) async {
    try {
      await _userDb?.insert(
        'user_verse_notes',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error guardando nota de versículo: $e');
    }
  }

  Future<void> _dbDeleteVerseNote(String id) async {
    try {
      await _userDb?.delete('user_verse_notes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error eliminando nota de versículo: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notas Strong — CRUD SQLite
  // ─────────────────────────────────────────────────────────────────────────

  String _strongKey(String language, int code) => '$language:$code';

  StrongNoteItem? getStrongNote(String language, int code) {
    return _strongNotes[_strongKey(language, code)];
  }

  Future<void> saveStrongNote({
    required String language,
    required int code,
    required String lemma,
    required String note,
  }) async {
    final key = _strongKey(language, code);
    final text = note.trim();
    if (text.isEmpty) {
      await deleteStrongNote(language, code);
      return;
    }
    final item = StrongNoteItem(
      id: key,
      language: language,
      code: code,
      lemma: lemma,
      note: text,
      updatedAt: DateTime.now(),
    );
    _strongNotes[key] = item;
    notifyListeners();
    await _dbUpsertStrongNote(item);
  }

  Future<void> deleteStrongNote(String language, int code) async {
    final key = _strongKey(language, code);
    if (_strongNotes.remove(key) != null) {
      notifyListeners();
      await _dbDeleteStrongNote(key);
    }
  }

  Future<void> _dbUpsertStrongNote(StrongNoteItem item) async {
    try {
      await _userDb?.insert(
        'user_strong_notes',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error guardando nota Strong: $e');
    }
  }

  Future<void> _dbDeleteStrongNote(String id) async {
    try {
      await _userDb?.delete('user_strong_notes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error eliminando nota Strong: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Historial — CRUD SQLite (máx 60 entradas, LIFO con deduplicación)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> addToHistory({
    required String bookId,
    required int chapter,
    required int verse,
    required String preview,
  }) async {
    final key = _verseKey(bookId, chapter, verse);

    // Eliminar duplicado anterior del caché para moverlo al frente
    _history.removeWhere((h) => h.id == key);

    final name = BookCatalog.nameById(bookId);
    final item = HistoryItem(
      id: key,
      bookId: bookId,
      bookName: name.isNotEmpty ? name : bookId,
      chapter: chapter,
      verse: verse,
      preview: preview,
      visitedAt: DateTime.now(),
    );
    _history.insert(0, item);

    // Truncar caché a 60 entradas
    if (_history.length > 60) {
      _history.removeRange(60, _history.length);
    }

    notifyListeners();
    await _dbUpsertHistory(item);
    await _dbTrimHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    try {
      await _userDb?.delete('user_history');
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error borrando historial: $e');
    }
  }

  Future<void> _dbUpsertHistory(HistoryItem item) async {
    try {
      // REPLACE actualiza visited_at si ya existe el mismo id (deduplicación)
      await _userDb?.insert(
        'user_history',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error insertando historial: $e');
    }
  }

  /// Mantiene únicamente los 60 registros más recientes en la BD.
  Future<void> _dbTrimHistory() async {
    try {
      await _userDb?.execute('''
        DELETE FROM user_history
        WHERE id NOT IN (
          SELECT id FROM user_history
          ORDER BY visited_at DESC
          LIMIT 60
        )
      ''');
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error al truncar historial en BD: $e');
    }
  }
}
