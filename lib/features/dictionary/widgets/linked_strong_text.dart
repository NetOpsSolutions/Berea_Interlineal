import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../strong_detail_screen.dart';

class LinkedStrongText extends StatefulWidget {
  final String text;
  final String currentLanguage;
  final TextStyle? style;
  final void Function(String language, int code)? onTapStrong;

  const LinkedStrongText({
    super.key,
    required this.text,
    required this.currentLanguage,
    this.style,
    this.onTapStrong,
  });

  @override
  State<LinkedStrongText> createState() => _LinkedStrongTextState();
}

class _LinkedStrongTextState extends State<LinkedStrongText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _handleTap(String language, int code) {
    if (widget.onTapStrong != null) {
      widget.onTapStrong!(language, code);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrongDetailScreen(
            language: language,
            code: code,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final baseStyle = widget.style ?? theme.textTheme.bodyMedium;

    if (widget.text.isEmpty) {
      return Text('—', style: baseStyle);
    }

    final spans = _buildSpans(widget.text, theme, baseStyle);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  List<InlineSpan> _buildSpans(String text, ThemeData theme, TextStyle? baseStyle) {
    final spans = <InlineSpan>[];

    // Regex para detectar códigos Strong explícitos (G1234, H1234) o números en contextos de derivación/paréntesis
    final pattern = RegExp(
      r'([GHgh]#?\d{1,5})|(?<![:\d])(\d{1,5})(?![:\d])',
      caseSensitive: false,
    );

    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      final matchStart = match.start;
      final matchEnd = match.end;

      // Verificamos si es parte de una referencia bíblica como "3:14" o "25:25"
      if (matchStart > 0 && text[matchStart - 1] == ':') continue;
      if (matchEnd < text.length && text[matchEnd] == ':') continue;

      final matchedStr = match.group(0)!;
      final numericPart = matchedStr.replaceAll(RegExp(r'[^0-9]'), '');
      final code = int.tryParse(numericPart);

      // Si no es un número válido o está fuera del rango razonable de Strong (1 a 8674)
      if (code == null || code <= 0 || code > 8674) continue;

      // Determinamos el idioma objetivo (griego o hebreo)
      String targetLang = widget.currentLanguage;
      final upper = matchedStr.toUpperCase();
      if (upper.startsWith('G')) {
        targetLang = 'greek';
      } else if (upper.startsWith('H')) {
        targetLang = 'hebrew';
      } else {
        // Miramos el contexto circundante (30 caracteres antes) para ver si menciona 'hebreo' o 'griego'
        final contextStart = matchStart > 30 ? matchStart - 30 : 0;
        final surrounding = text.substring(contextStart, matchStart).toLowerCase();
        if (surrounding.contains('hebreo') || surrounding.contains('hebr.')) {
          targetLang = 'hebrew';
        } else if (surrounding.contains('griego') || surrounding.contains('grieg.')) {
          targetLang = 'greek';
        }
      }

      // Añadimos el texto previo no enlazado
      if (matchStart > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, matchStart),
          style: baseStyle,
        ));
      }

      // Creamos el hipervínculo interactivo para el código Strong
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _handleTap(targetLang, code);
      _recognizers.add(recognizer);

      final prefix = targetLang == 'hebrew' ? 'H' : 'G';
      final linkDisplay = matchedStr.startsWith(RegExp(r'[GHgh]'))
          ? matchedStr.toUpperCase()
          : '$prefix$code';

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InkWell(
            onTap: () => _handleTap(targetLang, code),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(140),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(80),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    linkDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      lastIndex = matchEnd;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
