import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  testWidgets('SettingsScreen opens StudyScreen on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
        ),
      ),
    );

    // Verify tiles exist
    expect(find.text('Marcadores guardados'), findsOneWidget);
    expect(find.text('Notas en versículos'), findsOneWidget);
    expect(find.text('Notas en palabras Strong'), findsOneWidget);
    expect(find.text('Historial de visitas'), findsOneWidget);

    // Tap on Marcadores guardados
    await tester.tap(find.text('Marcadores guardados'));
    await tester.pumpAndSettle();

    // Verify StudyScreen opened
    expect(find.byType(StudyScreen), findsOneWidget);
  });
}
