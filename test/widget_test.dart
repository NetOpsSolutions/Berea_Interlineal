import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logos_k_logos/core/theme.dart';
import 'package:logos_k_logos/core/tour/interactive_tour_overlay.dart';
import 'package:logos_k_logos/data/database_service.dart';
import 'package:logos_k_logos/data/study_service.dart';
import 'package:logos_k_logos/features/settings/settings_screen.dart';
import 'package:logos_k_logos/features/splash/splash_screen.dart';
import 'package:logos_k_logos/features/study/study_screen.dart';
import 'package:logos_k_logos/main.dart';
import 'package:logos_k_logos/shell/home_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.initialize();
    await StudyService.instance.initialize();
  });

  testWidgets('SplashScreen animates and displays required branding elements', (WidgetTester tester) async {
    await tester.pumpWidget(const LogosApp());

    // 1. Verificar elementos visuales y textos clave requeridos
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('LOGOS K LOGOS'), findsOneWidget);
    expect(find.text('BIBLIA INTERLINEAL DE ESTUDIO'), findsOneWidget);
    expect(find.text('Griego • Hebreo • Reina-Valera 1960'), findsOneWidget);
    expect(find.text('Diccionarios Strong y Análisis Morfológico'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // 2. Simular el avance del tiempo de animación
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashScreen), findsOneWidget);

    // 3. Completar la animación de inicio
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Confirmar que HomeShell está activo
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('SplashScreen can be skipped with tap to enter immediately', (WidgetTester tester) async {
    await tester.pumpWidget(const LogosApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    // Esperar microtareas para que la BD reporte lista
    await tester.pump();

    // Pulsar en el texto o pantalla para omitir
    await tester.tap(find.text('LOGOS K LOGOS'));
    await tester.pumpAndSettle();

    // Confirmar que entra inmediatamente a HomeShell
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('SettingsScreen opens StudyScreen and omits removed simulator tile', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: SettingsScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;

    // Desplazar hasta la sección Mi Estudio Personal
    await tester.scrollUntilVisible(
      find.text('Historial de visitas'),
      220,
      scrollable: scrollable,
    );

    expect(find.text('Marcadores guardados'), findsOneWidget);
    expect(find.text('Versículos resaltados'), findsOneWidget);
    expect(find.text('Notas en versículos'), findsOneWidget);
    expect(find.text('Notas en palabras Strong'), findsOneWidget);
    expect(find.text('Historial de visitas'), findsOneWidget);

    // Desplazar hacia abajo para verificar que el simulador de diseño fue eliminado
    await tester.scrollUntilVisible(
      find.text('Buscar actualizaciones'),
      220,
      scrollable: scrollable,
    );
    expect(find.text('Vista previa visual (Simulador de diseño)'), findsNothing);

    // Volver y pulsar en Versículos resaltados para abrir StudyScreen en la pestaña Resaltados
    await tester.scrollUntilVisible(
      find.text('Versículos resaltados'),
      -200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Versículos resaltados'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.textContaining('Resaltados'), findsWidgets);
  });

  test('Phase 3 StudyService highlights, typography settings, and chapter verses work end-to-end', () async {
    final study = StudyService.instance;

    // 1. Resaltado de versículo completo y por selección de palabras
    await study.applyVerseHighlight(
      bookId: 'Gn',
      chapter: 1,
      verse: 1,
      colorKey: 'atributos',
      preview: 'En el principio creó Dios los cielos y la tierra.',
    );

    var hl = study.getVerseHighlight('Gn', 1, 1);
    expect(hl, isNotNull);
    expect(hl!.colorKey, equals('atributos'));
    expect(hl.isWholeVerse, isTrue);

    await study.applyVerseHighlight(
      bookId: 'Jn',
      chapter: 1,
      verse: 1,
      colorKey: 'profecia',
      preview: 'En el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios.',
      selectedFragment: 'el Verbo era Dios',
    );

    final jnHl = study.getVerseHighlight('Jn', 1, 1);
    expect(jnHl, isNotNull);
    expect(jnHl!.isWholeVerse, isFalse);
    expect(jnHl.selectedFragments, contains('el Verbo era Dios'));
    expect(study.highlightsByColor('profecia').length, equals(1));

    await study.removeVerseHighlight('Gn', 1, 1);
    expect(study.getVerseHighlight('Gn', 1, 1), isNull);

    // 2. Tipografías académicas SIL OFL y escala de lectura
    await study.setHebrewFontFamily(AcademicFonts.hebrewOptions[1].family);
    await study.setGreekFontFamily(AcademicFonts.greekOptions[1].family);
    await study.setReadingFontScale(1.20);
    await study.setChapterReadingMode(true);

    expect(study.hebrewFontFamily, equals('FrankRuhlLibre'));
    expect(study.greekFontFamily, equals('GentiumPlus'));
    expect(study.readingFontScale, closeTo(1.20, 0.001));
    expect(study.chapterReadingMode, isTrue);

    // 3. Carga de capítulo completo en modo memoria de pruebas
    final gnChapter = await DatabaseService.instance.getChapterVerses('Gn', 1);
    expect(gnChapter, isNotEmpty);
    expect(gnChapter.first.bookId, equals('Gn'));
    expect(gnChapter.first.chapter, equals(1));

    // 4. Control de aparición única de la guía interactiva post-actualización
    expect(study.shouldShowVersionTour('1.3.2'), isTrue);
    await study.markVersionTourSeen('1.3.2');
    expect(study.shouldShowVersionTour('1.3.2'), isFalse);
    // Ante una futura versión (ej. 1.3.3), volverá a mostrarse una sola vez
    expect(study.shouldShowVersionTour('1.3.3'), isTrue);
  });

  testWidgets('HomeShell replays InteractiveTourOverlay from Settings "Ver guía de uso"', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: HomeShell(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ir a la pestaña Ajustes
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    // Desplazar hasta la sección Información de la aplicación
    final settingsScrollable = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Ver guía de uso'),
      250,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();

    // Verificar que "Ver guía de uso" está presente debajo de "Ver animación de bienvenida"
    final welcomePos = tester.getCenter(find.text('Ver animación de bienvenida'));
    final guidePos = tester.getCenter(find.text('Ver guía de uso'));
    expect(guidePos.dy, greaterThan(welcomePos.dy));

    // Iniciar manualmente la guía visual interactiva
    await tester.tap(find.text('Ver guía de uso'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(InteractiveTourOverlay), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('Capítulo Completo e Interlineal al Toque'), findsOneWidget);

    // Avanzar al paso 2 y paso 3 (Búsqueda Global)
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 / 8'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3 / 8'), findsOneWidget);
    expect(find.text('Busca Palabras, Citas o Códigos Strong'), findsOneWidget);

    // Cerrar guía con "Omitir" y drenar temporizadores pendientes
    await tester.tap(find.text('Omitir'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveTourOverlay), findsNothing);
  });
}
