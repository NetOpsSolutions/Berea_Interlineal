import 'package:flutter/material.dart';

import '../../data/book_catalog.dart';
import '../../data/database_service.dart';
import '../../data/models.dart';
import '../authors/author_detail_screen.dart';
import '../bible/quick_verse_modal_sheet.dart';

class BookSummarySheet extends StatelessWidget {
  final BookSummary summary;
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const BookSummarySheet({
    super.key,
    required this.summary,
    this.onOpenVerse,
  });

  static Future<void> show(
    BuildContext context, {
    required BookSummary summary,
    void Function(String bookId, int chapter, int verse)? onOpenVerse,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookSummarySheet(
        summary: summary,
        onOpenVerse: onOpenVerse,
      ),
    );
  }

  void _navigateToKeyVerse(BuildContext context) {
    if (onOpenVerse == null) return;
    final parsed = BookCatalog.parseReference(
      summary.keyVerseRef,
      defaultBookCode: summary.bookCode,
    );
    final bookCode = parsed?.bookId ?? summary.bookCode;
    final ch = parsed?.chapter ?? 1;
    final vs = parsed?.verse ?? 1;
    Navigator.of(context).popUntil((route) => route.isFirst);
    onOpenVerse!(bookCode, ch, vs);
  }

  void _openQuickVersePreview(BuildContext context) {
    final parsed = BookCatalog.parseReference(
      summary.keyVerseRef,
      defaultBookCode: summary.bookCode,
    );
    final bookCode = parsed?.bookId ?? summary.bookCode;
    final ch = parsed?.chapter ?? 1;
    final vs = parsed?.verse ?? 1;

    QuickVerseModalSheet.show(
      context,
      bookId: bookCode,
      chapter: ch,
      verse: vs,
      rawRef: summary.keyVerseRef,
      onOpenFullReader: onOpenVerse,
    );
  }

  void _openAuthorBiography(BuildContext context) async {
    final author = await DatabaseService.instance.getBiblicalAuthorById(summary.authorId);
    if (author != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuthorDetailScreen(
            author: author,
            onOpenVerse: onOpenVerse,
          ),
        ),
      );
    }
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              // Indicador de arrastre superior
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFC7B698),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Barra de título del libro con icono y botón de cierre
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentGold.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.history_edu_rounded, color: accentGold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                summary.bookName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  summary.testament == 'OT' ? 'Antiguo Testamento' : 'Nuevo Testamento',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            summary.category,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFA89F91) : const Color(0xFF6B5A4B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Cerrar ficha',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contenido con los 6 campos canónicos estructurados
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    // 1. Autor y Fecha (Fila Compacta Informativa)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.person_rounded,
                            title: 'Autor / Escritor',
                            content: summary.authorName,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            bodyColor: bodyColor,
                            accentColor: accentGold,
                            actionLabel: 'Ver biografía',
                            onAction: () => _openAuthorBiography(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.calendar_today_rounded,
                            title: 'Fecha de Redacción',
                            content: summary.dateWritten,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            bodyColor: bodyColor,
                            accentColor: accentGold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2. Destinatarios Originales
                    _buildSectionBlock(
                      icon: Icons.groups_rounded,
                      title: 'Destinatarios Originales',
                      content: summary.recipients,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      bodyColor: bodyColor,
                      accentColor: accentGold,
                    ),

                    const SizedBox(height: 14),

                    // 3. Contexto Histórico, Político y Cultural
                    _buildSectionBlock(
                      icon: Icons.account_balance_rounded,
                      title: 'Contexto Histórico, Político y Cultural',
                      content: summary.historicalContext,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      bodyColor: bodyColor,
                      accentColor: accentGold,
                    ),

                    const SizedBox(height: 14),

                    // 4. Temas Centrales Doctrinales
                    _buildSectionBlock(
                      icon: Icons.auto_stories_rounded,
                      title: 'Temas Centrales y Ejes Doctrinales',
                      content: summary.keyThemes,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      bodyColor: bodyColor,
                      accentColor: accentGold,
                    ),

                    const SizedBox(height: 14),

                    // 5. Versículo Clave con Salto Interactivo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentGold.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: accentGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Versículo Clave del Libro',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.keyVerseRef,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accentGold,
                                  side: BorderSide(color: accentGold.withValues(alpha: 0.5)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.preview_rounded, size: 16),
                                label: const Text('Vista Rápida'),
                                onPressed: () => _openQuickVersePreview(context),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accentGold,
                                  foregroundColor: isDark ? const Color(0xFF1B1613) : Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text('Leer en Interlineal'),
                                onPressed: () => _navigateToKeyVerse(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 6. Aplicación Práctica para Hoy
                    _buildSectionBlock(
                      icon: Icons.eco_rounded,
                      title: 'Aplicación Práctica para Hoy',
                      content: summary.practicalApplication,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      bodyColor: bodyColor,
                      accentColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
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

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color cardBg,
    required Color borderColor,
    required Color bodyColor,
    required Color accentColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: bodyColor,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionBlock({
    required IconData icon,
    required String title,
    required String content,
    required Color cardBg,
    required Color borderColor,
    required Color bodyColor,
    required Color accentColor,
  }) {
    return Container(
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
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
