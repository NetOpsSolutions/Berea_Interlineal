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

  // Paleta Pergamino Alejandrino (Día) / Códice a la Luz de la Vela (Noche)
  final scheme = isDark
      ? const ColorScheme.dark(
          primary: Color(0xFFF59E0B), // Ámbar cálido
          onPrimary: Color(0xFF140F0C),
          primaryContainer: Color(0xFF3B2A18),
          onPrimaryContainer: Color(0xFFFDE68A),
          secondary: Color(0xFFFBBF24), // Ámbar dorado
          onSecondary: Color(0xFF140F0C),
          secondaryContainer: Color(0xFF422E1A),
          onSecondaryContainer: Color(0xFFFEF3C7),
          surface: Color(0xFF241C16), // Cuero tostado oscuro
          onSurface: Color(0xFFF2E3CD), // Oro champaña y marfil luminoso
          onSurfaceVariant: Color(0xFFC7B399),
          surfaceContainerLowest: Color(0xFF110D0A),
          surfaceContainerLow: Color(0xFF1D1612),
          surfaceContainer: Color(0xFF241C16),
          surfaceContainerHigh: Color(0xFF2D231C),
          surfaceContainerHighest: Color(0xFF382C23),
          outline: Color(0xFF8C663D),
          outlineVariant: Color(0xFF5A422D),
        )
      : const ColorScheme.light(
          primary: Color(0xFF9E4B06), // Bronce antiguo cálido
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF2E5CC),
          onPrimaryContainer: Color(0xFF6E3203),
          secondary: Color(0xFFC97206), // Ámbar dorado
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE8D7B9),
          onSecondaryContainer: Color(0xFF8A4106),
          surface: Color(0xFFFAF3E5), // Papiro limpio marfil
          onSurface: Color(0xFF221811), // Tinta sepia / carbón vegetal (>12:1)
          onSurfaceVariant: Color(0xFF5A4433),
          surfaceContainerLowest: Color(0xFFFAF3E5),
          surfaceContainerLow: Color(0xFFFAF3E5),
          surfaceContainer: Color(0xFFF1E4CA),
          surfaceContainerHigh: Color(0xFFE8D7B9),
          surfaceContainerHighest: Color(0xFFDEC59E),
          outline: Color(0xFFA68D6E),
          outlineVariant: Color(0xFFD2BE9F), // Bordes de tarjetas papiro
        );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent, // Permite que ParchmentBackground fluya en toda la app
    cardColor: isDark ? const Color(0xFF241C16) : const Color(0xFFFAF3E5),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor:
          isDark ? const Color(0xFFF2E3CD) : const Color(0xFF221811),
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2.0,
      shadowColor: isDark ? const Color(0x55000000) : const Color(0x286E4F28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? const Color(0xFFC89B53).withValues(alpha: 0.50)
              : const Color(0xFFD0BD9F),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xEE241C16) : const Color(0xF5FDF8EE),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFB88636) : const Color(0xFFCDB99C),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? const Color(0xFFB88636).withValues(alpha: 0.6)
              : const Color(0xFFCDB99C),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF9E4B06),
          width: 1.8,
        ),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF241C16) : const Color(0xFFFBF6ED),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          isDark ? const Color(0xFF16100D) : const Color(0xFFEADCC4),
      indicatorColor:
          isDark ? const Color(0xFF3B2C1E) : const Color(0xFFDEC59E),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:
          isDark ? const Color(0xFF16100D) : const Color(0xFFEADCC4),
      selectedItemColor:
          isDark ? const Color(0xFFF59E0B) : const Color(0xFF9E4B06),
      unselectedItemColor:
          isDark ? const Color(0xFF947D68) : const Color(0xFF7A634E),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor:
          isDark ? const Color(0xFF241C16) : const Color(0xFFFAF3E5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? const Color(0xFFC89B53).withValues(alpha: 0.65)
              : const Color(0xFFCDB99C),
          width: 1.2,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF5A422D) : const Color(0xFFD2BE9F),
      thickness: 1,
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

/// Contenedor de fondo con atmósfera de Pergamino Alejandrino (Modo Claro)
/// y Códice a la Luz de la Vela (Modo Oscuro), con viñeteado orgánico y textura de papiro.
class ParchmentBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const ParchmentBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF261A12), // Encabezado cálido ámbar
                  Color(0xFF1B120B), // Códice en penumbra
                  Color(0xFF130D08), // Papiro antiguo tostado
                  Color(0xFF0A0604), // Borde carbonizado inferior
                ],
                stops: [0.0, 0.32, 0.68, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFBF4E4), // Papiro marfil luminoso superior
                  Color(0xFFF4E5CA), // Pergamino alejandrino dorado
                  Color(0xFFE9D5AF), // Vitela envejecida miel
                  Color(0xFFDCBC88), // Borde ámbar tostado añejo
                ],
                stops: [0.0, 0.30, 0.68, 1.0],
              ),
      ),
      child: CustomPaint(
        painter: ParchmentTexturePainter(isDark: isDark),
        child: child,
      ),
    );
  }
}

class ParchmentTexturePainter extends CustomPainter {
  final bool isDark;

  const ParchmentTexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Resplandor cálido central (luz de vela / iluminación cenital suave)
    final centerLightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.30),
        radius: 0.95,
        colors: [
          isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
              : const Color(0xFFFFFDF5).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, centerLightPaint);

    // 2. Viñeta perimetral de envejecimiento orgánico de bordes (quemado de papiro)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 1.02,
        colors: [
          Colors.transparent,
          isDark
              ? const Color(0xFF000000).withValues(alpha: 0.22)
              : const Color(0xFF6B4219).withValues(alpha: 0.06),
          isDark
              ? const Color(0xFF000000).withValues(alpha: 0.52)
              : const Color(0xFF5A3310).withValues(alpha: 0.18),
          isDark
              ? const Color(0xFF000000).withValues(alpha: 0.82)
              : const Color(0xFF3E2007).withValues(alpha: 0.35),
        ],
        stops: const [0.52, 0.76, 0.90, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    // 3. Pátina histórica: manchas de envejecimiento y oxidación de vitela en márgenes
    final mottle1 = Paint()
      ..shader = RadialGradient(
        colors: [
          isDark
              ? const Color(0xFF000000).withValues(alpha: 0.35)
              : const Color(0xFF8B531F).withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.94, size.height * 0.07),
        radius: 130,
      ));
    canvas.drawCircle(Offset(size.width * 0.94, size.height * 0.07), 130, mottle1);

    final mottle2 = Paint()
      ..shader = RadialGradient(
        colors: [
          isDark
              ? const Color(0xFF000000).withValues(alpha: 0.35)
              : const Color(0xFF8B531F).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.06, size.height * 0.93),
        radius: 160,
      ));
    canvas.drawCircle(Offset(size.width * 0.06, size.height * 0.93), 160, mottle2);

    // 4. Fibras vegetales de caña de papiro (Cyperus papyrus) - Recto horizontal
    for (double y = 4; y < size.height; y += 7) {
      final int index = (y / 7).round();
      final double seed = ((index * 37) % 100) / 100.0;
      final double strokeW = 0.8 + ((index * 19) % 3) * 0.45;
      final double alpha = isDark
          ? (0.018 + seed * 0.038)
          : (0.045 + seed * 0.075);

      final fiberPaint = Paint()
        ..strokeWidth = strokeW
        ..color = isDark
            ? const Color(0xFFF59E0B).withValues(alpha: alpha)
            : const Color(0xFF6E4119).withValues(alpha: alpha);

      canvas.drawLine(Offset(0, y), Offset(size.width, y), fiberPaint);
    }

    // Tiras maestras horizontales de papiro
    for (double y = 18; y < size.height; y += 42) {
      final Paint masterReedPaint = Paint()
        ..strokeWidth = 2.0
        ..color = isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.045)
            : const Color(0xFF5A3311).withValues(alpha: 0.085);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), masterReedPaint);
    }

    // 5. Trama vertical cruzada de tiras prensadas (Verso)
    for (double x = 8; x < size.width; x += 22) {
      final int index = (x / 22).round();
      final double seed = ((index * 43) % 100) / 100.0;
      final double alpha = isDark
          ? (0.015 + seed * 0.030)
          : (0.030 + seed * 0.055);

      final vPaint = Paint()
        ..strokeWidth = 0.8 + ((index * 17) % 2) * 0.4
        ..color = isDark
            ? const Color(0xFFE2A03F).withValues(alpha: alpha)
            : const Color(0xFF7A4B20).withValues(alpha: alpha);

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vPaint);
    }

    // 6. Enmarcado perimetral de códice clásico (recuadro de orla sutil)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDark
          ? const Color(0xFFD97706).withValues(alpha: 0.12)
          : const Color(0xFF8C5E2D).withValues(alpha: 0.16);
    canvas.drawRect(rect.deflate(5.0), borderPaint);
  }

  @override
  bool shouldRepaint(covariant ParchmentTexturePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

