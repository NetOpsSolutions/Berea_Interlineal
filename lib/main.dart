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

  runApp(const LogosApp());
}

class LogosApp extends StatelessWidget {
  const LogosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final currentThemeMode = StudyService.instance.themeMode;

        return MaterialApp(
          title: 'Logos K Logos',
          debugShowCheckedModeBanner: false,
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
