import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/database_service.dart';
import 'data/study_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar marcadores, notas personales, historial y preferencias de tema
  await StudyService.instance.initialize();

  // Iniciar la preparación de la base de datos en segundo plano
  DatabaseService.instance.initialize();

  runApp(const BereaApp());
}

class BereaApp extends StatelessWidget {
  const BereaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: StudyService.instance.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Berea Interlineal',
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: currentThemeMode,
          home: SplashScreen(
            themeMode: currentThemeMode,
            onToggleTheme: () => StudyService.instance.toggleTheme(),
          ),
        );
      },
    );
  }
}

/// Alias para compatibilidad hacia atrás
typedef LogosApp = BereaApp;
