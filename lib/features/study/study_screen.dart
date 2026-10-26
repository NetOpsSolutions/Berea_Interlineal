import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/study_service.dart';
import '../dictionary/strong_detail_screen.dart';

enum StudyNotesFilter {
  all,
  verses,
  strong,
}

class StudyScreen extends StatefulWidget {
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;
  final int initialIndex;
  final StudyNotesFilter initialNotesFilter;
  final String initialHighlightColorFilter;
  final GlobalKey? tourTabsKey;

  const StudyScreen({
    super.key,
    this.onOpenVerse,
    this.initialIndex = 0,
    this.initialNotesFilter = StudyNotesFilter.all,
    this.initialHighlightColorFilter = 'all',
    this.tourTabsKey,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StudyNotesFilter _notesFilter;
  late String _highlightFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 3),
    );
    _notesFilter = widget.initialNotesFilter;
    _highlightFilter = widget.initialHighlightColorFilter;
  }

  @override
  void didUpdateWidget(StudyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _tabController.animateTo(widget.initialIndex.clamp(0, 3));
    }
    if (oldWidget.initialNotesFilter != widget.initialNotesFilter) {
      setState(() {
        _notesFilter = widget.initialNotesFilter;
      });
    }
    if (oldWidget.initialHighlightColorFilter != widget.initialHighlightColorFilter) {
      setState(() {
        _highlightFilter = widget.initialHighlightColorFilter;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final bookmarks = StudyService.instance.bookmarks;
        final highlights = StudyService.instance.highlights;
        final verseNotes = StudyService.instance.verseNotes;
        final strongNotes = StudyService.instance.strongNotes;
        final history = StudyService.instance.history;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Estudio'),
            bottom: TabBar(
              key: widget.tourTabsKey,
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: const Icon(Icons.bookmark),
                  text: 'Marcadores (${bookmarks.length})',
                ),
                Tab(
                  icon: const Icon(Icons.palette_rounded),
                  text: 'Resaltados (${highlights.length})',
                ),
                Tab(
                  icon: const Icon(Icons.note_alt),
                  text: 'Notas (${verseNotes.length + strongNotes.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history),
                  text: 'Historial (${history.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBookmarksTab(bookmarks),
              _buildHighlightsTab(highlights),
              _buildNotesTab(verseNotes, strongNotes),
              _buildHistoryTab(history),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pestaña 1: MARCADORES
  // ---------------------------------------------------------------------------
  Widget _buildBookmarksTab(List<BookmarkItem> bookmarks) {
    final theme = Theme.of(context);
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'No tienes versículos en marcadores',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el ícono de marcador en cualquier versículo para guardarlo aquí y consultarlo rápidamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final b = bookmarks[i];
        return Dismissible(
          key: Key('bm_${b.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
          ),
          onDismissed: (_) {
            StudyService.instance.removeBookmark(b.id);
            AppSnackBar.show(
              context,
              icon: Icons.delete_outline,
              message: 'Marcador eliminado: ${b.bookName} ${b.chapter}:${b.verse}',
              duration: const Duration(seconds: 2),
            );
          },
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.bookmark, color: theme.colorScheme.onPrimaryContainer),
              ),
              title: Text(
                '${b.bookName} ${b.chapter}:${b.verse}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  b.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar marcador',
                onPressed: () => StudyService.instance.removeBookmark(b.id),
              ),
              onTap: () {
                if (widget.onOpenVerse != null) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  widget.onOpenVerse!(b.bookId, b.chapter, b.verse);
                }
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pestaña 2: RESALTADOS TEOLÓGICOS
  // ---------------------------------------------------------------------------
  Widget _buildHighlightsTab(List<VerseHighlightItem> allHighlights) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (allHighlights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette_outlined, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Aún no tienes versículos resaltados',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'En la lectura bíblica, toca un versículo o selecciona palabras para aplicar resaltadores teológicos (Promesas, Mandamientos, Atributos de Dios, Advertencias o Profecía).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = StudyService.instance.highlightsByColor(_highlightFilter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Todos (${allHighlights.length})'),
                  selected: _highlightFilter == 'all',
                  onSelected: (s) {
                    if (s) setState(() => _highlightFilter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ...TheologicalHighlightPalette.values.map((colorDef) {
                  final count = allHighlights.where((h) => h.colorKey == colorDef.key).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        radius: 7,
                        backgroundColor: colorDef.swatchColor,
                      ),
                      label: Text('${colorDef.label} ($count)'),
                      selected: _highlightFilter == colorDef.key,
                      onSelected: (s) {
                        if (s) setState(() => _highlightFilter = colorDef.key);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No hay versículos resaltados en esta categoría.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final hl = filtered[i];
                    final palette = TheologicalHighlightPalette.byKey(hl.colorKey) ??
                        TheologicalHighlightPalette.values.first;

                    return Dismissible(
                      key: Key('hl_${hl.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) {
                        StudyService.instance.removeHighlightById(hl.id);
                      },
                      child: Card(
                        color: palette.cardBackground(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: palette.borderColor(isDark), width: 1.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (widget.onOpenVerse != null) {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              widget.onOpenVerse!(hl.bookId, hl.chapter, hl.verse);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: palette.swatchColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${hl.bookName} ${hl.chapter}:${hl.verse}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: palette.swatchColor.withAlpha(isDark ? 65 : 40),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        palette.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline, size: 19),
                                      tooltip: 'Quitar resaltado',
                                      onPressed: () =>
                                          StudyService.instance.removeHighlightById(hl.id),
                                    ),
                                  ],
                                ),
                                if (!hl.isWholeVerse) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: hl.selectedFragments.map((frag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.inlineMarkerColor(isDark),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '«$frag»',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  hl.preview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pestaña 3: NOTAS PERSONALES
  // ---------------------------------------------------------------------------
  Widget _buildNotesTab(List<VerseNoteItem> verseNotes, List<StrongNoteItem> strongNotes) {
    final theme = Theme.of(context);
    final totalNotes = verseNotes.length + strongNotes.length;

    if (totalNotes == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Aún no tienes notas personales',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes añadir anotaciones teológicas o personales por versículo o por palabra Strong en el diccionario.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final showVerses =
        _notesFilter == StudyNotesFilter.all || _notesFilter == StudyNotesFilter.verses;
    final showStrong =
        _notesFilter == StudyNotesFilter.all || _notesFilter == StudyNotesFilter.strong;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.all_inbox, size: 16),
                  label: Text('Todas ($totalNotes)'),
                  selected: _notesFilter == StudyNotesFilter.all,
                  onSelected: (selected) {
                    if (selected) setState(() => _notesFilter = StudyNotesFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.menu_book, size: 16),
                  label: Text('En versículos (${verseNotes.length})'),
                  selected: _notesFilter == StudyNotesFilter.verses,
                  onSelected: (selected) {
                    if (selected) setState(() => _notesFilter = StudyNotesFilter.verses);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.translate, size: 16),
                  label: Text('En palabras Strong (${strongNotes.length})'),
                  selected: _notesFilter == StudyNotesFilter.strong,
                  onSelected: (selected) {
                    if (selected) setState(() => _notesFilter = StudyNotesFilter.strong);
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (showVerses && verseNotes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Notas en versículos (${verseNotes.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...verseNotes.map((vn) => _buildVerseNoteTile(vn, theme)),
                const SizedBox(height: 16),
              ],
              if (showStrong && strongNotes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Notas en palabras Strong (${strongNotes.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...strongNotes.map((sn) => _buildStrongNoteTile(sn, theme)),
              ],
              if ((_notesFilter == StudyNotesFilter.verses && verseNotes.isEmpty) ||
                  (_notesFilter == StudyNotesFilter.strong && strongNotes.isEmpty)) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _notesFilter == StudyNotesFilter.verses
                              ? Icons.menu_book_outlined
                              : Icons.translate_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _notesFilter == StudyNotesFilter.verses
                              ? 'No hay notas en versículos todavía'
                              : 'No hay notas en palabras Strong todavía',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _notesFilter == StudyNotesFilter.verses
                              ? 'Toca el ícono de nota en cualquier versículo para registrar tus comentarios.'
                              : 'Desde el diccionario o interlineal, toca "Nota personal" para registrar tu apunte léxico.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerseNoteTile(VerseNoteItem vn, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${vn.bookName} ${vn.chapter}:${vn.verse}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Editar nota',
                  onPressed: () => _editVerseNoteDialog(vn),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Eliminar nota',
                  onPressed: () => StudyService.instance.deleteVerseNote(
                    vn.bookId,
                    vn.chapter,
                    vn.verse,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vn.note,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (widget.onOpenVerse != null) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    widget.onOpenVerse!(vn.bookId, vn.chapter, vn.verse);
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Ver versículo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrongNoteTile(StrongNoteItem sn, ThemeData theme) {
    final isHebrew = sn.language == 'hebrew';
    final prefix = isHebrew ? 'H' : 'G';
    final langLabel = isHebrew ? 'Hebreo' : 'Griego';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$prefix${sn.code} ($langLabel)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Directionality(
                    textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(
                      sn.lemma,
                      style: StudyService.instance.originalScriptStyle(
                        isHebrew: isHebrew,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Editar nota',
                  onPressed: () => _editStrongNoteDialog(sn),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Eliminar nota',
                  onPressed: () => StudyService.instance.deleteStrongNote(
                    sn.language,
                    sn.code,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sn.note,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrongDetailScreen(
                        language: sn.language,
                        code: sn.code,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Abrir en diccionario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pestaña 4: HISTORIAL
  // ---------------------------------------------------------------------------
  Widget _buildHistoryTab(List<HistoryItem> history) {
    final theme = Theme.of(context);

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Sin historial reciente',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Cada versículo que leas o consultes se guardará aquí automáticamente para fácil referencia.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Referencias recientes (${history.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _confirmClearHistory,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Borrar historial'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final h = history[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.schedule, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: Text(
                    '${h.bookName} ${h.chapter}:${h.verse}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    h.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (widget.onOpenVerse != null) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      widget.onOpenVerse!(h.bookId, h.chapter, h.verse);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar historial?'),
        content: const Text('Se eliminarán todas las referencias bíblicas visitadas recientemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              StudyService.instance.clearHistory();
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _editVerseNoteDialog(VerseNoteItem vn) {
    final controller = TextEditingController(text: vn.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar nota: ${vn.bookName} ${vn.chapter}:${vn.verse}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe tu nota aquí...',
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
              StudyService.instance.saveVerseNote(
                bookId: vn.bookId,
                chapter: vn.chapter,
                verse: vn.verse,
                note: controller.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editStrongNoteDialog(StrongNoteItem sn) {
    final controller = TextEditingController(text: sn.note);
    final prefix = sn.language == 'hebrew' ? 'H' : 'G';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar nota: #$prefix${sn.code} (${sn.lemma})'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe tu nota aquí...',
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
                language: sn.language,
                code: sn.code,
                lemma: sn.lemma,
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
