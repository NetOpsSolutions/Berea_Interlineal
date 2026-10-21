import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/book_catalog.dart';
import '../../data/database_service.dart';
import '../../data/models.dart';
import '../../data/parsing_decoder.dart';
import '../../data/study_service.dart';
import '../dictionary/strong_detail_screen.dart';
import '../dictionary/widgets/linked_strong_text.dart';

class BibleScreen extends StatefulWidget {
  final String? initialBookId;
  final int? initialChapter;
  final int? initialVerse;

  const BibleScreen({
    super.key,
    this.initialBookId,
    this.initialChapter,
    this.initialVerse,
  });

  @override
  State<BibleScreen> createState() => BibleScreenState();
}

class BibleScreenState extends State<BibleScreen> {
  int _testament = 1;
  String _bookId = 'Gn';
  int _chapter = 1;
  int _verse = 1;
  int _maxVerse = 1;
  Verse? _currentVerse;
  bool _loading = false;
  bool _fluentMode = false;

  final List<TapGestureRecognizer> _recognizers = [];

  Book get _book => BookCatalog.byId(_bookId) ?? BookCatalog.all.first;

  @override
  void initState() {
    super.initState();
    _fluentMode = StudyService.instance.fluentReadingMode;

    if (widget.initialBookId != null) {
      final b = BookCatalog.byId(widget.initialBookId!);
      if (b != null) {
        _testament = b.testament;
        _bookId = b.id;
        _chapter = widget.initialChapter ?? 1;
        _verse = widget.initialVerse ?? 1;
      }
    }
    _load();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// Método público para navegar directamente desde Búsqueda, Marcadores o Historial
  void goToVerse(String bookId, int chapter, int verse) {
    final b = BookCatalog.byId(bookId);
    if (b == null) return;
    setState(() {
      _testament = b.testament;
      _bookId = b.id;
      _chapter = chapter;
      _verse = verse;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final max = await DatabaseService.instance.getMaxVerse(_bookId, _chapter);
    setState(() {
      _maxVerse = max < 1 ? 1 : max;
      if (_verse > _maxVerse) _verse = _maxVerse;
    });

    final v = await DatabaseService.instance.getVerse(_bookId, _chapter, _verse);
    if (mounted) {
      setState(() {
        _currentVerse = v;
        _loading = false;
      });

      if (v != null) {
        StudyService.instance.addToHistory(
          bookId: _bookId,
          chapter: _chapter,
          verse: _verse,
          preview: v.translation,
        );
      }
    }
  }

  void _onTest(int? v) {
    if (v == null) return;
    final bs = BookCatalog.byTestament(v);
    setState(() {
      _testament = v;
      _bookId = bs.first.id;
      _chapter = 1;
      _verse = 1;
    });
    _load();
  }

  void _onBook(String? v) {
    if (v == null) return;
    setState(() {
      _bookId = v;
      _chapter = 1;
      _verse = 1;
    });
    _load();
  }

  void _onChap(int? v) {
    if (v == null) return;
    setState(() {
      _chapter = v;
      _verse = 1;
    });
    _load();
  }

  void _onVerse(int? v) {
    if (v == null) return;
    setState(() => _verse = v);
    _load();
  }

  void _prevVerse() {
    if (_verse > 1) {
      setState(() => _verse--);
      _load();
    } else if (_chapter > 1) {
      setState(() {
        _chapter--;
        _verse = 1; // se ajustará a maxVerse en _load()
      });
      _load();
    }
  }

  void _nextVerse() {
    if (_verse < _maxVerse) {
      setState(() => _verse++);
      _load();
    } else if (_chapter < _book.chapters) {
      setState(() {
        _chapter++;
        _verse = 1;
      });
      _load();
    }
  }

  void _toggleFluentMode() {
    setState(() {
      _fluentMode = !_fluentMode;
    });
    StudyService.instance.setFluentReadingMode(_fluentMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_fluentMode
            ? 'Modo lectura fluida activado'
            : 'Modo interlineal activado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    if (_currentVerse == null) return;
    final added = await StudyService.instance.toggleBookmark(
      bookId: _bookId,
      chapter: _chapter,
      verse: _verse,
      preview: _currentVerse!.translation,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added
            ? 'Versículo guardado en Marcadores'
            : 'Marcador eliminado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editVerseNoteDialog() {
    final existing = StudyService.instance.getVerseNote(_bookId, _chapter, _verse);
    final controller = TextEditingController(text: existing?.note ?? '');
    final ref = '${BookCatalog.nameById(_bookId)} $_chapter:$_verse';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nota personal: $ref'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe aquí tus observaciones, reflexiones teológicas o notas...',
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                StudyService.instance.deleteVerseNote(_bookId, _chapter, _verse);
              },
              style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Eliminar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              StudyService.instance.saveVerseNote(
                bookId: _bookId,
                chapter: _chapter,
                verse: _verse,
                note: controller.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sheet(WordToken w) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => WordDetailSheet(word: w),
      );

  @override
  Widget build(BuildContext context) {
    final books = BookCatalog.byTestament(_testament);
    final isHe = _book.testament == 1;

    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final isBookmarked = StudyService.instance.isBookmarked(_bookId, _chapter, _verse);
        final verseNote = StudyService.instance.getVerseNote(_bookId, _chapter, _verse);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Biblia Interlineal'),
            actions: [
              // Botón de alternar Modo Lectura Fluida / Interlineal
              IconButton(
                icon: Icon(
                  _fluentMode ? Icons.view_headline : Icons.auto_stories,
                  color: _fluentMode ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: _fluentMode ? 'Cambiar a modo interlineal' : 'Cambiar a lectura fluida',
                onPressed: _toggleFluentMode,
              ),

              // Botón de Marcador favorito
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: isBookmarked ? 'Quitar de marcadores' : 'Guardar en marcadores',
                onPressed: _toggleBookmark,
              ),

              // Botón de Nota personal
              IconButton(
                icon: Icon(
                  verseNote != null ? Icons.note_alt : Icons.note_alt_outlined,
                  color: verseNote != null ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: 'Nota personal del versículo',
                onPressed: _editVerseNoteDialog,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de pasaje
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey('test_$_testament'),
                                  initialValue: _testament,
                                  decoration: const InputDecoration(labelText: 'Testamento'),
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('Antiguo')),
                                    DropdownMenuItem(value: 2, child: Text('Nuevo')),
                                  ],
                                  onChanged: _onTest,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('book_$_bookId'),
                                  initialValue: _bookId,
                                  decoration: const InputDecoration(labelText: 'Libro'),
                                  items: books
                                      .map((b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Text(b.name),
                                          ))
                                      .toList(),
                                  onChanged: _onBook,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey('chap_$_chapter'),
                                  initialValue: _chapter,
                                  decoration: const InputDecoration(labelText: 'Capítulo'),
                                  items: List.generate(
                                    _book.chapters,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                  onChanged: _onChap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  key: ValueKey('verse_$_verse'),
                                  initialValue: _verse,
                                  decoration: const InputDecoration(labelText: 'Versículo'),
                                  items: List.generate(
                                    _maxVerse,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                  onChanged: _onVerse,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barra de navegación rápida entre versículos
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: (_verse > 1 || _chapter > 1) ? _prevVerse : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Anterior'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _fluentMode
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _fluentMode ? 'Modo Lectura Fluida' : 'Modo Interlineal',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _fluentMode
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : null,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: (_verse < _maxVerse || _chapter < _book.chapters)
                              ? _nextVerse
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          iconAlignment: IconAlignment.end,
                          label: const Text('Siguiente'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Vista principal del versículo
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _currentVerse == null
                            ? _Empty(onRetry: _load)
                            : _VerseView(
                                verse: _currentVerse!,
                                isHebrew: isHe,
                                fluentMode: _fluentMode,
                                verseNote: verseNote?.note,
                                onWordTap: _sheet,
                                onEditNote: _editVerseNoteDialog,
                                registerRecognizer: (r) => _recognizers.add(r),
                                clearRecognizers: _clearRecognizers,
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onRetry;
  const _Empty({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 64),
            const SizedBox(height: 12),
            const Text(
              'No hay versículo cargado para esta referencia.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

class _VerseView extends StatelessWidget {
  final Verse verse;
  final bool isHebrew;
  final bool fluentMode;
  final String? verseNote;
  final ValueChanged<WordToken> onWordTap;
  final VoidCallback onEditNote;
  final void Function(TapGestureRecognizer) registerRecognizer;
  final VoidCallback clearRecognizers;

  const _VerseView({
    required this.verse,
    required this.isHebrew,
    required this.fluentMode,
    required this.verseNote,
    required this.onWordTap,
    required this.onEditNote,
    required this.registerRecognizer,
    required this.clearRecognizers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = '${BookCatalog.nameById(verse.bookId)} ${verse.chapter}:${verse.verse}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la referencia
          Text(ref, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Tarjeta de Nota Personal si existe
          if (verseNote != null && verseNote!.isNotEmpty) ...[
            Card(
              color: theme.colorScheme.secondaryContainer.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Nota personal',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          tooltip: 'Editar nota',
                          onPressed: onEditNote,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(verseNote!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (fluentMode) ...[
            // ---------------------------------------------------------------
            // MODO LECTURA FLUIDA:
            // Ocultar interlineal y mostrar solo texto español
            // Palabras Strong subrayadas discretamente
            // ---------------------------------------------------------------
            _buildFluentReadingCard(context, theme),
            const SizedBox(height: 16),
            _buildStrongChipsSection(context, theme),
          ] else ...[
            // ---------------------------------------------------------------
            // MODO INTERLINEAL COMPLETO
            // ---------------------------------------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  verse.translation,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Interlineal', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Directionality(
              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
              child: Wrap(
                spacing: 10,
                runSpacing: 14,
                children: verse.words
                    .map((w) => _Tile(
                          word: w,
                          rtl: isHebrew,
                          onTap: () => onWordTap(w),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFluentReadingCard(BuildContext context, ThemeData theme) {
    clearRecognizers();

    // Palabras con código Strong
    final wordsWithStrong = verse.words.where((w) => w.strongCode != null).toList();

    // Separamos el texto de la traducción en tokens
    final text = verse.translation;
    final regex = RegExp(r'(\s+|[.,;:\(\)¡!¿?«»"—]+)');
    final matches = regex.allMatches(text);

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        final wordStr = text.substring(lastEnd, match.start);
        spans.add(_createWordSpan(wordStr, wordsWithStrong, theme));
      }
      // Puntuación o espacio
      final punctStr = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: punctStr,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.8,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final wordStr = text.substring(lastEnd);
      spans.add(_createWordSpan(wordStr, wordsWithStrong, theme));
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Texto en español',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Toca una palabra subrayada para ver su definición Strong',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText.rich(
              TextSpan(children: spans),
            ),
          ],
        ),
      ),
    );
  }

  InlineSpan _createWordSpan(
    String wordStr,
    List<WordToken> strongWords,
    ThemeData theme,
  ) {
    final clean = wordStr.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), '');
    WordToken? matchedToken;

    if (clean.isNotEmpty) {
      for (final w in strongWords) {
        final wClean = w.translation.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), '');
        if (wClean == clean || (wClean.isNotEmpty && clean.contains(wClean)) || (clean.isNotEmpty && wClean.contains(clean))) {
          matchedToken = w;
          break;
        }
      }
    }

    if (matchedToken != null) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => onWordTap(matchedToken!);
      registerRecognizer(recognizer);

      return TextSpan(
        text: wordStr,
        recognizer: recognizer,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.8,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: theme.colorScheme.primary,
        ),
      );
    }

    return TextSpan(
      text: wordStr,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.8,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStrongChipsSection(BuildContext context, ThemeData theme) {
    final strongWords = verse.words.where((w) => w.strongCode != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.translate, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Términos Strong en este versículo (${strongWords.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: strongWords.map((w) {
            final prefix = w.language == 'hebrew' ? 'H' : 'G';
            return ActionChip(
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  prefix,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              label: Text(
                '#$prefix${w.strongCode}: ${w.surface} (${w.translation})',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => onWordTap(w),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final WordToken word;
  final bool rtl;
  final VoidCallback onTap;

  const _Tile({required this.word, required this.rtl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.colorScheme.outlineVariant),
          color: t.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                word.surface,
                textAlign: TextAlign.center,
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              word.translation,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordDetailSheet extends StatefulWidget {
  final WordToken word;
  const WordDetailSheet({super.key, required this.word});

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  StrongEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.word.strongCode == null) {
      setState(() => _loading = false);
      return;
    }
    final e = await DatabaseService.instance.getStrong(
      widget.word.language,
      widget.word.strongCode!,
    );
    if (mounted) {
      setState(() {
        _entry = e;
        _loading = false;
      });
    }
  }

  void _editStrongNoteDialog(StrongEntry entry, String initialText) {
    final controller = TextEditingController(text: initialText);
    final prefix = entry.language == 'hebrew' ? 'H' : 'G';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nota Strong: #$prefix${entry.code} (${entry.lemma})'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe tu anotación personal o léxica aquí...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              StudyService.instance.saveStrongNote(
                language: entry.language,
                code: entry.code,
                lemma: entry.lemma,
                note: controller.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isHe = widget.word.language == 'hebrew';

    return SafeArea(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Detalle de Palabra', style: t.textTheme.titleLarge),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: t.colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: isHe ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        widget.word.surface,
                        textAlign: TextAlign.center,
                        style: t.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.word.translation,
                      style: t.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Row(
                label: 'Código Strong',
                value: widget.word.strongCode != null
                    ? '${isHe ? "H" : "G"}${widget.word.strongCode}'
                    : '—',
              ),
              _Row(label: 'Lema', value: widget.word.lemma, rtl: isHe),
              _Row(label: 'Parsing', value: widget.word.parsing),
              _Row(
                label: 'Análisis',
                value: ParsingDecoder.decode(widget.word.parsing, widget.word.language),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const LinearProgressIndicator()
              else if (_entry != null) ...[
                Text('Definición', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinkedStrongText(
                  text: _entry!.definition,
                  currentLanguage: widget.word.language,
                ),
                const SizedBox(height: 16),

                // Nota personal para esta palabra Strong
                ListenableBuilder(
                  listenable: StudyService.instance,
                  builder: (context, _) {
                    final strongNote = StudyService.instance.getStrongNote(
                      widget.word.language,
                      widget.word.strongCode!,
                    );

                    return Card(
                      color: t.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  strongNote != null ? Icons.note_alt : Icons.note_alt_outlined,
                                  size: 18,
                                  color: t.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nota personal',
                                  style: t.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: t.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                if (strongNote != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    onPressed: () => _editStrongNoteDialog(_entry!, strongNote.note),
                                  )
                                else
                                  TextButton.icon(
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('Añadir nota'),
                                    onPressed: () => _editStrongNoteDialog(_entry!, ''),
                                  ),
                              ],
                            ),
                            if (strongNote != null) ...[
                              const SizedBox(height: 4),
                              Text(strongNote.note, style: t.textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrongDetailScreen(
                        language: widget.word.language,
                        code: widget.word.strongCode!,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.book_outlined),
                  label: const Text('Abrir en diccionario completo'),
                ),
              ] else
                Text(
                  'Entrada del diccionario no cargada todavía.',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool rtl;
  const _Row({required this.label, required this.value, this.rtl = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: t.textTheme.labelLarge?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(value, style: t.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
