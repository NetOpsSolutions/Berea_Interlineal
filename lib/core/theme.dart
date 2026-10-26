import 'package:flutter/material.dart';

/// Catálogo de fuentes académicas open-source empaquetadas offline (SIL OFL)
class AcademicFontOption {
  final String family;
  final String name;
  final String subtitle;
  final String sampleText;

  const AcademicFontOption({
    required this.family,
    required this.name,
    required this.subtitle,
    required this.sampleText,
  });
}

class AcademicFonts {
  static const String defaultHebrew = 'EzraSIL';
  static const String defaultGreek = 'Cardo';

  static const List<AcademicFontOption> hebrewOptions = [
    AcademicFontOption(
      family: 'EzraSIL',
      name: 'Ezra SIL (BHS)',
      subtitle: 'Estándar académico SIL con soporte completo de nikud y cantilaciones',
      sampleText: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם',
    ),
    AcademicFontOption(
      family: 'FrankRuhlLibre',
      name: 'Frank Ruhl Libre',
      subtitle: 'Tipografía clásica hebrea de lectura fluida y trazos nítidos',
      sampleText: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם',
    ),
  ];

  static const List<AcademicFontOption> greekOptions = [
    AcademicFontOption(
      family: 'Cardo',
      name: 'Cardo (Koiné Clásica)',
      subtitle: 'Diseñada para estudios bíblicos y griego politónico (espíritus y acentos)',
      sampleText: 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',
    ),
    AcademicFontOption(
      family: 'GentiumPlus',
      name: 'Gentium Plus (SIL)',
      subtitle: 'Máxima legibilidad en pantallas móviles para diacríticos griegos',
      sampleText: 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',
    ),
  ];

  /// Genera un TextStyle optimizado para lenguas bíblicas originales (Hebreo / Griego)
  static TextStyle originalScriptStyle({
    required bool isHebrew,
    required String hebrewFamily,
    required String greekFamily,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double height = 1.55,
  }) {
    final family = isHebrew ? hebrewFamily : greekFamily;
    // El hebreo con nikud requiere ~12% más de cuerpo óptico para igualar la altura x
    final adjustedSize = isHebrew ? fontSize * 1.12 : fontSize * 1.04;
    return TextStyle(
      fontFamily: family,
      fontSize: adjustedSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

/// Definición de un color de resaltado teológico con soporte adaptativo Claro / Oscuro
class TheologicalHighlightColor {
  final String key;
  final String label;
  final String meaning;
  final IconData icon;
  final Color swatchColor;
  final Color lightBackground;
  final Color darkBackground;
  final Color lightBorder;
  final Color darkBorder;
  final Color lightInlineMarker;
  final Color darkInlineMarker;

  const TheologicalHighlightColor({
    required this.key,
    required this.label,
    required this.meaning,
    required this.icon,
    required this.swatchColor,
    required this.lightBackground,
    required this.darkBackground,
    required this.lightBorder,
    required this.darkBorder,
    required this.lightInlineMarker,
    required this.darkInlineMarker,
  });

  Color cardBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  Color borderColor(bool isDark) => isDark ? darkBorder : lightBorder;
  Color inlineMarkerColor(bool isDark) => isDark ? darkInlineMarker : lightInlineMarker;
}

class TheologicalHighlightPalette {
  static const List<TheologicalHighlightColor> values = [
    TheologicalHighlightColor(
      key: 'promesas',
      label: 'Promesas',
      meaning: 'Promesas, pactos y bendiciones de Dios',
      icon: Icons.auto_awesome_rounded,
      swatchColor: Color(0xFFF59E0B),
      lightBackground: Color(0xFFFFF8DC),
      darkBackground: Color(0x38F59E0B),
      lightBorder: Color(0xFFF59E0B),
      darkBorder: Color(0xFFFBBF24),
      lightInlineMarker: Color(0xB3FDE68A),
      darkInlineMarker: Color(0x66D97706),
    ),
    TheologicalHighlightColor(
      key: 'mandamientos',
      label: 'Mandamientos',
      meaning: 'Mandamientos, obediencia y vida cristiana',
      icon: Icons.check_circle_outline_rounded,
      swatchColor: Color(0xFF10B981),
      lightBackground: Color(0xFFECFDF5),
      darkBackground: Color(0x3610B981),
      lightBorder: Color(0xFF10B981),
      darkBorder: Color(0xFF34D399),
      lightInlineMarker: Color(0xFFA7F3D0),
      darkInlineMarker: Color(0x66059669),
    ),
    TheologicalHighlightColor(
      key: 'atributos',
      label: 'Atributos de Dios',
      meaning: 'Naturaleza del Padre, Cristo y el Espíritu Santo',
      icon: Icons.wb_sunny_outlined,
      swatchColor: Color(0xFF3B82F6),
      lightBackground: Color(0xFFEFF6FF),
      darkBackground: Color(0x383B82F6),
      lightBorder: Color(0xFF3B82F6),
      darkBorder: Color(0xFF60A5FA),
      lightInlineMarker: Color(0xFFBFDBFE),
      darkInlineMarker: Color(0x662563EB),
    ),
    TheologicalHighlightColor(
      key: 'advertencias',
      label: 'Advertencias',
      meaning: 'Exhortación, juicio y llamado a santidad',
      icon: Icons.warning_amber_rounded,
      swatchColor: Color(0xFFEC4899),
      lightBackground: Color(0xFFFDF2F8),
      darkBackground: Color(0x36EC4899),
      lightBorder: Color(0xFFEC4899),
      darkBorder: Color(0xFFF472B6),
      lightInlineMarker: Color(0xFFFBCFE8),
      darkInlineMarker: Color(0x66DB2777),
    ),
    TheologicalHighlightColor(
      key: 'profecia',
      label: 'Doctrina y Profecía',
      meaning: 'Profecía mesiánica, redención y doctrina',
      icon: Icons.menu_book_rounded,
      swatchColor: Color(0xFF8B5CF6),
      lightBackground: Color(0xFFF5F3FF),
      darkBackground: Color(0x388B5CF6),
      lightBorder: Color(0xFF8B5CF6),
      darkBorder: Color(0xFFA78BFA),
      lightInlineMarker: Color(0xFFDDD6FE),
      darkInlineMarker: Color(0x667C3AED),
    ),
  ];

  static TheologicalHighlightColor? byKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final c in values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

enum AppSnackBarTone {
  info,
  success,
  warning,
  update,
}

/// Helper centralizado para notificaciones emergentes (SnackBars) con contraste
/// garantizado WCAG AAA tanto en Tema Claro como en Tema Oscuro.
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    AppSnackBarTone tone = AppSnackBarTone.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    late final Color bgColor;
    late final Color fgColor;
    late final Color iconColor;
    late final Color actionColor;
    late final Color borderColor;

    switch (tone) {
      case AppSnackBarTone.update:
        bgColor = isDark ? const Color(0xFF172554) : const Color(0xFF1E3A8A);
        fgColor = Colors.white;
        iconColor = const Color(0xFFFCD34D);
        actionColor = const Color(0xFFFDE047);
        borderColor = const Color(0xFF3B82F6);
        break;
      case AppSnackBarTone.success:
        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFF065F46);
        fgColor = Colors.white;
        iconColor = const Color(0xFF6EE7B7);
        actionColor = const Color(0xFFA7F3D0);
        borderColor = const Color(0xFF10B981);
        break;
      case AppSnackBarTone.warning:
        bgColor = isDark ? const Color(0xFF451A03) : const Color(0xFF78350F);
        fgColor = Colors.white;
        iconColor = const Color(0xFFFCD34D);
        actionColor = const Color(0xFFFDE68A);
        borderColor = const Color(0xFFF59E0B);
        break;
      case AppSnackBarTone.info:
        bgColor = isDark ? scheme.surfaceContainerHigh : const Color(0xFF1E293B);
        fgColor = isDark ? scheme.onSurface : Colors.white;
        iconColor = isDark ? scheme.primary : const Color(0xFF93C5FD);
        actionColor = isDark ? scheme.primary : const Color(0xFF93C5FD);
        borderColor = isDark ? scheme.outlineVariant : const Color(0xFF334155);
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bgColor,
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor, width: 1.1),
          ),
          duration: duration,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: actionColor,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F3A93),
    brightness: brightness,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      color: scheme.surfaceContainerLow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: const Color(0xFFFDE047),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? scheme.outlineVariant : const Color(0xFF334155),
        ),
      ),
    ),
  );
}
