// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/theme.dart';
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
        id: map['id']?.toString() ?? '',
        bookId: map['book_id']?.toString() ?? '',
        bookName: map['book_name']?.toString() ?? '',
        chapter: (map['chapter'] as num?)?.toInt() ?? 1,
        verse: (map['verse'] as num?)?.toInt() ?? 1,
        preview: map['preview']?.toString() ?? '',
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
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
        id: map['id']?.toString() ?? '',
        bookId: map['book_id']?.toString() ?? '',
        bookName: map['book_name']?.toString() ?? '',
        chapter: (map['chapter'] as num?)?.toInt() ?? 1,
        verse: (map['verse'] as num?)?.toInt() ?? 1,
        note: map['note']?.toString() ?? '',
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
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
        id: map['id']?.toString() ?? '',
        language: map['language']?.toString() ?? 'greek',
        code: (map['code'] as num?)?.toInt() ?? 0,
        lemma: map['lemma']?.toString() ?? '',
        note: map['note']?.toString() ?? '',
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
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
        id: map['id']?.toString() ?? '',
        bookId: map['book_id']?.toString() ?? '',
        bookName: map['book_name']?.toString() ?? '',
        chapter: (map['chapter'] as num?)?.toInt() ?? 1,
        verse: (map['verse'] as num?)?.toInt() ?? 1,
        preview: map['preview']?.toString() ?? '',
        visitedAt: map['visited_at'] != null
            ? DateTime.tryParse(map['visited_at'].toString()) ?? DateTime.now()
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

class VerseHighlightItem {
  final String id; // '${bookId}:${chapter}:${verse}'
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String colorKey; // 'promesas', 'mandamientos', 'atributos', 'advertencias', 'profecia'
  final List<String> selectedFragments; // vacío = versículo completo resaltado
  final String preview;
  final DateTime updatedAt;

  VerseHighlightItem({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.colorKey,
    this.selectedFragments = const [],
    required this.preview,
    required this.updatedAt,
  });

  bool get isWholeVerse => selectedFragments.isEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'book_name': bookName,
        'chapter': chapter,
        'verse': verse,
        'color_key': colorKey,
        'selected_text': selectedFragments.isEmpty ? '' : jsonEncode(selectedFragments),
        'preview': preview,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VerseHighlightItem.fromMap(Map<String, dynamic> map) {
    final rawSel = map['selected_text']?.toString() ?? '';
    List<String> fragments = const [];
    if (rawSel.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSel);
        if (decoded is List) {
          fragments = decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        } else {
          fragments = [rawSel];
        }
      } catch (_) {
        fragments = [rawSel];
      }
    }
    return VerseHighlightItem(
      id: map['id']?.toString() ?? '',
      bookId: map['book_id']?.toString() ?? '',
      bookName: map['book_name']?.toString() ?? '',
      chapter: (map['chapter'] as num?)?.toInt() ?? 1,
      verse: (map['verse'] as num?)?.toInt() ?? 1,
      colorKey: map['color_key']?.toString() ?? 'promesas',
      selectedFragments: fragments,
      preview: map['preview']?.toString() ?? '',
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
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
  static const String _keyChapterMode = 'logos_chapter_mode_v1';
  static const String _keyHebrewFont = 'logos_hebrew_font_v1';
  static const String _keyGreekFont = 'logos_greek_font_v1';
  static const String _keyFontScale = 'logos_font_scale_v1';
  static const String _keyLastSeenTourVersion = 'logos_last_seen_tour_version_v1';

  // ── Claves legacy (solo para migración; se borran tras importar) ───────────
  static const String _legacyKeyBookmarks = 'logos_bookmarks_v1';
  static const String _legacyKeyVerseNotes = 'logos_verse_notes_v1';
  static const String _legacyKeyStrongNotes = 'logos_strong_notes_v1';
  static const String _legacyKeyHistory = 'logos_history_v1';

  // ── Nombre de la BD de usuario (independiente de la bíblica) ──────────────
  static const String _userDbName = 'logos_user_data.db';
  static const int _userDbVersion = 2;

  // ── Estado interno ─────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _sqliteAvailable = true;
  Completer<void>? _initCompleter;
  Database? _userDb;
  SharedPreferences? _prefs;

  // Caché en memoria para acceso reactivo desde la UI
  final Map<String, BookmarkItem> _bookmarks = {};
  final Map<String, VerseHighlightItem> _highlights = {};
  final Map<String, VerseNoteItem> _verseNotes = {};
  final Map<String, StrongNoteItem> _strongNotes = {};
  final List<HistoryItem> _history = [];

  bool _fluentReadingMode = false;
  bool _chapterReadingMode = true;
  String _hebrewFontFamily = AcademicFonts.defaultHebrew;
  String _greekFontFamily = AcademicFonts.defaultGreek;
  double _readingFontScale = 1.0;
  ThemeMode _themeMode = ThemeMode.dark;
  String _lastSeenTourVersion = '';

  // ── Getters públicos ───────────────────────────────────────────────────────
  bool get isInitialized => _initialized;
  bool get fluentReadingMode => _fluentReadingMode;
  bool get chapterReadingMode => _chapterReadingMode;
  String get hebrewFontFamily => _hebrewFontFamily;
  String get greekFontFamily => _greekFontFamily;
  double get readingFontScale => _readingFontScale;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get lastSeenTourVersion => _lastSeenTourVersion;

  /// Retorna true únicamente si la guía interactiva aún no se ha mostrado
  /// para la versión instalada actual (ej. después de actualizar a 1.3.2).
  bool shouldShowVersionTour(String currentAppVersion) {
    final clean = currentAppVersion.trim();
    if (clean.isEmpty) return false;
    return _lastSeenTourVersion.trim() != clean;
  }

  TextStyle originalScriptStyle({
    required bool isHebrew,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double height = 1.55,
  }) {
    return AcademicFonts.originalScriptStyle(
      isHebrew: isHebrew,
      hebrewFamily: _hebrewFontFamily,
      greekFamily: _greekFontFamily,
      fontSize: fontSize * _readingFontScale,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  List<BookmarkItem> get bookmarks =>
      _bookmarks.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<VerseHighlightItem> get highlights =>
      _highlights.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<VerseHighlightItem> highlightsByColor(String? colorKey) {
    final all = highlights;
    if (colorKey == null || colorKey.isEmpty || colorKey == 'all') return all;
    return all.where((h) => h.colorKey == colorKey).toList();
  }

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
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      // 1. Preferencias de UI (aisladas para nunca bloquear SQLite si el plugin falla en release/R8)
      try {
        _prefs = await SharedPreferences.getInstance();
        _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? _fluentReadingMode;
        _chapterReadingMode = _prefs?.getBool(_keyChapterMode) ?? _chapterReadingMode;
        _hebrewFontFamily = _prefs?.getString(_keyHebrewFont) ?? _hebrewFontFamily;
        _greekFontFamily = _prefs?.getString(_keyGreekFont) ?? _greekFontFamily;
        _readingFontScale = (_prefs?.getDouble(_keyFontScale) ?? _readingFontScale).clamp(0.85, 1.45);
        _lastSeenTourVersion = _prefs?.getString(_keyLastSeenTourVersion) ?? _lastSeenTourVersion;
        final tRaw = _prefs?.getString(_keyThemeMode);
        if (tRaw != null) {
          _themeMode = tRaw == 'light' ? ThemeMode.light : ThemeMode.dark;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[StudyService] SharedPreferences no disponible: $e');
      }

      // 2. Base de datos SQLite de usuario (completamente independiente de SharedPreferences)
      if (!kIsWeb) {
        final db = await _getDb();
        if (db != null) {
          await _migrateLegacySharedPreferences();
          await _loadAllFromDb();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error en initialize: $e');
    } finally {
      _initialized = true;
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
      notifyListeners();
    }
  }

  /// Devuelve una conexión activa a `logos_user_data.db`, reabriéndola si es necesario.
  Future<Database?> _getDb() async {
    if (kIsWeb || !_sqliteAvailable) return null;
    if (_userDb != null && _userDb!.isOpen) return _userDb;
    try {
      await _openUserDatabase();
    } on StateError catch (e) {
      // Entorno de pruebas host sin databaseFactory inicializado
      _sqliteAvailable = false;
      if (kDebugMode) debugPrint('[StudyService] SQLite no disponible en este entorno: $e');
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error reabriendo BD usuario: $e');
    }
    return _userDb;
  }

  /// Abre logos_user_data.db en el directorio estándar de bases de datos.
  ///
  /// NOTA: En sqflite (Android), PRAGMAs que retornan filas como `journal_mode`
  /// deben ejecutarse con `rawQuery` en `onOpen`, nunca con `execute` en `onConfigure`.
  /// Cada PRAGMA opcional está aislado en su propio `try/catch` para que ninguna
  /// restricción específica de dispositivo impida abrir o crear las tablas del usuario.
  Future<void> _openUserDatabase() async {
    final dbPath = join(await getDatabasesPath(), _userDbName);
    _userDb = await openDatabase(
      dbPath,
      version: _userDbVersion,
      onConfigure: (db) async {
        try {
          await db.execute('PRAGMA foreign_keys = ON');
        } catch (e) {
          if (kDebugMode) debugPrint('[StudyService] Ignorando PRAGMA foreign_keys: $e');
        }
      },
      onCreate: _createUserTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (kDebugMode) {
          debugPrint('[StudyService] Migrando BD usuario de v$oldVersion a v$newVersion');
        }
        await _createUserTables(db, newVersion);
      },
      onOpen: (db) async {
        // Garantizar siempre que las tablas e índices existan (auto-reparación si
        // una instancia previa creó el archivo de BD sin completar el esquema).
        await _createUserTables(db, _userDbVersion);
        try {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = FULL');
        } catch (e) {
          if (kDebugMode) debugPrint('[StudyService] Ignorando PRAGMA WAL/sync: $e');
        }
        if (kDebugMode) debugPrint('[StudyService] BD usuario lista en modo ACID WAL');
      },
    );
  }

  /// Crea las tablas de usuario si no existen (idempotente).
  /// Firma compatible con los callbacks onCreate/onUpgrade de sqflite.
  Future<void> _createUserTables(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_highlights (
        id            TEXT PRIMARY KEY,
        book_id       TEXT NOT NULL,
        book_name     TEXT NOT NULL,
        chapter       INTEGER NOT NULL,
        verse         INTEGER NOT NULL,
        color_key     TEXT NOT NULL,
        selected_text TEXT NOT NULL DEFAULT '',
        preview       TEXT NOT NULL,
        updated_at    TEXT NOT NULL
      )
    ''');

    // Índices para acelerar consultas ordenadas por fecha
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_visited ON user_history(visited_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_created ON user_bookmarks(created_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_highlights_updated ON user_highlights(updated_at DESC)');

    if (kDebugMode) debugPrint('[StudyService] Tablas de usuario creadas (v$version)');
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
    try {
      _bookmarks.clear();
      final bRows = await db.query('user_bookmarks');
      for (final row in bRows) {
        final b = BookmarkItem.fromMap(Map<String, dynamic>.from(row));
        if (b.id.isNotEmpty) _bookmarks[b.id] = b;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando marcadores: $e');
    }

    // Resaltados teológicos
    try {
      _highlights.clear();
      final hlRows = await db.query('user_highlights');
      for (final row in hlRows) {
        final hl = VerseHighlightItem.fromMap(Map<String, dynamic>.from(row));
        if (hl.id.isNotEmpty) _highlights[hl.id] = hl;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando resaltados: $e');
    }

    // Notas de versículos
    try {
      _verseNotes.clear();
      final vnRows = await db.query('user_verse_notes');
      for (final row in vnRows) {
        final vn = VerseNoteItem.fromMap(Map<String, dynamic>.from(row));
        if (vn.id.isNotEmpty) _verseNotes[vn.id] = vn;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando notas de versículo: $e');
    }

    // Notas Strong
    try {
      _strongNotes.clear();
      final snRows = await db.query('user_strong_notes');
      for (final row in snRows) {
        final sn = StrongNoteItem.fromMap(Map<String, dynamic>.from(row));
        if (sn.id.isNotEmpty) _strongNotes[sn.id] = sn;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando notas Strong: $e');
    }

    // Historial (ordenado por fecha de visita desc)
    try {
      _history.clear();
      final hRows = await db.query('user_history', orderBy: 'visited_at DESC', limit: 60);
      for (final row in hRows) {
        final h = HistoryItem.fromMap(Map<String, dynamic>.from(row));
        if (h.id.isNotEmpty) _history.add(h);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando historial: $e');
    }

    // Respaldo de preferencias UI desde SQLite (si SharedPreferences no tenía valor)
    try {
      final sRows = await db.query('user_settings');
      for (final row in sRows) {
        final k = row['key']?.toString();
        final v = row['value']?.toString();
        if (k == _keyFluentMode && _prefs?.getBool(_keyFluentMode) == null && v != null) {
          _fluentReadingMode = v == 'true';
        } else if (k == _keyChapterMode && _prefs?.getBool(_keyChapterMode) == null && v != null) {
          _chapterReadingMode = v == 'true';
        } else if (k == _keyHebrewFont && _prefs?.getString(_keyHebrewFont) == null && v != null) {
          _hebrewFontFamily = v;
        } else if (k == _keyGreekFont && _prefs?.getString(_keyGreekFont) == null && v != null) {
          _greekFontFamily = v;
        } else if (k == _keyFontScale && _prefs?.getDouble(_keyFontScale) == null && v != null) {
          final parsed = double.tryParse(v);
          if (parsed != null) _readingFontScale = parsed.clamp(0.85, 1.45);
        } else if (k == _keyThemeMode && _prefs?.getString(_keyThemeMode) == null && v != null) {
          _themeMode = v == 'light' ? ThemeMode.light : ThemeMode.dark;
        } else if (k == _keyLastSeenTourVersion && v != null && v.isNotEmpty) {
          if (_lastSeenTourVersion.isEmpty) {
            _lastSeenTourVersion = v;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error cargando ajustes UI: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Preferencias de UI (SharedPreferences + respaldo SQLite)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setFluentReadingMode(bool value) async {
    if (_fluentReadingMode == value) return;
    _fluentReadingMode = value;
    notifyListeners();
    try {
      await _prefs?.setBool(_keyFluentMode, value);
    } catch (_) {}
    await _saveUiSettingToDb(_keyFluentMode, value ? 'true' : 'false');
  }

  Future<void> setChapterReadingMode(bool value) async {
    if (_chapterReadingMode == value) return;
    _chapterReadingMode = value;
    notifyListeners();
    try {
      await _prefs?.setBool(_keyChapterMode, value);
    } catch (_) {}
    await _saveUiSettingToDb(_keyChapterMode, value ? 'true' : 'false');
  }

  Future<void> setHebrewFontFamily(String family) async {
    if (_hebrewFontFamily == family || family.isEmpty) return;
    _hebrewFontFamily = family;
    notifyListeners();
    try {
      await _prefs?.setString(_keyHebrewFont, family);
    } catch (_) {}
    await _saveUiSettingToDb(_keyHebrewFont, family);
  }

  Future<void> setGreekFontFamily(String family) async {
    if (_greekFontFamily == family || family.isEmpty) return;
    _greekFontFamily = family;
    notifyListeners();
    try {
      await _prefs?.setString(_keyGreekFont, family);
    } catch (_) {}
    await _saveUiSettingToDb(_keyGreekFont, family);
  }

  Future<void> setReadingFontScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.45);
    if ((_readingFontScale - clamped).abs() < 0.005) return;
    _readingFontScale = clamped;
    notifyListeners();
    try {
      await _prefs?.setDouble(_keyFontScale, clamped);
    } catch (_) {}
    await _saveUiSettingToDb(_keyFontScale, clamped.toStringAsFixed(2));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final modeStr = mode == ThemeMode.light ? 'light' : 'dark';
    try {
      await _prefs?.setString(_keyThemeMode, modeStr);
    } catch (_) {}
    await _saveUiSettingToDb(_keyThemeMode, modeStr);
  }

  Future<void> _saveUiSettingToDb(String key, String value) async {
    try {
      final db = await _getDb();
      if (db == null) return;
      await db.insert(
        'user_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  /// Registra de forma atómica que el usuario ya visualizó la guía interactiva
  /// correspondiente a [currentAppVersion], evitando que vuelva a mostrarse
  /// hasta una futura actualización de versión.
  Future<void> markVersionTourSeen(String currentAppVersion) async {
    final clean = currentAppVersion.trim();
    if (clean.isEmpty) return;
    _lastSeenTourVersion = clean;
    notifyListeners();
    try {
      await _prefs?.setString(_keyLastSeenTourVersion, clean);
    } catch (_) {}
    await _saveUiSettingToDb(_keyLastSeenTourVersion, clean);
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
      final db = await _getDb();
      if (db == null) return;
      await db.insert(
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
      final db = await _getDb();
      if (db == null) return;
      await db.delete('user_bookmarks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error eliminando marcador: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resaltados Teológicos (Highlighters) — CRUD SQLite
  // ─────────────────────────────────────────────────────────────────────────

  VerseHighlightItem? getVerseHighlight(String bookId, int chapter, int verse) {
    return _highlights[_verseKey(bookId, chapter, verse)];
  }

  /// Aplica o alterna un color de resaltado teológico sobre un versículo completo
  /// o sobre un fragmento seleccionado por el usuario.
  /// Retorna `true` si el resaltado quedó aplicado, o `false` si se quitó.
  Future<bool> applyVerseHighlight({
    required String bookId,
    required int chapter,
    required int verse,
    required String colorKey,
    required String preview,
    String? selectedFragment,
    bool toggleIfSameWholeVerse = true,
  }) async {
    final key = _verseKey(bookId, chapter, verse);
    final existing = _highlights[key];
    final cleanFragment = selectedFragment?.trim() ?? '';

    // Si el usuario pulsa el mismo color en modo versículo completo y ya estaba en ese color completo -> quitar
    if (cleanFragment.isEmpty &&
        toggleIfSameWholeVerse &&
        existing != null &&
        existing.colorKey == colorKey &&
        existing.isWholeVerse) {
      await removeVerseHighlight(bookId, chapter, verse);
      return false;
    }

    List<String> fragments = const [];
    if (cleanFragment.isNotEmpty) {
      if (existing != null && existing.colorKey == colorKey && !existing.isWholeVerse) {
        final nextList = List<String>.from(existing.selectedFragments);
        if (!nextList.any((f) => f.toLowerCase() == cleanFragment.toLowerCase())) {
          nextList.add(cleanFragment);
        }
        fragments = nextList;
      } else {
        fragments = [cleanFragment];
      }
    }

    final name = BookCatalog.nameById(bookId);
    final item = VerseHighlightItem(
      id: key,
      bookId: bookId,
      bookName: name.isNotEmpty ? name : bookId,
      chapter: chapter,
      verse: verse,
      colorKey: colorKey,
      selectedFragments: fragments,
      preview: preview,
      updatedAt: DateTime.now(),
    );

    _highlights[key] = item;
    notifyListeners();
    await _dbUpsertHighlight(item);
    return true;
  }

  Future<void> removeVerseHighlight(String bookId, int chapter, int verse) async {
    await removeHighlightById(_verseKey(bookId, chapter, verse));
  }

  Future<void> removeHighlightById(String key) async {
    if (_highlights.remove(key) != null) {
      notifyListeners();
      await _dbDeleteHighlight(key);
    }
  }

  Future<void> _dbUpsertHighlight(VerseHighlightItem item) async {
    try {
      final db = await _getDb();
      if (db == null) return;
      await db.insert(
        'user_highlights',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error guardando resaltado: $e');
    }
  }

  Future<void> _dbDeleteHighlight(String id) async {
    try {
      final db = await _getDb();
      if (db == null) return;
      await db.delete('user_highlights', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error eliminando resaltado: $e');
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
      final db = await _getDb();
      if (db == null) return;
      await db.insert(
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
      final db = await _getDb();
      if (db == null) return;
      await db.delete('user_verse_notes', where: 'id = ?', whereArgs: [id]);
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
      final db = await _getDb();
      if (db == null) return;
      await db.insert(
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
      final db = await _getDb();
      if (db == null) return;
      await db.delete('user_strong_notes', where: 'id = ?', whereArgs: [id]);
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
      final db = await _getDb();
      if (db == null) return;
      await db.delete('user_history');
    } catch (e) {
      if (kDebugMode) debugPrint('[StudyService] Error borrando historial: $e');
    }
  }

  Future<void> _dbUpsertHistory(HistoryItem item) async {
    try {
      final db = await _getDb();
      if (db == null) return;
      // REPLACE actualiza visited_at si ya existe el mismo id (deduplicación)
      await db.insert(
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
      final db = await _getDb();
      if (db == null) return;
      await db.execute('''
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
