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
  final bool showExegesisSections;

  const StrongDetailScreen({
    super.key,
    required this.language,
    required this.code,
    this.showExegesisSections = true,
  });

  @override
  State<StrongDetailScreen> createState() => _StrongDetailScreenState();
}

class _StrongDetailScreenState extends State<StrongDetailScreen> {
  late Future<StrongEntry?> _entryFuture;
  late Future<List<Occurrence>> _occurrencesFuture;
  late Future<List<StrongRelationItem>> _relationsFuture;

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
    _relationsFuture =
        DatabaseService.instance.getStrongRelations(widget.language, widget.code);
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

                // Derivación con Hipervínculos a otros Strong y badge de Raíz Primaria
                _buildDerivationSection(entry, theme),

                // Definición Strong con Hipervínculos a otros Strong
                if (entry.definition.trim().isNotEmpty)
                  _Section(
                    title: 'Definición Strong',
                    icon: Icons.auto_stories_outlined,
                    child: LinkedStrongText(
                      text: entry.definition,
                      currentLanguage: widget.language,
                    ),
                  ),

                // Definición en RV con Hipervínculos a otros Strong
                if (entry.rvDefinition.trim().isNotEmpty)
                  _Section(
                    title: 'Definición en RV',
                    icon: Icons.translate_rounded,
                    child: LinkedStrongText(
                      text: entry.rvDefinition,
                      currentLanguage: widget.language,
                    ),
                  ),

                // Léxico STEPBible con Hipervínculos a otros Strong
                if (entry.stepbible.trim().isNotEmpty)
                  _Section(
                    title: 'Léxico Académico Extendido (STEPBible / Tyndale)',
                    icon: Icons.menu_book_rounded,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(100),
                        ),
                      ),
                      child: LinkedStrongText(
                        text: entry.stepbible,
                        currentLanguage: widget.language,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),

                // Relaciones Léxicas y Exegéticas (Similitudes + Familia de Palabras)
                if (widget.showExegesisSections)
                  FutureBuilder<List<StrongRelationItem>>(
                    future: _relationsFuture,
                    builder: (context, relSnapshot) {
                      final relations = relSnapshot.data ?? const <StrongRelationItem>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSimilaritiesSection(entry, relations, theme),
                          _buildDerivedFamilySection(relations, theme),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 8),

                // Sección "Dónde aparece": Acordeón desplegable con versículos completos y palabra resaltada
                FutureBuilder<List<Occurrence>>(
                  future: _occurrencesFuture,
                  builder: (context, occSnapshot) {
                    if (!occSnapshot.hasData || occSnapshot.data!.isEmpty) {
                      return const _Section(
                        title: 'Dónde aparece',
                        icon: Icons.format_list_numbered_rounded,
                        child: Text(
                          'Concordancia no cargada. Importa el dataset completo para ver ocurrencias por libro.',
                        ),
                      );
                    }

                    final occurrences = occSnapshot.data!;

                    return _Section(
                      title: 'Dónde aparece (Toca un libro para desplegar versículos)',
                      icon: Icons.format_list_numbered_rounded,
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

  Widget _buildDerivationSection(StrongEntry entry, ThemeData theme) {
    final raw = entry.derivation.trim();
    final isPrimaryRoot = raw.isEmpty ||
        raw.toLowerCase().contains('raíz prim') ||
        raw.toLowerCase().contains('palabra prim');

    if (isPrimaryRoot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Derivación',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(80),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Raíz primaria (no proviene de otra palabra bíblica)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _Section(
      title: 'Derivación',
      icon: Icons.account_tree_outlined,
      child: LinkedStrongText(
        text: entry.derivation,
        currentLanguage: widget.language,
      ),
    );
  }

  Widget _buildSimilaritiesSection(
    StrongEntry entry,
    List<StrongRelationItem> relations,
    ThemeData theme,
  ) {
    final compRelations = relations
        .where((r) => r.relationType == 'compares_with' || r.relationType == 'synonym')
        .toList();
    final hasNote = entry.similarities.trim().isNotEmpty;
    if (!hasNote && compRelations.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                'Similitudes y Comparaciones Teológicas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (compRelations.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: compRelations.map((rel) {
                final prefix = rel.language == 'hebrew' ? 'H' : 'G';
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StrongDetailScreen(
                          language: rel.language,
                          code: rel.code,
                          showExegesisSections: widget.showExegesisSections,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2218) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF78350F) : const Color(0xFFF59E0B),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$prefix${rel.code}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rel.lemma,
                          style: StudyService.instance.originalScriptStyle(
                            isHebrew: rel.language == 'hebrew',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                          ),
                        ),
                        if (rel.pronunciation.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${rel.pronunciation})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          if (hasNote)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF251C15) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF6B4826) : const Color(0xFFFDE68A),
                  width: 1.0,
                ),
              ),
              child: Text(
                entry.similarities,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF374151),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDerivedFamilySection(
    List<StrongRelationItem> relations,
    ThemeData theme,
  ) {
    final derived = relations.where((r) => r.relationType == 'parent_of').toList();
    if (derived.isEmpty) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nature_people_rounded, size: 20, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                'Familia de Palabras Derivadas (${derived.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: derived.map((rel) {
              final prefix = rel.language == 'hebrew' ? 'H' : 'G';
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrongDetailScreen(
                        language: rel.language,
                        code: rel.code,
                        showExegesisSections: widget.showExegesisSections,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132B20) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF047857) : const Color(0xFF6EE7B7),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$prefix${rel.code}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rel.lemma,
                        style: StudyService.instance.originalScriptStyle(
                          isHebrew: rel.language == 'hebrew',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B),
                        ),
                      ),
                      if (rel.pronunciation.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${rel.pronunciation})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
  final IconData? icon;

  const _Section({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
