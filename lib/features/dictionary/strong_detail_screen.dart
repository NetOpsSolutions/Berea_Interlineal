import 'package:flutter/material.dart';

import '../../data/book_catalog.dart';
import '../../data/database_service.dart';
import '../../data/models.dart';
import '../../data/study_service.dart';
import '../bible/bible_screen.dart';
import 'widgets/highlighted_verse_tile.dart';
import 'widgets/linked_strong_text.dart';

class StrongDetailScreen extends StatefulWidget {
  final String language;
  final int code;

  const StrongDetailScreen({
    super.key,
    required this.language,
    required this.code,
  });

  @override
  State<StrongDetailScreen> createState() => _StrongDetailScreenState();
}

class _StrongDetailScreenState extends State<StrongDetailScreen> {
  late Future<StrongEntry?> _entryFuture;
  late Future<List<Occurrence>> _occurrencesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _entryFuture =
        DatabaseService.instance.getStrong(widget.language, widget.code);
    _occurrencesFuture =
        DatabaseService.instance.getOccurrences(widget.language, widget.code);
  }

  String get _languageLabel =>
      widget.language == 'greek' ? 'griego' : 'hebreo';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = widget.language == 'hebrew' ? 'H' : 'G';

    return Scaffold(
      appBar: AppBar(
        title: Text('Strong $_languageLabel #$prefix${widget.code}'),
      ),
      body: FutureBuilder<StrongEntry?>(
        future: _entryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Entrada no encontrada.\n\n'
                  'Carga el dataset completo de diccionarios Strong para consultar esta palabra.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final entry = snapshot.data!;
          final isHebrew = entry.language == 'hebrew';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera con lema y pronunciación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Column(
                    children: [
                      Directionality(
                        textDirection:
                            isHebrew ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          entry.lemma,
                          textAlign: TextAlign.center,
                          style: StudyService.instance.originalScriptStyle(
                            isHebrew: isHebrew,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.pronunciation,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sección de Nota Personal
                ListenableBuilder(
                  listenable: StudyService.instance,
                  builder: (context, _) {
                    final note = StudyService.instance.getStrongNote(
                      widget.language,
                      widget.code,
                    );

                    return Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  note != null
                                      ? Icons.note_alt
                                      : Icons.note_alt_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nota personal',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                if (note != null) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Editar nota',
                                    onPressed: () => _editNoteDialog(entry, note.note),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    tooltip: 'Eliminar nota',
                                    onPressed: () => StudyService.instance.deleteStrongNote(
                                      widget.language,
                                      widget.code,
                                    ),
                                  ),
                                ] else
                                  FilledButton.tonalIcon(
                                    onPressed: () => _editNoteDialog(entry, ''),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Añadir nota'),
                                  ),
                              ],
                            ),
                            if (note != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                note.note,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Derivación con Hipervínculos a otros Strong
                _Section(
                  title: 'Derivación',
                  child: LinkedStrongText(
                    text: entry.derivation,
                    currentLanguage: widget.language,
                  ),
                ),

                // Definición Strong con Hipervínculos a otros Strong
                _Section(
                  title: 'Definición Strong',
                  child: LinkedStrongText(
                    text: entry.definition,
                    currentLanguage: widget.language,
                  ),
                ),

                // Definición en RV con Hipervínculos a otros Strong
                _Section(
                  title: 'Definición en RV',
                  child: LinkedStrongText(
                    text: entry.rvDefinition,
                    currentLanguage: widget.language,
                  ),
                ),

                // Léxico STEPBible con Hipervínculos a otros Strong
                _Section(
                  title: 'Léxico STEPBible',
                  child: LinkedStrongText(
                    text: entry.stepbible,
                    currentLanguage: widget.language,
                  ),
                ),

                const SizedBox(height: 16),

                // Sección "Dónde aparece": Acordeón desplegable con versículos completos y palabra resaltada
                FutureBuilder<List<Occurrence>>(
                  future: _occurrencesFuture,
                  builder: (context, occSnapshot) {
                    if (!occSnapshot.hasData || occSnapshot.data!.isEmpty) {
                      return const _Section(
                        title: 'Dónde aparece',
                        child: Text(
                          'Concordancia no cargada. Importa el dataset completo para ver ocurrencias por libro.',
                        ),
                      );
                    }

                    final occurrences = occSnapshot.data!;

                    return _Section(
                      title: 'Dónde aparece (Toca un libro para desplegar versículos)',
                      child: _OccurrencesAccordion(
                        occurrences: occurrences,
                        strongCode: widget.code,
                        language: widget.language,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editNoteDialog(StrongEntry entry, String initialText) {
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
}

class _OccurrencesAccordion extends StatelessWidget {
  final List<Occurrence> occurrences;
  final int strongCode;
  final String language;

  const _OccurrencesAccordion({
    required this.occurrences,
    required this.strongCode,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: occurrences.map((o) {
        return _BookExpansionTile(
          occurrence: o,
          strongCode: strongCode,
          language: language,
        );
      }).toList(),
    );
  }
}

class _BookExpansionTile extends StatefulWidget {
  final Occurrence occurrence;
  final int strongCode;
  final String language;

  const _BookExpansionTile({
    required this.occurrence,
    required this.strongCode,
    required this.language,
  });

  @override
  State<_BookExpansionTile> createState() => _BookExpansionTileState();
}

class _BookExpansionTileState extends State<_BookExpansionTile> {
  bool _loading = false;
  List<Verse>? _verses;

  Future<void> _loadVerses() async {
    if (_verses != null || _loading) return;
    setState(() => _loading = true);
    final list = await DatabaseService.instance.getVersesForStrong(
      widget.language,
      widget.strongCode,
      bookId: widget.occurrence.bookId,
    );
    if (mounted) {
      setState(() {
        _verses = list;
        _loading = false;
      });
    }
  }

  void _openVerse(BuildContext context, Verse v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('${BookCatalog.nameById(v.bookId)} ${v.chapter}:${v.verse}'),
          ),
          body: BibleScreen(
            initialBookId: v.bookId,
            initialChapter: v.chapter,
            initialVerse: v.verse,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = widget.occurrence;
    final bookName = BookCatalog.nameById(o.bookId);
    final suffix = o.occurrences > 0 ? ' • ${o.occurrences} vec.' : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              o.bookId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          title: Text(
            bookName,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${o.verses} versículos$suffix',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onExpansionChanged: (expanded) {
            if (expanded) {
              _loadVerses();
            }
          },
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_verses == null || _verses!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se pudieron cargar los versículos para este libro.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._verses!.map(
                (v) => HighlightedVerseTile(
                  verse: v,
                  strongCode: widget.strongCode,
                  language: widget.language,
                  onOpenVerse: (v) => _openVerse(context, v),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
