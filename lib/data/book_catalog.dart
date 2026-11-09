import 'models.dart';

class BookCatalog {
  static const List<Book> all = [
    Book(id: 'Gn', name: 'Génesis', testament: 1, chapters: 50),
    Book(id: 'Ex', name: 'Éxodo', testament: 1, chapters: 40),
    Book(id: 'Lv', name: 'Levítico', testament: 1, chapters: 27),
    Book(id: 'Nm', name: 'Números', testament: 1, chapters: 36),
    Book(id: 'Dt', name: 'Deuteronomio', testament: 1, chapters: 34),
    Book(id: 'Jos', name: 'Josué', testament: 1, chapters: 24),
    Book(id: 'Jue', name: 'Jueces', testament: 1, chapters: 21),
    Book(id: 'Rt', name: 'Rut', testament: 1, chapters: 4),
    Book(id: '1S', name: '1ra Samuel', testament: 1, chapters: 31),
    Book(id: '2S', name: '2da Samuel', testament: 1, chapters: 24),
    Book(id: '1R', name: '1ra Reyes', testament: 1, chapters: 22),
    Book(id: '2R', name: '2da Reyes', testament: 1, chapters: 25),
    Book(id: '1Cr', name: '1ra Crónicas', testament: 1, chapters: 29),
    Book(id: '2Cr', name: '2da Crónicas', testament: 1, chapters: 36),
    Book(id: 'Esd', name: 'Esdras', testament: 1, chapters: 10),
    Book(id: 'Neh', name: 'Nehemías', testament: 1, chapters: 13),
    Book(id: 'Est', name: 'Ester', testament: 1, chapters: 10),
    Book(id: 'Job', name: 'Job', testament: 1, chapters: 42),
    Book(id: 'Sal', name: 'Salmos', testament: 1, chapters: 150),
    Book(id: 'Pr', name: 'Proverbios', testament: 1, chapters: 31),
    Book(id: 'Ec', name: 'Eclesiastés', testament: 1, chapters: 12),
    Book(id: 'Cnt', name: 'Cantares', testament: 1, chapters: 8),
    Book(id: 'Is', name: 'Isaías', testament: 1, chapters: 66),
    Book(id: 'Jer', name: 'Jeremías', testament: 1, chapters: 52),
    Book(id: 'Lm', name: 'Lamentaciones', testament: 1, chapters: 5),
    Book(id: 'Ez', name: 'Ezequiel', testament: 1, chapters: 48),
    Book(id: 'Dn', name: 'Daniel', testament: 1, chapters: 12),
    Book(id: 'Os', name: 'Oseas', testament: 1, chapters: 14),
    Book(id: 'Jl', name: 'Joel', testament: 1, chapters: 3),
    Book(id: 'Am', name: 'Amós', testament: 1, chapters: 9),
    Book(id: 'Abd', name: 'Abdías', testament: 1, chapters: 1),
    Book(id: 'Jon', name: 'Jonás', testament: 1, chapters: 4),
    Book(id: 'Mi', name: 'Miqueas', testament: 1, chapters: 7),
    Book(id: 'Nah', name: 'Nahúm', testament: 1, chapters: 3),
    Book(id: 'Hab', name: 'Habacuc', testament: 1, chapters: 3),
    Book(id: 'Sof', name: 'Sofonías', testament: 1, chapters: 3),
    Book(id: 'Ha', name: 'Hageo', testament: 1, chapters: 1),
    Book(id: 'Zac', name: 'Zacarías', testament: 1, chapters: 14),
    Book(id: 'Mal', name: 'Malaquías', testament: 1, chapters: 4),
    Book(id: 'Mt', name: 'Mateo', testament: 2, chapters: 28),
    Book(id: 'Mr', name: 'Marcos', testament: 2, chapters: 16),
    Book(id: 'Lc', name: 'Lucas', testament: 2, chapters: 24),
    Book(id: 'Jn', name: 'Juan', testament: 2, chapters: 21),
    Book(id: 'Hch', name: 'Hechos', testament: 2, chapters: 28),
    Book(id: 'Ro', name: 'Romanos', testament: 2, chapters: 16),
    Book(id: '1Co', name: '1ra Corintios', testament: 2, chapters: 16),
    Book(id: '2Co', name: '2da Corintios', testament: 2, chapters: 13),
    Book(id: 'Ga', name: 'Gálatas', testament: 2, chapters: 6),
    Book(id: 'Ef', name: 'Efesios', testament: 2, chapters: 6),
    Book(id: 'Fil', name: 'Filipenses', testament: 2, chapters: 4),
    Book(id: 'Col', name: 'Colosenses', testament: 2, chapters: 4),
    Book(id: '1Ts', name: '1ra Tesalonicenses', testament: 2, chapters: 5),
    Book(id: '2Ts', name: '2da Tesalonicenses', testament: 2, chapters: 3),
    Book(id: '1Ti', name: '1ra Timoteo', testament: 2, chapters: 6),
    Book(id: '2Ti', name: '2da Timoteo', testament: 2, chapters: 4),
    Book(id: 'Tit', name: 'Tito', testament: 2, chapters: 3),
    Book(id: 'Flm', name: 'Filemón', testament: 2, chapters: 1),
    Book(id: 'He', name: 'Hebreos', testament: 2, chapters: 13),
    Book(id: 'Stg', name: 'Santiago', testament: 2, chapters: 5),
    Book(id: '1P', name: '1ra Pedro', testament: 2, chapters: 5),
    Book(id: '2P', name: '2da Pedro', testament: 2, chapters: 3),
    Book(id: '1Jn', name: '1ra Juan', testament: 2, chapters: 5),
    Book(id: '2Jn', name: '2da Juan', testament: 2, chapters: 1),
    Book(id: '3Jn', name: '3ra Juan', testament: 2, chapters: 1),
    Book(id: 'Jud', name: 'Judas', testament: 2, chapters: 1),
    Book(id: 'Ap', name: 'Apocalipsis', testament: 2, chapters: 22),
  ];

  static List<Book> byTestament(int t) => all.where((b) => b.testament == t).toList();
  
  static Book? byId(String id) {
    for (final b in all) {
      if (b.id.toLowerCase() == id.toLowerCase()) return b;
    }
    return null;
  }
  
  static String nameById(String id) => byId(id)?.name ?? id;

  static Book? findByNameOrId(String text) {
    final clean = _normalize(text);
    if (clean.isEmpty) return null;
    for (final b in all) {
      if (_normalize(b.id) == clean) return b;
      if (_normalize(b.name) == clean) return b;
    }
    for (final b in all) {
      final bn = _normalize(b.name);
      if (bn.startsWith(clean) || clean.startsWith(bn)) return b;
    }
    return null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('1ra', '1')
        .replaceAll('2da', '2')
        .replaceAll('3ra', '3')
        .replaceAll('primera', '1')
        .replaceAll('segunda', '2')
        .replaceAll('tercera', '3')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Analiza y normaliza una referencia textual bíblica en español
  /// (ej. 'Éxodo 3:4', '1 Samuel 16:7', 'Daniel 2:19-23') a sus coordenadas canónicas.
  static ScriptureReference? parseReference(String refStr, {String? defaultBookCode}) {
    final ref = refStr.trim();
    if (ref.isEmpty) return null;

    final match = RegExp(
      r'^(?:([1-3]?\s*[A-Za-zÁÉÍÓÚáéíóúñÑ]+)\s+)?(\d+)\s*:\s*(\d+)',
    ).firstMatch(ref);
    if (match == null) return null;

    final bName = match.group(1)?.trim();
    final ch = int.tryParse(match.group(2) ?? '1') ?? 1;
    final vs = int.tryParse(match.group(3) ?? '1') ?? 1;

    if (bName != null && bName.isNotEmpty) {
      final book = findByNameOrId(bName);
      if (book != null) {
        return ScriptureReference(
          bookId: book.id,
          bookName: book.name,
          chapter: ch,
          verse: vs,
          rawText: ref,
        );
      }
    }

    if (defaultBookCode != null) {
      final book = byId(defaultBookCode);
      if (book != null) {
        return ScriptureReference(
          bookId: book.id,
          bookName: book.name,
          chapter: ch,
          verse: vs,
          rawText: ref,
        );
      }
    }

    return null;
  }

  /// Descompone cadenas compuestas con múltiples pasajes separados por ';'
  /// (ej. 'Hechos 12:12; 1 Pedro 5:13', 'Daniel 1:8; 2:19-23') heredando
  /// el libro canónico contextual si no se especifica explícitamente en partes subsiguientes.
  static List<ScriptureReference> parseMultiReferences(String text, {String? fallbackBookCode}) {
    final results = <ScriptureReference>[];
    String? currentBookCode = fallbackBookCode;
    final parts = text.split(';').map((p) => p.trim()).where((p) => p.isNotEmpty);

    for (final part in parts) {
      final parsed = parseReference(part, defaultBookCode: currentBookCode);
      if (parsed != null) {
        results.add(parsed);
        currentBookCode = parsed.bookId;
      }
    }
    return results;
  }
}

/// Representa una referencia bíblica canónica normalizada
class ScriptureReference {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String rawText;

  const ScriptureReference({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.rawText,
  });

  @override
  String toString() => '$bookName $chapter:$verse';
}
