import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'book_catalog.dart';

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
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'preview': preview,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BookmarkItem.fromMap(Map<String, dynamic> map) => BookmarkItem(
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
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VerseNoteItem.fromMap(Map<String, dynamic> map) => VerseNoteItem(
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
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StrongNoteItem.fromMap(Map<String, dynamic> map) => StrongNoteItem(
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
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'preview': preview,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory HistoryItem.fromMap(Map<String, dynamic> map) => HistoryItem(
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

class StudyService extends ChangeNotifier {
  static final StudyService instance = StudyService._();
  StudyService._();

  static const String _keyBookmarks = 'logos_bookmarks_v1';
  static const String _keyVerseNotes = 'logos_verse_notes_v1';
  static const String _keyStrongNotes = 'logos_strong_notes_v1';
  static const String _keyHistory = 'logos_history_v1';
  static const String _keyFluentMode = 'logos_fluent_mode_v1';
  static const String _keyThemeMode = 'logos_theme_mode_v1';

  bool _initialized = false;
  SharedPreferences? _prefs;

  final Map<String, BookmarkItem> _bookmarks = {};
  final Map<String, VerseNoteItem> _verseNotes = {};
  final Map<String, StrongNoteItem> _strongNotes = {};
  final List<HistoryItem> _history = [];
  bool _fluentReadingMode = false;
  ThemeMode _themeMode = ThemeMode.dark;

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

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();

      _fluentReadingMode = _prefs?.getBool(_keyFluentMode) ?? false;

      // Cargar modo de tema (predeterminado: oscuro)
      final tRaw = _prefs?.getString(_keyThemeMode);
      if (tRaw != null) {
        _themeMode = tRaw == 'light' ? ThemeMode.light : ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.dark; // Predeterminado oscuro
      }

      // Cargar marcadores
      final bRaw = _prefs?.getString(_keyBookmarks);
      if (bRaw != null && bRaw.isNotEmpty) {
        final list = jsonDecode(bRaw) as List;
        for (final item in list) {
          final b = BookmarkItem.fromMap(Map<String, dynamic>.from(item as Map));
          _bookmarks[b.id] = b;
        }
      }

      // Cargar notas de versículos
      final vnRaw = _prefs?.getString(_keyVerseNotes);
      if (vnRaw != null && vnRaw.isNotEmpty) {
        final list = jsonDecode(vnRaw) as List;
        for (final item in list) {
          final vn = VerseNoteItem.fromMap(Map<String, dynamic>.from(item as Map));
          _verseNotes[vn.id] = vn;
        }
      }

      // Cargar notas Strong
      final snRaw = _prefs?.getString(_keyStrongNotes);
      if (snRaw != null && snRaw.isNotEmpty) {
        final list = jsonDecode(snRaw) as List;
        for (final item in list) {
          final sn = StrongNoteItem.fromMap(Map<String, dynamic>.from(item as Map));
          _strongNotes[sn.id] = sn;
        }
      }

      // Cargar historial
      final hRaw = _prefs?.getString(_keyHistory);
      if (hRaw != null && hRaw.isNotEmpty) {
        final list = jsonDecode(hRaw) as List;
        for (final item in list) {
          final h = HistoryItem.fromMap(Map<String, dynamic>.from(item as Map));
          _history.add(h);
        }
        _history.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error inicializando StudyService: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Preferencias de lectura
  // ---------------------------------------------------------------------------
  Future<void> setFluentReadingMode(bool value) async {
    if (_fluentReadingMode == value) return;
    _fluentReadingMode = value;
    notifyListeners();
    await _prefs?.setBool(_keyFluentMode, value);
  }

  // ---------------------------------------------------------------------------
  // Preferencias de tema (oscuro / claro con persistencia)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Marcadores
  // ---------------------------------------------------------------------------
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
    bool added;
    if (_bookmarks.containsKey(key)) {
      _bookmarks.remove(key);
      added = false;
    } else {
      final name = BookCatalog.nameById(bookId);
      _bookmarks[key] = BookmarkItem(
        id: key,
        bookId: bookId,
        bookName: name.isNotEmpty ? name : bookId,
        chapter: chapter,
        verse: verse,
        preview: preview,
        createdAt: DateTime.now(),
      );
      added = true;
    }
    notifyListeners();
    await _persistBookmarks();
    return added;
  }

  Future<void> removeBookmark(String key) async {
    if (_bookmarks.remove(key) != null) {
      notifyListeners();
      await _persistBookmarks();
    }
  }

  Future<void> _persistBookmarks() async {
    try {
      final list = _bookmarks.values.map((e) => e.toMap()).toList();
      await _prefs?.setString(_keyBookmarks, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('Error persistiendo marcadores: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notas de versículos
  // ---------------------------------------------------------------------------
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
    _verseNotes[key] = VerseNoteItem(
      id: key,
      bookId: bookId,
      bookName: name.isNotEmpty ? name : bookId,
      chapter: chapter,
      verse: verse,
      note: text,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistVerseNotes();
  }

  Future<void> deleteVerseNote(String bookId, int chapter, int verse) async {
    final key = _verseKey(bookId, chapter, verse);
    if (_verseNotes.remove(key) != null) {
      notifyListeners();
      await _persistVerseNotes();
    }
  }

  Future<void> _persistVerseNotes() async {
    try {
      final list = _verseNotes.values.map((e) => e.toMap()).toList();
      await _prefs?.setString(_keyVerseNotes, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('Error persistiendo notas de versículos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notas Strong
  // ---------------------------------------------------------------------------
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
    _strongNotes[key] = StrongNoteItem(
      id: key,
      language: language,
      code: code,
      lemma: lemma,
      note: text,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistStrongNotes();
  }

  Future<void> deleteStrongNote(String language, int code) async {
    final key = _strongKey(language, code);
    if (_strongNotes.remove(key) != null) {
      notifyListeners();
      await _persistStrongNotes();
    }
  }

  Future<void> _persistStrongNotes() async {
    try {
      final list = _strongNotes.values.map((e) => e.toMap()).toList();
      await _prefs?.setString(_keyStrongNotes, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('Error persistiendo notas Strong: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Historial de navegación
  // ---------------------------------------------------------------------------
  Future<void> addToHistory({
    required String bookId,
    required int chapter,
    required int verse,
    required String preview,
  }) async {
    final key = _verseKey(bookId, chapter, verse);
    // Elimina duplicado anterior para moverlo al frente
    _history.removeWhere((h) => h.id == key);

    final name = BookCatalog.nameById(bookId);
    _history.insert(
      0,
      HistoryItem(
        id: key,
        bookId: bookId,
        bookName: name.isNotEmpty ? name : bookId,
        chapter: chapter,
        verse: verse,
        preview: preview,
        visitedAt: DateTime.now(),
      ),
    );

    // Mantener un máximo de 60 elementos recientes
    if (_history.length > 60) {
      _history.removeRange(60, _history.length);
    }

    notifyListeners();
    await _persistHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _prefs?.remove(_keyHistory);
  }

  Future<void> _persistHistory() async {
    try {
      final list = _history.map((e) => e.toMap()).toList();
      await _prefs?.setString(_keyHistory, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('Error persistiendo historial: $e');
    }
  }
}
