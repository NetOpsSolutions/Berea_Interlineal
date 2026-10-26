import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tour/interactive_tour_overlay.dart';
import '../core/update/update_dialog.dart';
import '../core/update/update_model.dart';
import '../core/update/update_service.dart';
import '../data/study_service.dart';
import '../features/bible/bible_screen.dart';
import '../features/dictionary/dictionary_screen.dart';
import '../features/search/global_search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/study/study_screen.dart';

class HomeShell extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  const HomeShell({super.key, required this.themeMode, required this.onToggleTheme});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;

  final GlobalKey<BibleScreenState> _bibleKey = GlobalKey<BibleScreenState>();
  final GlobalKey _searchBarKey = GlobalKey(debugLabel: 'tourSearchBar');
  final GlobalKey _dictionaryControlsKey = GlobalKey(debugLabel: 'tourDictionaryControls');
  final GlobalKey _studyTabsKey = GlobalKey(debugLabel: 'tourStudyTabs');
  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();

  Timer? _updateTimer;
  Timer? _autoTourTimer;
  StreamSubscription<AppReleaseInfo>? _notificationTapSub;

  bool _showInteractiveTour = false;
  String _tourVersionLabel = UpdateService.fallbackVersion;

  @override
  void initState() {
    super.initState();
    _setupUpdateNotificationsAndTour();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _autoTourTimer?.cancel();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  /// Permite iniciar o repetir manualmente la guía visual interactiva en cualquier momento
  Future<void> startInteractiveTour() async {
    final ver = UpdateService.instance.currentVersion;
    await StudyService.instance.markVersionTourSeen(ver);
    if (!mounted) return;
    setState(() {
      _tourVersionLabel = ver;
      _showInteractiveTour = true;
    });
  }

  void _setupUpdateNotificationsAndTour() {
    // Evitar canales o temporizadores asíncronos pendientes durante pruebas unitarias/widget
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    UpdateService.instance.initializeNotificationBridge();

    _notificationTapSub = UpdateService.instance.onNotificationTapStream.listen((release) {
      if (!mounted) return;
      if (_showInteractiveTour) {
        setState(() => _showInteractiveTour = false);
      }
      showUpdateDialog(context, release, isDemo: release.isDemo);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 1. Verificar si la app fue abierta pulsando la notificación en el Centro de Notificaciones Android
      final pendingRelease = await UpdateService.instance.consumePendingNotificationRelease();
      if (!mounted) return;
      if (pendingRelease != null) {
        showUpdateDialog(context, pendingRelease, isDemo: pendingRelease.isDemo);
        return;
      }

      // 2. Solicitar permiso de notificaciones en Android 13+ de forma amigable
      await UpdateService.instance.requestNotificationPermissionIfNeeded();
      if (!mounted) return;

      // 3. Mostrar la guía visual interactiva UNA SOLA VEZ tras cada actualización de versión
      final appVer = await UpdateService.instance.getAppVersion();
      if (!mounted) return;
      if (StudyService.instance.shouldShowVersionTour(appVer)) {
        _autoTourTimer = Timer(const Duration(milliseconds: 650), () async {
          if (!mounted) return;
          await StudyService.instance.markVersionTourSeen(appVer);
          if (!mounted) return;
          setState(() {
            _tourVersionLabel = appVer;
            _showInteractiveTour = true;
          });
        });
      }
    });

    _updateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_showInteractiveTour) {
        _checkUpdateSilently();
      }
    });
  }

  Future<void> _checkUpdateSilently() async {
    try {
      final res = await UpdateService.instance.checkForUpdates();
      if (!mounted) return;
      if (res.hasUpdate && res.releaseInfo != null) {
        final release = res.releaseInfo!;

        // Publicar en el Centro de Notificaciones nativo de Android
        await UpdateService.instance.showSystemUpdateNotification(release);
        if (!mounted) return;

        // Mostrar aviso in-app con alto contraste garantizado (claro/oscuro)
        AppSnackBar.show(
          context,
          icon: Icons.system_update_rounded,
          tone: AppSnackBarTone.update,
          message: 'Nueva versión ${release.tagName} disponible (${release.apkAbi})',
          actionLabel: 'VER NOVEDADES',
          duration: const Duration(seconds: 10),
          onAction: () {
            showUpdateDialog(context, release);
          },
        );
      }
    } catch (_) {}
  }

  void _navigateToVerse(String bookId, int chapter, int verse) {
    setState(() => _index = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bibleKey.currentState?.goToVerse(bookId, chapter, verse);
    });
  }

  List<TourStepConfig> _buildTourSteps() {
    return [
      // Paso 1: Novedad v1.3.2 — Capítulo Completo e Interlineal al Toque
      TourStepConfig(
        badge: 'NOVEDAD v$_tourVersionLabel',
        isNewFeature: true,
        icon: Icons.menu_book_rounded,
        title: 'Capítulo Completo e Interlineal al Toque',
        description:
            'Ahora lees el capítulo corrido: pulsa en cualquier versículo para desplegar al instante su Hebreo o Griego original, su código Strong y los 5 resaltadores teológicos. Desliza a los lados para cambiar de capítulo.',
        pointerLabel: '👆 Pulsa en un versículo',
        demoKind: TourDemoKind.chapterUnfold,
        tabIndex: 0,
        onPrepareStep: () async {
          await _bibleKey.currentState?.prepareForInteractiveTourStep1();
        },
        targetKeyResolver: () => _bibleKey.currentState?.tourActiveVerseKey,
      ),

      // Paso 2: Novedad v1.3.2 — Controles Superiores y Fuentes Académicas
      TourStepConfig(
        badge: 'NOVEDAD v$_tourVersionLabel',
        isNewFeature: true,
        icon: Icons.text_fields_rounded,
        title: 'Modos de Vista y Fuentes Académicas',
        description:
            'Usa estos íconos superiores para alternar entre Capítulo Completo o Versículo Único, activar la Lectura Fluida o pulsar «TT» para cambiar el tamaño de letra y las fuentes Ezra SIL y Cardo.',
        pointerLabel: '👆 Vistas y fuentes (TT)',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => _bibleKey.currentState?.tourAppBarActionsKey,
      ),

      // Paso 3: Búsqueda Global
      TourStepConfig(
        badge: 'BÚSQUEDA GLOBAL',
        icon: Icons.search_rounded,
        title: 'Busca Palabras, Citas o Códigos Strong',
        description:
            'Escribe cualquier palabra en español, referencia bíblica o código Strong (ej. G3056 o H430) para encontrar en milisegundos todos los pasajes relacionados.',
        pointerLabel: '⌨️ Escribe tu búsqueda aquí',
        demoKind: TourDemoKind.typewriterSearch,
        tabIndex: 1,
        targetKeyResolver: () => _searchBarKey,
      ),

      // Paso 4: Diccionario Strong
      TourStepConfig(
        badge: 'DICCIONARIO LÉXICO',
        icon: Icons.translate_rounded,
        title: 'Diccionario Strong Griego y Hebreo',
        description:
            'Selecciona Griego o Hebreo y escribe una palabra, raíz transliterada o número Strong para consultar su significado etimológico y sus apariciones.',
        pointerLabel: '📖 Elige idioma y escribe',
        demoKind: TourDemoKind.typewriterDictionary,
        tabIndex: 2,
        targetKeyResolver: () => _dictionaryControlsKey,
      ),

      // Paso 5: Mi Estudio (Marcadores, Resaltados, Notas)
      TourStepConfig(
        badge: 'ESTUDIO PERSONAL',
        isNewFeature: true,
        icon: Icons.bookmarks_rounded,
        title: 'Marcadores, Resaltados y Notas',
        description:
            '¿Cómo crear un marcador o resaltar? Al tocar un versículo en la Biblia verás «Marcador», «Añadir nota» y 5 colores teológicos. Todo queda guardado aquí de forma permanente.',
        pointerLabel: '🔖 Tus colecciones guardadas',
        demoKind: TourDemoKind.studyCollections,
        tabIndex: 3,
        targetKeyResolver: () => _studyTabsKey,
      ),

      // Paso 6: Ajustes de Lectura y Tema
      TourStepConfig(
        badge: 'PERSONALIZACIÓN',
        icon: Icons.tune_rounded,
        title: 'Modo Claro/Oscuro, Lectura y Letra',
        description:
            'Personaliza tu lectura activando Modo Claro u Oscuro, Lectura por Capítulo Completo, Modo Lectura Fluida y el tamaño exacto de letra bíblica.',
        pointerLabel: '🎨 Tema, modos y letra',
        demoKind: TourDemoKind.readingPreferences,
        tabIndex: 4,
        onPrepareStep: () async {
          final st = _settingsKey.currentState;
          if (st != null) {
            await st.scrollToTourTarget(st.tourReadingSectionKey, alignment: 0.0);
          }
        },
        targetKeyResolver: () => _settingsKey.currentState?.tourReadingSectionKey,
      ),

      // Paso 7: Centro de Actualizaciones OTA
      TourStepConfig(
        badge: 'ACTUALIZACIONES OTA',
        isNewFeature: true,
        icon: Icons.system_update_rounded,
        title: 'Actualizaciones y Avisos en Android',
        description:
            'Comprueba nuevas versiones aquí o recibe el aviso directo en el Centro de Notificaciones de Android con las notas de versión y confirmación de descarga.',
        pointerLabel: '🔄 Centro de actualizaciones',
        demoKind: TourDemoKind.otaNotification,
        tabIndex: 4,
        onPrepareStep: () async {
          final st = _settingsKey.currentState;
          if (st != null) {
            await st.scrollToTourTarget(st.tourUpdaterKey, alignment: 0.12);
          }
        },
        targetKeyResolver: () => _settingsKey.currentState?.tourUpdaterKey,
      ),

      // Paso 8: Repetir Guía Visual cuando quieras
      TourStepConfig(
        badge: 'AYUDA SIEMPRE ACTIVA',
        icon: Icons.explore_rounded,
        title: 'Vuelve a Ver esta Guía Cuando Quieras',
        description:
            'Este recorrido solo aparece automáticamente una vez tras cada actualización. Si deseas repetirlo más adelante, pulsa aquí en «Ver guía de uso».',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: () async {
          final st = _settingsKey.currentState;
          if (st != null) {
            await st.scrollToTourTarget(st.tourReplayGuideKey, alignment: 0.22);
          }
        },
        targetKeyResolver: () => _settingsKey.currentState?.tourReplayGuideKey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BibleScreen(key: _bibleKey),
      GlobalSearchScreen(
        onOpenVerse: _navigateToVerse,
        tourSearchBarKey: _searchBarKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
      ),
      StudyScreen(
        onOpenVerse: _navigateToVerse,
        tourTabsKey: _studyTabsKey,
      ),
      SettingsScreen(
        key: _settingsKey,
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
        onOpenVerse: _navigateToVerse,
        onStartInteractiveGuide: startInteractiveTour,
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Biblia',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Búsqueda',
              ),
              NavigationDestination(
                icon: Icon(Icons.translate_outlined),
                selectedIcon: Icon(Icons.translate),
                label: 'Diccionario',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmarks_outlined),
                selectedIcon: Icon(Icons.bookmarks),
                label: 'Mi Estudio',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
        if (_showInteractiveTour)
          InteractiveTourOverlay(
            versionLabel: _tourVersionLabel,
            steps: _buildTourSteps(),
            onSwitchTab: (tabIdx) {
              if (_index != tabIdx) {
                setState(() => _index = tabIdx);
              }
            },
            onFinish: () {
              setState(() {
                _showInteractiveTour = false;
                _index = 0;
              });
            },
            onSkip: () {
              setState(() {
                _showInteractiveTour = false;
              });
            },
          ),
      ],
    );
  }
}
