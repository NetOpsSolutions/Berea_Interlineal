import 'package:flutter/material.dart';

import '../../data/book_catalog.dart';
import '../../data/database_service.dart';
import '../../data/models.dart';
import '../bible/quick_verse_modal_sheet.dart';
import '../dictionary/strong_detail_screen.dart';
import '../summaries/book_summary_sheet.dart';

class AuthorDetailScreen extends StatefulWidget {
  final BiblicalAuthor author;
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const AuthorDetailScreen({
    super.key,
    required this.author,
    this.onOpenVerse,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  late Future<List<BookSummary>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture =
        DatabaseService.instance.getBooksByAuthorId(widget.author.authorId);
  }

  void _openStrongCode(String strongCode) {
    final clean = strongCode.trim();
    if (clean.isEmpty) return;

    final prefix = clean[0].toUpperCase();
    final number = int.tryParse(clean.substring(1));
    if (number == null) return;

    final lang = prefix == 'H' ? 'hebrew' : 'greek';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StrongDetailScreen(
          language: lang,
          code: number,
        ),
      ),
    );
  }

  void _openCallingVerseDirect(ScriptureReference ref) {
    if (widget.onOpenVerse == null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onOpenVerse!(ref.bookId, ref.chapter, ref.verse);
  }

  void _openCallingVersePreview(ScriptureReference ref) {
    QuickVerseModalSheet.show(
      context,
      bookId: ref.bookId,
      chapter: ref.chapter,
      verse: ref.verse,
      rawRef: ref.rawText,
      onOpenFullReader: widget.onOpenVerse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF181412) : const Color(0xFFF7F1E1);
    final cardBg = isDark ? const Color(0xFF241D19) : const Color(0xFFEDE4CE);
    final borderColor = isDark ? const Color(0xFF3D3025) : const Color(0xFFDFCFAF);
    final accentGold = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final titleColor = isDark ? const Color(0xFFFDFBF7) : const Color(0xFF261D17);
    final bodyColor = isDark ? const Color(0xFFE5DDD0) : const Color(0xFF3D3025);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.author.nameEs),
        backgroundColor: isDark ? const Color(0xFF14110E) : const Color(0xFFEDE4CE),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Cabecera del Autor con Nombre Original y Código Strong
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentGold, width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          widget.author.nameEs.characters.first,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.author.nameEs,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                widget.author.nameOriginal,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: widget.author.strongCode?.startsWith('H') == true
                                      ? 'EzraSIL'
                                      : 'GentiumPlus',
                                  color: accentGold,
                                ),
                              ),
                              if (widget.author.strongCode != null) ...[
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => _openStrongCode(widget.author.strongCode!),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accentGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: accentGold, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.translate, size: 12, color: accentGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.author.strongCode!,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: accentGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                // Época y Ocupación
                _buildAuthorMetaRow(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Época histórica',
                  value: widget.author.era,
                  accentColor: accentGold,
                  bodyColor: bodyColor,
                ),
                const SizedBox(height: 10),
                _buildAuthorMetaRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Ocupación terrenal',
                  value: widget.author.occupation,
                  accentColor: accentGold,
                  bodyColor: bodyColor,
                ),

                const SizedBox(height: 14),

                // Versículo de llamamiento y testimonio
                Builder(
                  builder: (context) {
                    final callingRefs = BookCatalog.parseMultiReferences(widget.author.callingVerse);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentGold.withValues(alpha: 0.28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 18, color: accentGold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Versículo de llamamiento / testimonio:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (callingRefs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                widget.author.callingVerse,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                            )
                          else
                            ...callingRefs.map((ref) {
                              return Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor, width: 0.8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ref.rawText,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.preview_rounded, size: 20),
                                      color: accentGold,
                                      tooltip: 'Vista previa rápida en ventana',
                                      onPressed: () => _openCallingVersePreview(ref),
                                    ),
                                    if (widget.onOpenVerse != null)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                                        color: accentGold,
                                        tooltip: 'Abrir en Biblia Interlineal',
                                        onPressed: () => _openCallingVerseDirect(ref),
                                      ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Libros Canónicos Redactados
          Text(
            'LIBROS BÍBLICOS REDACTADOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: accentGold,
            ),
          ),
          const SizedBox(height: 10),

          FutureBuilder<List<BookSummary>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ));
              }
              final books = snapshot.data ?? [];
              if (books.isEmpty) {
                return Text(
                  'No se han vinculado libros a este autor en el canon.',
                  style: TextStyle(fontSize: 13, color: bodyColor),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: books.map((b) {
                  return ActionChip(
                    backgroundColor: cardBg,
                    side: BorderSide(color: borderColor),
                    avatar: Icon(Icons.history_edu_rounded, size: 16, color: accentGold),
                    label: Text(
                      b.bookName,
                      style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
                    ),
                    onPressed: () {
                      BookSummarySheet.show(
                        context,
                        summary: b,
                        onOpenVerse: widget.onOpenVerse,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Biografía Completa y Legado Teológico
          Text(
            'BIOGRAFÍA Y LEGADO TEOLÓGICO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: accentGold,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.author.biography,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.6,
                color: bodyColor,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAuthorMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required Color bodyColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: bodyColor,
            ),
          ),
        ),
      ],
    );
  }
}
