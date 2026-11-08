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
        bgColor = const Color(0xFF1E293B);
        fgColor = Colors.white;
        iconColor = const Color(0xFFFCD34D);
        actionColor = const Color(0xFFFDE047);
        borderColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF334155);
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

  // Paleta Pergamino Alejandrino Liso (Día) / Códice a la Luz de la Vela (Noche)
  final scheme = isDark
      ? const ColorScheme.dark(
          primary: Color(0xFFF59E0B), // Ámbar cálido
          onPrimary: Color(0xFF181412),
          primaryContainer: Color(0xFF3B2A18),
          onPrimaryContainer: Color(0xFFFDE68A),
          secondary: Color(0xFFFBBF24), // Ámbar dorado
          onSecondary: Color(0xFF181412),
          secondaryContainer: Color(0xFF422E1A),
          onSecondaryContainer: Color(0xFFFEF3C7),
          surface: Color(0xFF221C18), // Cuero tostado oscuro
          onSurface: Color(0xFFEAD8BA), // Oro champaña y marfil cálido
          onSurfaceVariant: Color(0xFFA89884), // Bronce suave
          surfaceContainerLowest: Color(0xFF14110E),
          surfaceContainerLow: Color(0xFF221C18),
          surfaceContainer: Color(0xFF261F1A),
          surfaceContainerHigh: Color(0xFF2A221C),
          surfaceContainerHighest: Color(0xFF332922),
          outline: Color(0xFF6E5B4B),
          outlineVariant: Color(0xFF4A3E34), // Bordes generales
        )
      : const ColorScheme.light(
          primary: Color(0xFFB45309), // Bronce antiguo cálido
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF3EAD5),
          onPrimaryContainer: Color(0xFF78350F),
          secondary: Color(0xFFD97706), // Ámbar dorado
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFEDE4CE),
          onSecondaryContainer: Color(0xFF92400E),
          surface: Color(0xFFFAF5EA), // Papiro limpio para tarjetas, diálogos y menús
          onSurface: Color(0xFF261D17), // Tinta sepia / carbón vegetal (>12:1)
          onSurfaceVariant: Color(0xFF6B5A4B), // Tono nuez oscuro
          surfaceContainerLowest: Color(0xFFFAF5EA),
          surfaceContainerLow: Color(0xFFFAF5EA),
          surfaceContainer: Color(0xFFF3EAD5),
          surfaceContainerHigh: Color(0xFFEDE4CE),
          surfaceContainerHighest: Color(0xFFE5DAC1),
          outline: Color(0xFFB8A68B),
          outlineVariant: Color(0xFFDFCFAF), // Bordes generales de tarjetas y selectores
        );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF181412) : const Color(0xFFF5EEDB),
    cardColor: isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EA),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor:
          isDark ? const Color(0xFF1F1915) : const Color(0xFFEFE6D2),
      surfaceTintColor: Colors.transparent,
      foregroundColor:
          isDark ? const Color(0xFFEAD8BA) : const Color(0xFF261D17),
      elevation: 0.5,
      scrolledUnderElevation: 1.0,
      shadowColor: isDark ? const Color(0x44000000) : const Color(0x18000000),
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFFEAD8BA) : const Color(0xFF261D17),
      ),
      titleTextStyle: TextStyle(
        color: isDark ? const Color(0xFFEAD8BA) : const Color(0xFF261D17),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: isDark ? 1.5 : 1.0,
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark ? const Color(0x33000000) : const Color(0x18000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFDFCFAF),
          width: 1.0,
        ),
      ),
      color: isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EA),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFDFCFAF),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFDFCFAF),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EA),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          isDark ? const Color(0xFF1B1613) : const Color(0xFFEDE4CE),
      surfaceTintColor: Colors.transparent,
      indicatorColor:
          isDark ? const Color(0xFF382A1D) : const Color(0xFFE2D3B5),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        if (isDark) {
          return IconThemeData(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFF786A5E),
          );
        }
        return IconThemeData(
          color: selected ? const Color(0xFFB45309) : const Color(0xFF8C7B6B),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        if (isDark) {
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFF786A5E),
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFFB45309) : const Color(0xFF8C7B6B),
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:
          isDark ? const Color(0xFF1B1613) : const Color(0xFFEDE4CE),
      selectedItemColor:
          isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
      unselectedItemColor:
          isDark ? const Color(0xFF786A5E) : const Color(0xFF8C7B6B),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor:
          isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EA),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFDFCFAF),
          width: 1.0,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:
          isDark ? const Color(0xFF221C18) : const Color(0xFFFAF5EA),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF4A3E34) : const Color(0xFFDFCFAF),
      thickness: 1.0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
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

