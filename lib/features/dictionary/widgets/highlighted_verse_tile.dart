import 'package:flutter/material.dart';

import '../../../data/book_catalog.dart';
import '../../../data/models.dart';
import '../../../data/study_service.dart';

class HighlightedVerseTile extends StatelessWidget {
  final Verse verse;
  final int strongCode;
  final String language;
  final void Function(Verse verse)? onOpenVerse;

  const HighlightedVerseTile({
    super.key,
    required this.verse,
    required this.strongCode,
    required this.language,
    this.onOpenVerse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookName = BookCatalog.nameById(verse.bookId);
    final ref = '$bookName ${verse.chapter}:${verse.verse}';

    // Palabras correspondientes a este código Strong en este versículo
    final matchingTokens = verse.words.where((w) => w.strongCode == strongCode).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Referencia y Botón para ir a la Biblia
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (onOpenVerse != null) {
                      onOpenVerse!(verse);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text('Abrir versículo', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Texto en español con la palabra resaltada tipo marcador/subrayada
            _buildHighlightedTranslation(verse.translation, matchingTokens, theme, isDark),

            // Chips con la forma original en este versículo
            if (matchingTokens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: matchingTokens.map((w) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: w.surface,
                            style: StudyService.instance.originalScriptStyle(
                              isHebrew: language == 'hebrew',
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: ' (${w.translation})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedTranslation(
    String translation,
    List<WordToken> tokens,
    ThemeData theme,
    bool isDark,
  ) {
    final phrases = <String>{};
    for (final t in tokens) {
      final clean = t.translation.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      if (clean.isNotEmpty) {
        phrases.add(clean);
        // También añadimos palabras individuales significativas (ej: de "de Dios" -> "Dios")
        for (final word in clean.split(RegExp(r'\s+'))) {
          final wClean = word.replaceAll(RegExp(r'[^a-záéíóúñA-ZÁÉÍÓÚÑ]'), '');
          if (wClean.length > 2) {
            phrases.add(wClean);
          }
        }
      }
    }

    if (phrases.isEmpty) {
      return Text(
        translation,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      );
    }

    // Ordenamos de mayor a menor longitud para no partir frases compuestas
    final sortedPhrases = phrases.toList()..sort((a, b) => b.length.compareTo(a.length));
    final pattern = sortedPhrases.map((p) => r'\b' + RegExp.escape(p) + r'\b').join('|');
    final regex = RegExp(pattern, caseSensitive: false);

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(translation)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: translation.substring(lastEnd, match.start),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: theme.colorScheme.onSurface,
          ),
        ));
      }

      // La palabra o frase objetivo: resaltada tipo resaltador sin cambiar el color de la fuente
      spans.add(TextSpan(
        text: translation.substring(match.start, match.end),
        style: TextStyle(
          color: theme.colorScheme.onSurface, // No cambia el color de la fuente
          backgroundColor: isDark
              ? const Color(0xFFFBC02D).withAlpha(140) // Resaltador dorado en oscuro
              : const Color(0xFFFFF176), // Resaltador amarillo en claro
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: isDark
              ? const Color(0xFFFFD54F)
              : const Color(0xFFE65100), // Subrayado que resalta
          decorationThickness: 2.2,
        ),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < translation.length) {
      spans.add(TextSpan(
        text: translation.substring(lastEnd),
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.55,
          color: theme.colorScheme.onSurface,
        ),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: theme.textTheme.bodyMedium,
    );
  }
}
