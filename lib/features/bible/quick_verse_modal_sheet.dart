import 'package:flutter/material.dart';

import '../../data/book_catalog.dart';
import '../../data/database_service.dart';
import '../../data/models.dart';
import '../../data/study_service.dart';
import '../dictionary/strong_detail_screen.dart';

/// Ventana emergente tipo modal para lectura interlineal rápida de un versículo
/// sin necesidad de abandonar la pantalla actual (biografía de autor o resumen de libro).
class QuickVerseModalSheet extends StatefulWidget {
  final String bookId;
  final int chapter;
  final int verse;
  final String? rawRef;
  final void Function(String bookId, int chapter, int verse)? onOpenFullReader;

  const QuickVerseModalSheet({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    this.rawRef,
    this.onOpenFullReader,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookId,
    required int chapter,
    required int verse,
    String? rawRef,
    void Function(String bookId, int chapter, int verse)? onOpenFullReader,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickVerseModalSheet(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        rawRef: rawRef,
        onOpenFullReader: onOpenFullReader,
      ),
    );
  }

  @override
  State<QuickVerseModalSheet> createState() => _QuickVerseModalSheetState();
}

class _QuickVerseModalSheetState extends State<QuickVerseModalSheet> {
  Verse? _verse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    final v = await DatabaseService.instance.getVerse(
      widget.bookId,
      widget.chapter,
      widget.verse,
    );
    if (mounted) {
      setState(() {
        _verse = v;
        _loading = false;
      });
    }
  }

  void _openStrong(String language, int code) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StrongDetailScreen(
          language: language,
          code: code,
        ),
      ),
    );
  }

  void _openInBible() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onOpenFullReader?.call(widget.bookId, widget.chapter, widget.verse);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF1B1613) : const Color(0xFFF7F1E1);
    final cardBg = isDark ? const Color(0xFF241D19) : const Color(0xFFEDE4CE);
    final borderColor = isDark ? const Color(0xFF3D3025) : const Color(0xFFDFCFAF);
    final accentGold = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final titleColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF261D17);
    final bodyColor = isDark ? const Color(0xFFE5DDD0) : const Color(0xFF3D3025);

    final bookName = BookCatalog.nameById(widget.bookId);
    final book = BookCatalog.byId(widget.bookId);
    final isHebrew = book?.testament == 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFC7B698),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Cabecera: Título del versículo y acciones
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentGold.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.auto_stories_rounded, color: accentGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.rawRef ?? '$bookName ${widget.chapter}:${widget.verse}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                isHebrew
                                    ? 'Antiguo Testamento • Texto Hebreo'
                                    : 'Nuevo Testamento • Texto Griego',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: accentGold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: accentGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Vista Rápida',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Cerrar ventana',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contenido con scroll
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _verse == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No se pudo cargar el versículo en este momento.',
                                style: TextStyle(color: bodyColor),
                              ),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Traducción en español (Reina-Valera)
                              if (_verse!.translation.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor, width: 0.9),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.format_quote_rounded, size: 16, color: accentGold),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Traducción en Español (RVR1960)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: accentGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _verse!.translation,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          height: 1.45,
                                          fontStyle: FontStyle.italic,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Título de la sección interlineal
                              Row(
                                children: [
                                  Icon(Icons.translate_rounded, size: 16, color: accentGold),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PALABRAS INTERLINEALES Y CONCORDANCIA',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: accentGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Fichas de palabras interlineales
                              Directionality(
                                textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 10,
                                  children: _verse!.words.map((w) {
                                    final strongCode = w.strongCode;
                                    final lang = w.language;

                                    return Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: borderColor, width: 0.8),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Texto original (hebreo/griego)
                                            Directionality(
                                              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
                                              child: Text(
                                                w.surface,
                                                style: StudyService.instance.originalScriptStyle(
                                                  isHebrew: isHebrew,
                                                  fontSize: isHebrew ? 22 : 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                ),
                                              ),
                                            ),
                                            if (w.lemma.isNotEmpty && w.lemma != w.surface) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '(${w.lemma})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color: accentGold,
                                                ),
                                              ),
                                            ],
                                            if (strongCode != null) ...[
                                              const SizedBox(height: 4),
                                              InkWell(
                                                borderRadius: BorderRadius.circular(4),
                                                onTap: () => _openStrong(lang, strongCode),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: accentGold.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: accentGold.withValues(alpha: 0.4),
                                                      width: 0.6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '#${lang == 'hebrew' ? 'H' : 'G'}$strongCode',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: accentGold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (w.translation.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                w.translation,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: bodyColor,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
              ),

              const Divider(height: 1),

              // Botonera inferior: Abrir en Lector Completo / Cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentGold,
                          foregroundColor: isDark ? const Color(0xFF1B1613) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: const Text(
                          'Abrir en Biblia Interlineal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        onPressed: widget.onOpenFullReader != null ? _openInBible : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
