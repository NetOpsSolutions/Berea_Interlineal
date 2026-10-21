class Book {
  final String id;
  final String name;
  final int testament;
  final int chapters;
  const Book({required this.id, required this.name, required this.testament, required this.chapters});
  factory Book.fromMap(Map<String, Object?> m) => Book(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        testament: (m['testament'] as int?) ?? 0,
        chapters: (m['chapters'] as int?) ?? 0,
      );
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'testament': testament, 'chapters': chapters};
}

class Verse {
  final int id;
  final String bookId;
  final int chapter;
  final int verse;
  final String translation;
  final List<WordToken> words;
  const Verse({required this.id, required this.bookId, required this.chapter, required this.verse,
      required this.translation, required this.words});
}

class WordToken {
  final int id;
  final int verseId;
  final int position;
  final int? strongCode;
  final String language;
  final String lemma;
  final String surface;
  final String parsing;
  final String translation;
  const WordToken({required this.id, required this.verseId, required this.position, required this.strongCode,
      required this.language, required this.lemma, required this.surface, required this.parsing,
      required this.translation});
  factory WordToken.fromMap(Map<String, Object?> m) => WordToken(
        id: (m['id'] as int?) ?? 0,
        verseId: (m['verse_id'] as int?) ?? 0,
        position: (m['position'] as int?) ?? 0,
        strongCode: m['strong_code'] as int?,
        language: (m['language'] as String?) ?? '',
        lemma: (m['lemma'] as String?) ?? '',
        surface: (m['surface'] as String?) ?? '',
        parsing: (m['parsing'] as String?) ?? '',
        translation: (m['translation'] as String?) ?? '',
      );
}

class StrongEntry {
  final String language;
  final int code;
  final String lemma;
  final String pronunciation;
  final String derivation;
  final String definition;
  final String rvDefinition;
  final String stepbible;
  const StrongEntry({required this.language, required this.code, required this.lemma,
      required this.pronunciation, required this.derivation, required this.definition,
      required this.rvDefinition, required this.stepbible});
  factory StrongEntry.fromMap(Map<String, Object?> m) => StrongEntry(
        language: (m['language'] as String?) ?? '',
        code: (m['code'] as int?) ?? 0,
        lemma: (m['lemma'] as String?) ?? '',
        pronunciation: (m['pronunciation'] as String?) ?? '',
        derivation: (m['derivation'] as String?) ?? '',
        definition: (m['definition'] as String?) ?? '',
        rvDefinition: (m['rv_definition'] as String?) ?? '',
        stepbible: (m['stepbible'] as String?) ?? '',
      );
  Map<String, Object?> toMap() => {'language': language, 'code': code, 'lemma': lemma,
      'pronunciation': pronunciation, 'derivation': derivation, 'definition': definition,
      'rv_definition': rvDefinition, 'stepbible': stepbible};
}

class Occurrence {
  final String language;
  final int strongCode;
  final String bookId;
  final int verses;
  final int occurrences;
  const Occurrence({required this.language, required this.strongCode, required this.bookId,
      required this.verses, required this.occurrences});
  factory Occurrence.fromMap(Map<String, Object?> m) => Occurrence(
        language: (m['language'] as String?) ?? '',
        strongCode: (m['strong_code'] as int?) ?? 0,
        bookId: (m['book_id'] as String?) ?? '',
        verses: (m['verses'] as int?) ?? 0,
        occurrences: (m['occurrences'] as int?) ?? 0,
      );
}

class VerseSearchResult {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String translation;

  const VerseSearchResult({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.translation,
  });

  String get reference => '$bookName $chapter:$verse';
}

class GlobalSearchResult {
  final String query;
  final VerseSearchResult? directReference;
  final List<VerseSearchResult> verses;
  final List<StrongEntry> greekEntries;
  final List<StrongEntry> hebrewEntries;

  const GlobalSearchResult({
    required this.query,
    this.directReference,
    required this.verses,
    required this.greekEntries,
    required this.hebrewEntries,
  });

  int get totalCount =>
      (directReference != null ? 1 : 0) +
      verses.length +
      greekEntries.length +
      hebrewEntries.length;

  bool get isEmpty => totalCount == 0;
}
