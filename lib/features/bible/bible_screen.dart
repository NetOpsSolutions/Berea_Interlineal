import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
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

  List<Verse> _chapterVerses = [];
  Verse? _currentVerse;
  int? _expandedVerseNumber;
  bool _forceShowInterlinearInExpanded = false;
  bool _loading = false;

  final ScrollController _chapterScrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  final GlobalKey tourAppBarActionsKey = GlobalKey(debugLabel: 'tourAppBarActions');
  final GlobalKey tourSingleVerseKey = GlobalKey(debugLabel: 'tourSingleVerse');

  GlobalKey? get tourActiveVerseKey {
    if (StudyService.instance.chapterReadingMode) {
      return _chapterVerses.isNotEmpty ? _keyForVerse(_chapterVerses.first.verse) : null;
    }
    return tourSingleVerseKey;
  }

  /// Prepara el Paso 1 de la guía visual desplegando el primer versículo del capítulo
  /// para mostrar en vivo el interlineal Hebreo/Griego, código Strong y resaltadores.
  Future<void> prepareForInteractiveTourStep1() async {
    if (!mounted) return;
    if (_chapterScrollController.hasClients) {
      await _chapterScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    if (_chapterVerses.isNotEmpty) {
      setState(() {
        _expandedVerseNumber = _chapterVerses.first.verse;
        _forceShowInterlinearInExpanded = true;
      });
    }
  }

  Book get _book => BookCatalog.byId(_bookId) ?? BookCatalog.all.first;

  @override
  void initState() {
    super.initState();

    if (widget.initialBookId != null) {
      final b = BookCatalog.byId(widget.initialBookId!);
      if (b != null) {
        _testament = b.testament;
        _bookId = b.id;
        _chapter = widget.initialChapter ?? 1;
        _verse = widget.initialVerse ?? 1;
        _expandedVerseNumber = widget.initialVerse;
      }
    }
    _load(scrollToTargetVerse: widget.initialVerse != null);
  }

  @override
  void dispose() {
    _chapterScrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForVerse(int verseNum) {
    return _verseKeys.putIfAbsent(verseNum, () => GlobalKey());
  }

  /// Método público para navegar directamente desde Búsqueda, Marcadores, Resaltados o Historial
  void goToVerse(String bookId, int chapter, int verse) {
    final b = BookCatalog.byId(bookId);
    if (b == null) return;
    setState(() {
      _testament = b.testament;
      _bookId = b.id;
      _chapter = chapter;
      _verse = verse;
      _expandedVerseNumber = verse;
      _forceShowInterlinearInExpanded = false;
    });
    _load(scrollToTargetVerse: true);
  }

  Future<void> _load({bool scrollToTargetVerse = false, bool scrollToTop = false}) async {
    setState(() => _loading = true);

    final verses = await DatabaseService.instance.getChapterVerses(_bookId, _chapter);
    if (!mounted) return;

    int maxV = verses.isNotEmpty ? verses.last.verse : 1;
    if (verses.isEmpty) {
      maxV = await DatabaseService.instance.getMaxVerse(_bookId, _chapter);
      if (!mounted) return;
    }

    final clampedVerse = _verse.clamp(1, maxV < 1 ? 1 : maxV);
    Verse? activeVerse;
    for (final v in verses) {
      if (v.verse == clampedVerse) {
        activeVerse = v;
        break;
      }
    }
    activeVerse ??= verses.isNotEmpty
        ? verses.first
        : await DatabaseService.instance.getVerse(_bookId, _chapter, clampedVerse);

    if (!mounted) return;

    // Limpiar claves antiguas si cambió el tamaño del capítulo
    _verseKeys.removeWhere((k, _) => k > maxV);

    setState(() {
      _chapterVerses = verses;
      _maxVerse = maxV < 1 ? 1 : maxV;
      _verse = clampedVerse;
      _currentVerse = activeVerse;
      _loading = false;
    });

    if (activeVerse != null) {
      StudyService.instance.addToHistory(
        bookId: _bookId,
        chapter: _chapter,
        verse: activeVerse.verse,
        preview: activeVerse.translation,
      );
    }

    if (scrollToTargetVerse) {
      _scrollToVerse(_verse);
    } else if (scrollToTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chapterScrollController.hasClients) {
          _chapterScrollController.jumpTo(0);
        }
      });
    }
  }

  void _scrollToVerse(int targetVerse) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _verseKeys[targetVerse];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  bool get _hasPrevChapter {
    if (_chapter > 1) return true;
    final idx = BookCatalog.all.indexWhere((b) => b.id == _bookId);
    return idx > 0;
  }

  bool get _hasNextChapter {
    if (_chapter < _book.chapters) return true;
    final idx = BookCatalog.all.indexWhere((b) => b.id == _bookId);
    return idx >= 0 && idx < BookCatalog.all.length - 1;
  }

  void _prevChapter() {
    if (!_hasPrevChapter) return;
    HapticFeedback.selectionClick();
    if (_chapter > 1) {
      setState(() {
        _chapter--;
        _verse = 1;
        _expandedVerseNumber = null;
      });
      _load(scrollToTop: true);
    } else {
      final idx = BookCatalog.all.indexWhere((b) => b.id == _bookId);
      if (idx > 0) {
        final prevBook = BookCatalog.all[idx - 1];
        setState(() {
          _testament = prevBook.testament;
          _bookId = prevBook.id;
          _chapter = prevBook.chapters;
          _verse = 1;
          _expandedVerseNumber = null;
        });
        _load(scrollToTop: true);
      }
    }
  }

  void _nextChapter() {
    if (!_hasNextChapter) return;
    HapticFeedback.selectionClick();
    if (_chapter < _book.chapters) {
      setState(() {
        _chapter++;
        _verse = 1;
        _expandedVerseNumber = null;
      });
      _load(scrollToTop: true);
    } else {
      final idx = BookCatalog.all.indexWhere((b) => b.id == _bookId);
      if (idx >= 0 && idx < BookCatalog.all.length - 1) {
        final nextBook = BookCatalog.all[idx + 1];
        setState(() {
          _testament = nextBook.testament;
          _bookId = nextBook.id;
          _chapter = 1;
          _verse = 1;
          _expandedVerseNumber = null;
        });
        _load(scrollToTop: true);
      }
    }
  }

  void _prevVerse() {
    if (_verse > 1) {
      setState(() {
        _verse--;
        _currentVerse = _chapterVerses.where((v) => v.verse == _verse).firstOrNull ?? _currentVerse;
      });
      if (_currentVerse != null && _currentVerse!.verse == _verse) {
        StudyService.instance.addToHistory(
          bookId: _bookId,
          chapter: _chapter,
          verse: _verse,
          preview: _currentVerse!.translation,
        );
      } else {
        _load();
      }
    } else if (_hasPrevChapter) {
      _prevChapter();
    }
  }

  void _nextVerse() {
    if (_verse < _maxVerse) {
      setState(() {
        _verse++;
        _currentVerse = _chapterVerses.where((v) => v.verse == _verse).firstOrNull ?? _currentVerse;
      });
      if (_currentVerse != null && _currentVerse!.verse == _verse) {
        StudyService.instance.addToHistory(
          bookId: _bookId,
          chapter: _chapter,
          verse: _verse,
          preview: _currentVerse!.translation,
        );
      } else {
        _load();
      }
    } else if (_hasNextChapter) {
      _nextChapter();
    }
  }

  void _handleHorizontalSwipe(DragEndDetails details, bool isChapterMode) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 320) return;

    if (velocity < 0) {
      // Deslizar hacia la izquierda -> Siguiente
      isChapterMode ? _nextChapter() : _nextVerse();
    } else {
      // Deslizar hacia la derecha -> Anterior
      isChapterMode ? _prevChapter() : _prevVerse();
    }
  }

  void _toggleChapterMode() {
    final next = !StudyService.instance.chapterReadingMode;
    StudyService.instance.setChapterReadingMode(next);
    AppSnackBar.show(
      context,
      icon: next ? Icons.menu_book_rounded : Icons.center_focus_strong_rounded,
      message: next
          ? 'Vista de capítulo completo activada'
          : 'Vista por versículo individual activada',
      duration: const Duration(seconds: 2),
    );
    if (next) {
      _scrollToVerse(_verse);
    }
  }

  void _toggleFluentMode() {
    final next = !StudyService.instance.fluentReadingMode;
    StudyService.instance.setFluentReadingMode(next);
    AppSnackBar.show(
      context,
      icon: next ? Icons.auto_stories_rounded : Icons.translate_rounded,
      message: next
          ? 'Modo lectura fluida activado'
          : 'Modo estudio interlineal activado',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _toggleBookmarkForVerse(Verse v) async {
    final added = await StudyService.instance.toggleBookmark(
      bookId: v.bookId,
      chapter: v.chapter,
      verse: v.verse,
      preview: v.translation,
    );
    if (!mounted) return;
    AppSnackBar.show(
      context,
      icon: added ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
      tone: added ? AppSnackBarTone.success : AppSnackBarTone.info,
      message: added
          ? '${BookCatalog.nameById(v.bookId)} ${v.chapter}:${v.verse} guardado en Marcadores'
          : 'Marcador eliminado',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _applyHighlightForVerse(
    Verse v,
    String colorKey, {
    String? selectedFragment,
  }) async {
    HapticFeedback.lightImpact();
    final applied = await StudyService.instance.applyVerseHighlight(
      bookId: v.bookId,
      chapter: v.chapter,
      verse: v.verse,
      colorKey: colorKey,
      preview: v.translation,
      selectedFragment: selectedFragment,
    );
    if (!mounted) return;
    final paletteItem = TheologicalHighlightPalette.byKey(colorKey);
    if (applied && paletteItem != null) {
      AppSnackBar.show(
        context,
        icon: paletteItem.icon,
        message: selectedFragment != null && selectedFragment.trim().isNotEmpty
            ? 'Texto resaltado como "${paletteItem.label}"'
            : '${BookCatalog.nameById(v.bookId)} ${v.chapter}:${v.verse} resaltado (${paletteItem.label})',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _copyVerseToClipboard(Verse v) async {
    final ref = '${BookCatalog.nameById(v.bookId)} ${v.chapter}:${v.verse}';
    await Clipboard.setData(ClipboardData(text: '«${v.translation}» — $ref (RV1960)'));
    if (!mounted) return;
    AppSnackBar.show(
      context,
      icon: Icons.copy_rounded,
      tone: AppSnackBarTone.success,
      message: '$ref copiado al portapapeles',
      duration: const Duration(seconds: 2),
    );
  }

  void _editVerseNoteDialog(Verse v) {
    final existing = StudyService.instance.getVerseNote(v.bookId, v.chapter, v.verse);
    final controller = TextEditingController(text: existing?.note ?? '');
    final ref = '${BookCatalog.nameById(v.bookId)} ${v.chapter}:${v.verse}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nota personal: $ref'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe aquí tus observaciones, exégesis o reflexiones teológicas...',
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                StudyService.instance.deleteVerseNote(v.bookId, v.chapter, v.verse);
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
                bookId: v.bookId,
                chapter: v.chapter,
                verse: v.verse,
                note: controller.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPassagePicker() async {
    final selected = await showModalBottomSheet<({String bookId, int chapter, int verse})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PassagePickerSheet(
        initialBookId: _bookId,
        initialChapter: _chapter,
        initialVerse: _verse,
        initialMaxVerse: _maxVerse,
      ),
    );

    if (selected != null && mounted) {
      goToVerse(selected.bookId, selected.chapter, selected.verse);
    }
  }

  void _openAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReaderAppearanceSheet(),
    );
  }

  Future<void> _openWordSheet(WordToken w) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WordDetailSheet(word: w),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHebrew = _book.testament == 1;

    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final chapterMode = StudyService.instance.chapterReadingMode;
        final fluentMode = StudyService.instance.fluentReadingMode;
        final activeSingleVerse = _currentVerse;
        final singleBookmarked = activeSingleVerse != null &&
            StudyService.instance.isBookmarked(
              activeSingleVerse.bookId,
              activeSingleVerse.chapter,
              activeSingleVerse.verse,
            );
        final singleNote = activeSingleVerse != null
            ? StudyService.instance.getVerseNote(
                activeSingleVerse.bookId,
                activeSingleVerse.chapter,
                activeSingleVerse.verse,
              )
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              chapterMode ? '${_book.name} $_chapter' : 'Biblia Interlineal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              Row(
                key: tourAppBarActionsKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      chapterMode ? Icons.menu_book_rounded : Icons.looks_one_outlined,
                      color: chapterMode ? theme.colorScheme.primary : null,
                    ),
                    tooltip: chapterMode
                        ? 'Cambiar a vista de versículo único'
                        : 'Cambiar a lectura por capítulo completo',
                    onPressed: _toggleChapterMode,
                  ),
                  IconButton(
                    icon: Icon(
                      fluentMode ? Icons.auto_stories_rounded : Icons.translate_rounded,
                      color: fluentMode ? theme.colorScheme.primary : null,
                    ),
                    tooltip: fluentMode
                        ? 'Modo lectura fluida activo (pulsa para modo interlineal)'
                        : 'Modo interlineal activo (pulsa para lectura fluida)',
                    onPressed: _toggleFluentMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_fields_rounded),
                    tooltip: 'Tipografías académicas y tamaño de letra',
                    onPressed: _openAppearanceSheet,
                  ),
                ],
              ),
              if (!chapterMode && activeSingleVerse != null) ...[
                IconButton(
                  icon: Icon(
                    singleBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: singleBookmarked ? theme.colorScheme.primary : null,
                  ),
                  tooltip: 'Marcador',
                  onPressed: () => _toggleBookmarkForVerse(activeSingleVerse),
                ),
                IconButton(
                  icon: Icon(
                    singleNote != null ? Icons.note_alt : Icons.note_alt_outlined,
                    color: singleNote != null ? theme.colorScheme.primary : null,
                  ),
                  tooltip: 'Nota del versículo',
                  onPressed: () => _editVerseNoteDialog(activeSingleVerse),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra compacta de navegación de pasaje y capítulo
                _buildPassageHeaderBar(theme, chapterMode, fluentMode),

                // Área principal de lectura con soporte de gestos swipe laterales
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (d) => _handleHorizontalSwipe(d, chapterMode),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : chapterMode
                            ? (_chapterVerses.isEmpty
                                ? _Empty(onRetry: _load)
                                : _buildChapterReadingView(theme, isHebrew, fluentMode))
                            : (activeSingleVerse == null
                                ? _Empty(onRetry: _load)
                                : Padding(
                                    key: tourSingleVerseKey,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _SingleVerseView(
                                      verse: activeSingleVerse,
                                      isHebrew: isHebrew,
                                      fluentMode: fluentMode,
                                      verseNote: singleNote?.note,
                                      highlight: StudyService.instance.getVerseHighlight(
                                        activeSingleVerse.bookId,
                                        activeSingleVerse.chapter,
                                        activeSingleVerse.verse,
                                      ),
                                      onWordTap: _openWordSheet,
                                      onEditNote: () => _editVerseNoteDialog(activeSingleVerse),
                                      onApplyHighlight: (colorKey, {selectedFragment}) =>
                                          _applyHighlightForVerse(
                                        activeSingleVerse,
                                        colorKey,
                                        selectedFragment: selectedFragment,
                                      ),
                                      onClearHighlight: () => StudyService.instance
                                          .removeVerseHighlight(
                                        activeSingleVerse.bookId,
                                        activeSingleVerse.chapter,
                                        activeSingleVerse.verse,
                                      ),
                                    ),
                                  )),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassageHeaderBar(ThemeData theme, bool chapterMode, bool fluentMode) {
    final testamentLabel = _testament == 1 ? 'AT • Hebreo' : 'NT • Griego';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
        ),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            onPressed: chapterMode ? (_hasPrevChapter ? _prevChapter : null) : _prevVerse,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: chapterMode ? 'Capítulo anterior' : 'Versículo anterior',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _openPassagePicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(180),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 17,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        chapterMode
                            ? '${_book.name} $_chapter  (1–$_maxVerse)'
                            : '${_book.name} $_chapter:$_verse',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        testamentLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            onPressed: chapterMode ? (_hasNextChapter ? _nextChapter : null) : _nextVerse,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: chapterMode ? 'Capítulo siguiente' : 'Versículo siguiente',
          ),
        ],
      ),
    );
  }

  Widget _buildChapterReadingView(ThemeData theme, bool isHebrew, bool fluentMode) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: SingleChildScrollView(
        key: ValueKey('chap_scroll_${_bookId}_$_chapter'),
        controller: _chapterScrollController,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera editorial del capítulo
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_book.name} — Capítulo $_chapter',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toca un versículo para expandir su análisis interlineal y resaltadores • Desliza a los lados para cambiar de capítulo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista continua de versículos del capítulo
            ..._chapterVerses.map((v) {
              final isExpanded = _expandedVerseNumber == v.verse;
              final isBookmarked = StudyService.instance.isBookmarked(v.bookId, v.chapter, v.verse);
              final noteItem = StudyService.instance.getVerseNote(v.bookId, v.chapter, v.verse);
              final highlightItem =
                  StudyService.instance.getVerseHighlight(v.bookId, v.chapter, v.verse);

              return Container(
                key: _keyForVerse(v.verse),
                child: _ChapterVerseBlock(
                  verse: v,
                  isHebrew: isHebrew,
                  fluentMode: fluentMode,
                  isExpanded: isExpanded,
                  forceShowInterlinear: isExpanded && _forceShowInterlinearInExpanded,
                  isBookmarked: isBookmarked,
                  noteText: noteItem?.note,
                  highlight: highlightItem,
                  onToggleExpand: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_expandedVerseNumber == v.verse) {
                        _expandedVerseNumber = null;
                        _forceShowInterlinearInExpanded = false;
                      } else {
                        _expandedVerseNumber = v.verse;
                        _verse = v.verse;
                        _currentVerse = v;
                        _forceShowInterlinearInExpanded = false;
                      }
                    });
                    StudyService.instance.addToHistory(
                      bookId: v.bookId,
                      chapter: v.chapter,
                      verse: v.verse,
                      preview: v.translation,
                    );
                  },
                  onRequestShowInterlinear: () {
                    setState(() {
                      _forceShowInterlinearInExpanded = !_forceShowInterlinearInExpanded;
                    });
                  },
                  onWordTap: _openWordSheet,
                  onToggleBookmark: () => _toggleBookmarkForVerse(v),
                  onEditNote: () => _editVerseNoteDialog(v),
                  onCopyVerse: () => _copyVerseToClipboard(v),
                  onApplyHighlight: (colorKey, {selectedFragment}) => _applyHighlightForVerse(
                    v,
                    colorKey,
                    selectedFragment: selectedFragment,
                  ),
                  onClearHighlight: () =>
                      StudyService.instance.removeVerseHighlight(v.bookId, v.chapter, v.verse),
                ),
              );
            }),

            const SizedBox(height: 18),

            // Botones inferiores de navegación rápida entre capítulos
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasPrevChapter ? _prevChapter : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Cap. Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _hasNextChapter ? _nextChapter : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Cap. Siguiente'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque individual de versículo dentro de la Lectura por Capítulo Completo
class _ChapterVerseBlock extends StatefulWidget {
  final Verse verse;
  final bool isHebrew;
  final bool fluentMode;
  final bool isExpanded;
  final bool forceShowInterlinear;
  final bool isBookmarked;
  final String? noteText;
  final VerseHighlightItem? highlight;
  final VoidCallback onToggleExpand;
  final VoidCallback onRequestShowInterlinear;
  final ValueChanged<WordToken> onWordTap;
  final VoidCallback onToggleBookmark;
  final VoidCallback onEditNote;
  final VoidCallback onCopyVerse;
  final void Function(String colorKey, {String? selectedFragment}) onApplyHighlight;
  final VoidCallback onClearHighlight;

  const _ChapterVerseBlock({
    required this.verse,
    required this.isHebrew,
    required this.fluentMode,
    required this.isExpanded,
    required this.forceShowInterlinear,
    required this.isBookmarked,
    required this.noteText,
    required this.highlight,
    required this.onToggleExpand,
    required this.onRequestShowInterlinear,
    required this.onWordTap,
    required this.onToggleBookmark,
    required this.onEditNote,
    required this.onCopyVerse,
    required this.onApplyHighlight,
    required this.onClearHighlight,
  });

  @override
  State<_ChapterVerseBlock> createState() => _ChapterVerseBlockState();
}

class _ChapterVerseBlockState extends State<_ChapterVerseBlock> {
  final List<TapGestureRecognizer> _recognizers = [];

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

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scale = StudyService.instance.readingFontScale;
    final hlColor = TheologicalHighlightPalette.byKey(widget.highlight?.colorKey);
    final isWholeHighlight = widget.highlight != null && widget.highlight!.isWholeVerse;

    Color bgColor = Colors.transparent;
    if (isWholeHighlight && hlColor != null) {
      bgColor = hlColor.cardBackground(isDark);
    } else if (widget.isExpanded) {
      bgColor = theme.colorScheme.surfaceContainerLow;
    }

    final borderColor = widget.isExpanded
        ? (hlColor?.borderColor(isDark) ?? theme.colorScheme.primary)
        : (hlColor != null ? hlColor.borderColor(isDark).withAlpha(140) : Colors.transparent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.symmetric(vertical: widget.isExpanded ? 6 : 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: widget.isExpanded ? 1.5 : (hlColor != null ? 1.0 : 0.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, widget.isExpanded ? 10 : 7, 10, widget.isExpanded ? 12 : 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de texto del versículo + número interactivo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insignia numérica del versículo (tocar expande/contrae panel interlineal)
                InkWell(
                  onTap: widget.onToggleExpand,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    margin: const EdgeInsets.only(top: 3, right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isExpanded
                          ? theme.colorScheme.primary
                          : (hlColor != null
                              ? hlColor.swatchColor.withAlpha(isDark ? 90 : 50)
                              : theme.colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.verse.verse}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w800,
                        color: widget.isExpanded
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Cuerpo del versículo con resaltado y selección contextual
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onToggleExpand,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVerseRichText(context, theme, isDark, scale, hlColor),
                        if (hlColor != null ||
                            widget.isBookmarked ||
                            (widget.noteText != null && widget.noteText!.isNotEmpty)) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hlColor != null)
                                _TinyBadge(
                                  icon: hlColor.icon,
                                  label: hlColor.label,
                                  color: hlColor.borderColor(isDark),
                                ),
                              if (widget.isBookmarked)
                                _TinyBadge(
                                  icon: Icons.bookmark_rounded,
                                  label: 'Marcador',
                                  color: theme.colorScheme.primary,
                                ),
                              if (widget.noteText != null && widget.noteText!.isNotEmpty)
                                _TinyBadge(
                                  icon: Icons.edit_note_rounded,
                                  label: 'Nota',
                                  color: theme.colorScheme.tertiary,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botón sutil para expandir/contraer herramientas e interlineal
                InkWell(
                  onTap: widget.onToggleExpand,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      widget.isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 18,
                      color: widget.isExpanded
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(150),
                    ),
                  ),
                ),
              ],
            ),

            // Bloque expandible con Resaltadores Teológicos + Acciones + Interlineal Académico
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.isExpanded
                  ? _buildExpandedPanel(context, theme, isDark, hlColor)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseRichText(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    double scale,
    TheologicalHighlightColor? hlColor,
  ) {
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 17.5 * scale,
      height: 1.65,
      color: theme.colorScheme.onSurface,
    );

    final fragments = widget.highlight?.selectedFragments ?? const <String>[];
    final spans = _buildFormattedSpans(
      text: widget.verse.translation,
      words: widget.verse.words,
      fluentMode: widget.fluentMode,
      baseStyle: baseStyle!,
      theme: theme,
      isDark: isDark,
      highlightColor: hlColor,
      highlightedFragments: fragments,
      onWordTap: widget.onWordTap,
      registerRecognizer: (r) => _recognizers.add(r),
    );

    return SelectableText.rich(
      TextSpan(children: spans),
      contextMenuBuilder: (ctx, editableState) {
        return _TheologicalSelectionToolbar(
          editableTextState: editableState,
          onSelectColor: (colorKey, selectedStr) {
            widget.onApplyHighlight(colorKey, selectedFragment: selectedStr);
            editableState.hideToolbar();
          },
        );
      },
    );
  }

  Widget _buildExpandedPanel(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    TheologicalHighlightColor? activeHl,
  ) {
    final showInterlinear = !widget.fluentMode || widget.forceShowInterlinear;
    final strongWords = widget.verse.words.where((w) => w.strongCode != null).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),

          // 1. Paleta de Resaltadores Teológicos (5 colores + borrar)
          _TheologicalPaletteBar(
            activeColorKey: widget.highlight?.colorKey,
            onSelectColor: (key) => widget.onApplyHighlight(key),
            onClear: widget.highlight != null ? widget.onClearHighlight : null,
          ),

          const SizedBox(height: 10),

          // 2. Barra de herramientas rápida del versículo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(widget.isBookmarked ? 'Guardado' : 'Marcador'),
                  onPressed: widget.onToggleBookmark,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    widget.noteText != null ? Icons.note_alt : Icons.note_alt_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(widget.noteText != null ? 'Editar nota' : 'Añadir nota'),
                  onPressed: widget.onEditNote,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.copy_rounded, size: 15, color: theme.colorScheme.primary),
                  label: const Text('Copiar'),
                  onPressed: widget.onCopyVerse,
                ),
                if (widget.fluentMode) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      showInterlinear ? Icons.visibility_off_outlined : Icons.translate_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(showInterlinear ? 'Ocultar interlineal' : 'Ver interlineal'),
                    onPressed: widget.onRequestShowInterlinear,
                  ),
                ],
              ],
            ),
          ),

          // 3. Nota personal del versículo (si existe)
          if (widget.noteText != null && widget.noteText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withAlpha(110),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.noteText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 4. Bloque Interlineal Académico o Chips Strong
          if (showInterlinear && widget.verse.words.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.translate_rounded, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  widget.isHebrew
                      ? 'Interlineal Hebreo BHS (lectura derecha a izquierda ←)'
                      : 'Interlineal Griego Koiné (Tischendorf →)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: widget.isHebrew ? TextDirection.rtl : TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: widget.verse.words
                    .map((w) => _InterlinearWordTile(
                          word: w,
                          isHebrew: widget.isHebrew,
                          onTap: () => widget.onWordTap(w),
                        ))
                    .toList(),
              ),
            ),
          ] else if (strongWords.isNotEmpty) ...[
            _StrongChipsWrap(
              strongWords: strongWords,
              isHebrew: widget.isHebrew,
              onWordTap: widget.onWordTap,
            ),
          ],
        ],
      ),
    );
  }
}

/// Construye spans enriquecidos combinando subrayados Strong discretos y resaltados de texto seleccionado
List<InlineSpan> _buildFormattedSpans({
  required String text,
  required List<WordToken> words,
  required bool fluentMode,
  required TextStyle baseStyle,
  required ThemeData theme,
  required bool isDark,
  required TheologicalHighlightColor? highlightColor,
  required List<String> highlightedFragments,
  required ValueChanged<WordToken> onWordTap,
  required void Function(TapGestureRecognizer) registerRecognizer,
}) {
  // Marcar rangos de caracteres resaltados parcialmente (si existen fragmentos específicos)
  final highlightedMask = List<bool>.filled(text.length, false);
  if (highlightColor != null && highlightedFragments.isNotEmpty) {
    final lowerText = text.toLowerCase();
    for (final frag in highlightedFragments) {
      final cleanFrag = frag.trim().toLowerCase();
      if (cleanFrag.isEmpty) continue;
      int searchFrom = 0;
      while (true) {
        final idx = lowerText.indexOf(cleanFrag, searchFrom);
        if (idx < 0) break;
        for (int i = idx; i < idx + cleanFrag.length && i < text.length; i++) {
          highlightedMask[i] = true;
        }
        searchFrom = idx + cleanFrag.length;
      }
    }
  }

  final strongWords = words.where((w) => w.strongCode != null).toList();
  final regex = RegExp(r'(\s+|[.,;:\(\)¡!¿?«»"—]+)');
  final matches = regex.allMatches(text);

  final spans = <InlineSpan>[];
  int lastEnd = 0;

  TextStyle applyMask(TextStyle s, int start, int end) {
    if (highlightColor == null || highlightedFragments.isEmpty) return s;
    bool anyHighlighted = false;
    for (int i = start; i < end && i < highlightedMask.length; i++) {
      if (highlightedMask[i]) {
        anyHighlighted = true;
        break;
      }
    }
    if (!anyHighlighted) return s;
    return s.copyWith(
      backgroundColor: highlightColor.inlineMarkerColor(isDark),
      fontWeight: FontWeight.w600,
    );
  }

  InlineSpan buildWordSpan(String wordStr, int start, int end) {
    WordToken? matchedToken;
    if (fluentMode && strongWords.isNotEmpty) {
      final clean = wordStr.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), '');
      if (clean.length > 2) {
        for (final w in strongWords) {
          final wClean = w.translation.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), '');
          if (wClean == clean ||
              (wClean.length > 2 && clean.contains(wClean)) ||
              (clean.length > 2 && wClean.contains(clean))) {
            matchedToken = w;
            break;
          }
        }
      }
    }

    if (matchedToken != null) {
      final recognizer = TapGestureRecognizer()..onTap = () => onWordTap(matchedToken!);
      registerRecognizer(recognizer);
      return TextSpan(
        text: wordStr,
        recognizer: recognizer,
        style: applyMask(
          baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: theme.colorScheme.primary.withAlpha(190),
          ),
          start,
          end,
        ),
      );
    }

    return TextSpan(
      text: wordStr,
      style: applyMask(baseStyle, start, end),
    );
  }

  for (final match in matches) {
    if (match.start > lastEnd) {
      spans.add(buildWordSpan(text.substring(lastEnd, match.start), lastEnd, match.start));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: applyMask(baseStyle, match.start, match.end),
    ));
    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(buildWordSpan(text.substring(lastEnd), lastEnd, text.length));
  }

  return spans;
}

/// Menú contextual al seleccionar texto con soporte de los 5 resaltadores teológicos + Copiar
class _TheologicalSelectionToolbar extends StatelessWidget {
  final EditableTextState editableTextState;
  final void Function(String colorKey, String selectedText) onSelectColor;

  const _TheologicalSelectionToolbar({
    required this.editableTextState,
    required this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = editableTextState.textEditingValue;
    final selectedText = value.selection.isValid && !value.selection.isCollapsed
        ? value.selection.textInside(value.text).trim()
        : '';

    final anchors = editableTextState.contextMenuAnchors;

    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (ctx, child) => Material(
        elevation: 6,
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...TheologicalHighlightPalette.values.map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: 'Resaltar: ${c.label}',
                      child: InkWell(
                        onTap: () {
                          if (selectedText.isNotEmpty) {
                            onSelectColor(c.key, selectedText);
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c.swatchColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    editableTextState.copySelection(SelectionChangedCause.toolbar);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Barra horizontal con los 5 colores de resaltado teológico
class _TheologicalPaletteBar extends StatelessWidget {
  final String? activeColorKey;
  final ValueChanged<String> onSelectColor;
  final VoidCallback? onClear;

  const _TheologicalPaletteBar({
    required this.activeColorKey,
    required this.onSelectColor,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeItem = TheologicalHighlightPalette.byKey(activeColorKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                activeItem != null
                    ? 'Resaltado: ${activeItem.label} (${activeItem.meaning})'
                    : 'Resaltador teológico (toca un color o selecciona palabras):',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: activeItem != null ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...TheologicalHighlightPalette.values.map((item) {
                final isSelected = item.key == activeColorKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onSelectColor(item.key),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: item.swatchColor.withAlpha(isSelected ? 55 : 24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? item.swatchColor
                              : item.swatchColor.withAlpha(110),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.swatchColor,
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 9, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (onClear != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Quitar resaltado',
                  onPressed: onClear,
                  icon: Icon(
                    Icons.format_color_reset_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TinyBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
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
              'No hay versículos cargados para esta referencia.',
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

/// Vista enfocada de Versículo Individual (preservada y enriquecida con Fase 3)
class _SingleVerseView extends StatefulWidget {
  final Verse verse;
  final bool isHebrew;
  final bool fluentMode;
  final String? verseNote;
  final VerseHighlightItem? highlight;
  final ValueChanged<WordToken> onWordTap;
  final VoidCallback onEditNote;
  final void Function(String colorKey, {String? selectedFragment}) onApplyHighlight;
  final VoidCallback onClearHighlight;

  const _SingleVerseView({
    required this.verse,
    required this.isHebrew,
    required this.fluentMode,
    required this.verseNote,
    required this.highlight,
    required this.onWordTap,
    required this.onEditNote,
    required this.onApplyHighlight,
    required this.onClearHighlight,
  });

  @override
  State<_SingleVerseView> createState() => _SingleVerseViewState();
}

class _SingleVerseViewState extends State<_SingleVerseView> {
  final List<TapGestureRecognizer> _recognizers = [];

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

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scale = StudyService.instance.readingFontScale;
    final ref = '${BookCatalog.nameById(widget.verse.bookId)} ${widget.verse.chapter}:${widget.verse.verse}';
    final hlColor = TheologicalHighlightPalette.byKey(widget.highlight?.colorKey);
    final isWhole = widget.highlight != null && widget.highlight!.isWholeVerse;

    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: 18 * scale,
      height: 1.7,
      color: theme.colorScheme.onSurface,
    );

    final spans = _buildFormattedSpans(
      text: widget.verse.translation,
      words: widget.verse.words,
      fluentMode: widget.fluentMode,
      baseStyle: baseStyle!,
      theme: theme,
      isDark: isDark,
      highlightColor: hlColor,
      highlightedFragments: widget.highlight?.selectedFragments ?? const [],
      onWordTap: widget.onWordTap,
      registerRecognizer: (r) => _recognizers.add(r),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Tarjeta del texto español con resaltado teológico y selección contextual
          Card(
            color: (isWhole && hlColor != null)
                ? hlColor.cardBackground(isDark)
                : theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: hlColor != null
                    ? hlColor.borderColor(isDark)
                    : theme.colorScheme.outlineVariant,
                width: hlColor != null ? 1.4 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText.rich(
                    TextSpan(children: spans),
                    contextMenuBuilder: (ctx, editableState) => _TheologicalSelectionToolbar(
                      editableTextState: editableState,
                      onSelectColor: (colorKey, selectedStr) {
                        widget.onApplyHighlight(colorKey, selectedFragment: selectedStr);
                        editableState.hideToolbar();
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _TheologicalPaletteBar(
                    activeColorKey: widget.highlight?.colorKey,
                    onSelectColor: (key) => widget.onApplyHighlight(key),
                    onClear: widget.highlight != null ? widget.onClearHighlight : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (widget.verseNote != null && widget.verseNote!.isNotEmpty) ...[
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
                          onPressed: widget.onEditNote,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.verseNote!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (widget.fluentMode) ...[
            _StrongChipsWrap(
              strongWords: widget.verse.words.where((w) => w.strongCode != null).toList(),
              isHebrew: widget.isHebrew,
              onWordTap: widget.onWordTap,
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              widget.isHebrew ? 'Interlineal Hebreo (BHS)' : 'Interlineal Griego (Koiné)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: widget.isHebrew ? TextDirection.rtl : TextDirection.ltr,
              child: Wrap(
                spacing: 10,
                runSpacing: 14,
                children: widget.verse.words
                    .map((w) => _InterlinearWordTile(
                          word: w,
                          isHebrew: widget.isHebrew,
                          onTap: () => widget.onWordTap(w),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StrongChipsWrap extends StatelessWidget {
  final List<WordToken> strongWords;
  final bool isHebrew;
  final ValueChanged<WordToken> onWordTap;

  const _StrongChipsWrap({
    required this.strongWords,
    required this.isHebrew,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            final origStyle = StudyService.instance.originalScriptStyle(
              isHebrew: w.language == 'hebrew',
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            );
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
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '#$prefix${w.strongCode}: ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: w.surface, style: origStyle),
                    TextSpan(
                      text: ' (${w.translation})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              onPressed: () => onWordTap(w),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Ficha léxica interlineal con tipografías académicas (Ezra SIL / Cardo)
class _InterlinearWordTile extends StatelessWidget {
  final WordToken word;
  final bool isHebrew;
  final VoidCallback onTap;

  const _InterlinearWordTile({
    required this.word,
    required this.isHebrew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final prefix = isHebrew ? 'H' : 'G';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88, maxWidth: 138),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.colorScheme.outlineVariant),
          color: t.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                word.surface,
                textAlign: TextAlign.center,
                style: StudyService.instance.originalScriptStyle(
                  isHebrew: isHebrew,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: t.colorScheme.onSurface,
                ),
              ),
            ),
            if (word.strongCode != null) ...[
              const SizedBox(height: 2),
              Text(
                '$prefix${word.strongCode}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              word.translation,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector modal ágil por pestañas: Libro -> Capítulo -> Versículo
class _PassagePickerSheet extends StatefulWidget {
  final String initialBookId;
  final int initialChapter;
  final int initialVerse;
  final int initialMaxVerse;

  const _PassagePickerSheet({
    required this.initialBookId,
    required this.initialChapter,
    required this.initialVerse,
    required this.initialMaxVerse,
  });

  @override
  State<_PassagePickerSheet> createState() => _PassagePickerSheetState();
}

class _PassagePickerSheetState extends State<_PassagePickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _testament;
  late String _bookId;
  late int _chapter;
  late int _verse;
  late int _maxVerse;

  Book get _book => BookCatalog.byId(_bookId) ?? BookCatalog.all.first;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final b = BookCatalog.byId(widget.initialBookId) ?? BookCatalog.all.first;
    _testament = b.testament;
    _bookId = b.id;
    _chapter = widget.initialChapter;
    _verse = widget.initialVerse;
    _maxVerse = widget.initialMaxVerse;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectBook(Book b) async {
    setState(() {
      _bookId = b.id;
      _testament = b.testament;
      _chapter = 1;
      _verse = 1;
    });
    _tabController.animateTo(1);
    final maxV = await DatabaseService.instance.getMaxVerse(b.id, 1);
    if (mounted) {
      setState(() => _maxVerse = maxV < 1 ? 1 : maxV);
    }
  }

  Future<void> _selectChapter(int ch) async {
    setState(() {
      _chapter = ch;
      _verse = 1;
    });
    final maxV = await DatabaseService.instance.getMaxVerse(_bookId, ch);
    if (!mounted) return;
    setState(() => _maxVerse = maxV < 1 ? 1 : maxV);
    _tabController.animateTo(2);
  }

  void _selectVerse(int v) {
    Navigator.pop(context, (bookId: _bookId, chapter: _chapter, verse: v));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final books = BookCatalog.byTestament(_testament);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ir a Pasaje (${_book.name} $_chapter:$_verse)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, (bookId: _bookId, chapter: _chapter, verse: 1)),
                  child: const Text('Abrir capítulo'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '1. Libro'),
              Tab(text: '2. Capítulo'),
              Tab(text: '3. Versículo'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Libros por Testamento
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('Antiguo Testamento')),
                          ButtonSegment(value: 2, label: Text('Nuevo Testamento')),
                        ],
                        selected: {_testament},
                        onSelectionChanged: (s) => setState(() => _testament = s.first),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 3.1,
                        ),
                        itemCount: books.length,
                        itemBuilder: (ctx, i) {
                          final b = books[i];
                          final selected = b.id == _bookId;
                          return FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _selectBook(b),
                            child: Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Pestaña 2: Cuadrícula de Capítulos
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _book.chapters,
                  itemBuilder: (ctx, i) {
                    final ch = i + 1;
                    final selected = ch == _chapter;
                    return InkWell(
                      onTap: () => _selectChapter(ch),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$ch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Pestaña 3: Cuadrícula de Versículos
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _maxVerse,
                  itemBuilder: (ctx, i) {
                    final v = i + 1;
                    final selected = v == _verse;
                    return InkWell(
                      onTap: () => _selectVerse(v),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$v',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja modal rápida de Apariencia de Lectura y Tipografías Académicas (SIL OFL)
class _ReaderAppearanceSheet extends StatelessWidget {
  const _ReaderAppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final service = StudyService.instance;
        final scale = service.readingFontScale;
        final percent = (scale * 100).round();

        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Experiencia de Lectura y Tipografías',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Escala de texto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tamaño de letra', style: theme.textTheme.labelLarge),
                    Text(
                      '$percent%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: scale,
                  min: 0.85,
                  max: 1.45,
                  divisions: 12,
                  label: '$percent%',
                  onChanged: (v) => service.setReadingFontScale(v),
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lectura por capítulo completo'),
                  subtitle: const Text('Scroll vertical continuo y swipe lateral entre capítulos'),
                  value: service.chapterReadingMode,
                  onChanged: (v) => service.setChapterReadingMode(v),
                ),

                const Divider(),
                const SizedBox(height: 6),

                // Fuente Hebrea
                Text(
                  'Tipografía Académica Hebrea (AT)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...AcademicFonts.hebrewOptions.map((opt) {
                  final selected = service.hebrewFontFamily == opt.family;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: selected
                        ? theme.colorScheme.primaryContainer.withAlpha(110)
                        : theme.colorScheme.surfaceContainerLow,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => service.setHebrewFontFamily(opt.family),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    opt.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                opt.sampleText,
                                style: TextStyle(
                                  fontFamily: opt.family,
                                  fontSize: 22,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // Fuente Griega
                Text(
                  'Tipografía Académica Griega (NT)',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...AcademicFonts.greekOptions.map((opt) {
                  final selected = service.greekFontFamily == opt.family;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: selected
                        ? theme.colorScheme.primaryContainer.withAlpha(110)
                        : theme.colorScheme.surfaceContainerLow,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => service.setGreekFontFamily(opt.family),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    opt.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              opt.sampleText,
                              style: TextStyle(
                                fontFamily: opt.family,
                                fontSize: 19,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
          maxHeight: MediaQuery.of(context).size.height * 0.82,
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
                    child: Text('Detalle Léxico y Morfológico', style: t.textTheme.titleLarge),
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
                        style: StudyService.instance.originalScriptStyle(
                          isHebrew: isHe,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: t.colorScheme.onSurface,
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
              _Row(label: 'Lema', value: widget.word.lemma, rtl: isHe, useAcademicFont: true),
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
  final bool useAcademicFont;

  const _Row({
    required this.label,
    required this.value,
    this.rtl = false,
    this.useAcademicFont = false,
  });

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
              child: Text(
                value,
                style: useAcademicFont
                    ? StudyService.instance.originalScriptStyle(
                        isHebrew: rtl,
                        fontSize: 18,
                        color: t.colorScheme.onSurface,
                      )
                    : t.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
