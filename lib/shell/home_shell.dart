import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tour/interactive_tour_overlay.dart';
import '../core/tour/tour_steps_factory.dart';
import '../core/update/update_dialog.dart';
import '../core/update/update_model.dart';
import '../core/update/update_service.dart';
import '../data/study_service.dart';
import '../features/bible/bible_screen.dart';
import '../features/dictionary/dictionary_screen.dart';
import '../features/search/global_search_screen.dart';
import '../features/authors/biblical_authors_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/study/study_screen.dart';
import '../features/summaries/book_summaries_screen.dart';
import 'widgets/berea_drawer.dart';

class HomeShell extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  const HomeShell({super.key, required this.themeMode, required this.onToggleTheme});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<BibleScreenState> _bibleKey = GlobalKey<BibleScreenState>();
  final GlobalKey<StudyScreenState> _studyKey = GlobalKey<StudyScreenState>();
  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();
  final GlobalKey _dictionaryControlsKey = GlobalKey(debugLabel: 'tourDictionaryControls');
  final GlobalKey _studyTabsKey = GlobalKey(debugLabel: 'tourStudyTabs');
  final GlobalKey _searchBarKey = GlobalKey(debugLabel: 'tourSearchBar');

  // Claves de la guía interactiva v1.4.0
  final GlobalKey _tourDrawerButtonKey = GlobalKey(debugLabel: 'tourDrawerButton');
  final GlobalKey _tourBottomNavDictionaryKey = GlobalKey(debugLabel: 'tourBottomNavDictionary');
  final GlobalKey _tourBottomNavStudyKey = GlobalKey(debugLabel: 'tourBottomNavStudy');
  final GlobalKey _tourBookSummaryButtonKey = GlobalKey(debugLabel: 'tourBookSummaryButton');
  final GlobalKey _tourDrawerTheologicalKey = GlobalKey(debugLabel: 'tourDrawerTheological');
  final GlobalKey _tourThemeToggleKey = GlobalKey(debugLabel: 'tourThemeToggle');

  Timer? _updateTimer;
  Timer? _periodicUpdateTimer;
  Timer? _autoTourTimer;
  StreamSubscription<AppReleaseInfo>? _notificationTapSub;
  String? _lastInAppPromptTag;

  bool _showInteractiveTour = false;
  String _tourVersionLabel = UpdateService.fallbackVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupUpdateNotificationsAndTour();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _periodicUpdateTimer?.cancel();
    _autoTourTimer?.cancel();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver a la app o reconectar pantalla/red, verificar si venció la ventana de enfriamiento (5 min)
      if (UpdateService.instance.canCheckSilently(minCooldown: const Duration(minutes: 5))) {
        _checkUpdateSilently();
      }
    }
  }

  /// Permite iniciar o repetir manualmente la guía visual interactiva en cualquier momento
  Future<void> startInteractiveTour() async {
    final ver = await UpdateService.instance.getAppVersion();
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

      // 3. Mostrar la guía visual interactiva UNA SOLA VEZ tras cada instalación o actualización
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

    // 1. Espera de cortesía de 15 segundos: arranque suave sin competir por I/O, BD ni CPU
    _updateTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_showInteractiveTour) {
        _checkUpdateSilently();
      }
      // 2. Revisión periódica prudente cada 15 minutos mientras la app esté en uso prolongado
      _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        if (mounted && !_showInteractiveTour) {
          _checkUpdateSilently();
        }
      });
    });
  }

  Future<void> _checkUpdateSilently() async {
    try {
      final res = await UpdateService.instance.checkForUpdates();
      if (!mounted) return;
      if (res.hasUpdate && res.releaseInfo != null) {
        final release = res.releaseInfo!;

        // 1. Publicar en el Centro de Notificaciones nativo de Android
        await UpdateService.instance.showSystemUpdateNotification(release);
        if (!mounted) return;

        // 2. Mostrar aviso in-app con alto contraste garantizado una sola vez por versión
        if (_lastInAppPromptTag != release.tagName) {
          _lastInAppPromptTag = release.tagName;
          AppSnackBar.show(
            context,
            icon: Icons.system_update_rounded,
            tone: AppSnackBarTone.update,
            message: 'Nueva versión ${release.tagName} disponible',
            actionLabel: 'VER NOVEDADES',
            duration: const Duration(seconds: 10),
            onAction: () {
              showUpdateDialog(context, release);
            },
          );
        }
      }
    } catch (_) {}
  }

  void _navigateToVerse(String bookId, int chapter, int verse) {
    // Cerrar cualquier diálogo, pantalla o modal apilado sobre HomeShell
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _index = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bibleKey.currentState?.goToVerse(bookId, chapter, verse);
    });
  }

  void _openBookSummaries() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSummariesScreen(onOpenVerse: _navigateToVerse),
      ),
    );
  }

  void _openAuthors() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BiblicalAuthorsScreen(onOpenVerse: _navigateToVerse),
      ),
    );
  }

  void _openGlobalSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlobalSearchScreen(
          onOpenVerse: _navigateToVerse,
          tourSearchBarKey: _searchBarKey,
        ),
      ),
    );
  }

  void _openTheologicalFilter(String colorKey) {
    setState(() => _index = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _studyKey.currentState?.setHighlightFilter(colorKey);
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          key: _settingsKey,
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
          onOpenVerse: _navigateToVerse,
          onStartInteractiveGuide: () {
            Navigator.of(context).pop();
            startInteractiveTour();
          },
        ),
      ),
    );
  }

  List<TourStepConfig> _buildTourSteps() {
    return TourStepsFactory.getStepsForVersion(
      version: _tourVersionLabel,
      bibleKey: _bibleKey,
      searchBarKey: _searchBarKey,
      dictionaryControlsKey: _dictionaryControlsKey,
      studyTabsKey: _studyTabsKey,
      settingsKey: _settingsKey,
      bibleVerseKeyResolver: () => _bibleKey.currentState?.tourActiveVerseKey,
      bibleAppBarKeyResolver: () => _bibleKey.currentState?.tourAppBarActionsKey,
      settingsReadingKeyResolver: () => _settingsKey.currentState?.tourReadingSectionKey,
      settingsUpdaterKeyResolver: () => _settingsKey.currentState?.tourUpdaterKey,
      settingsReplayGuideKeyResolver: () => _settingsKey.currentState?.tourReplayGuideKey,
      tourDrawerButtonKey: _tourDrawerButtonKey,
      tourBottomNavDictionaryKey: _tourBottomNavDictionaryKey,
      tourBottomNavStudyKey: _tourBottomNavStudyKey,
      tourBookSummaryButtonKey: _tourBookSummaryButtonKey,
      tourDrawerTheologicalKey: _tourDrawerTheologicalKey,
      tourThemeToggleKey: _tourThemeToggleKey,
      onPrepareBibleStep: () async {
        await _bibleKey.currentState?.prepareForInteractiveTourStep1();
      },
      onPrepareSettingsReadingStep: () async {
        final st = _settingsKey.currentState;
        if (st != null) {
          await st.scrollToTourTarget(st.tourReadingSectionKey, alignment: 0.0);
        }
      },
      onPrepareSettingsUpdaterStep: () async {
        final st = _settingsKey.currentState;
        if (st != null) {
          await st.scrollToTourTarget(st.tourUpdaterKey, alignment: 0.12);
        }
      },
      onPrepareSettingsReplayStep: () async {
        final st = _settingsKey.currentState;
        if (st != null) {
          await st.scrollToTourTarget(st.tourReplayGuideKey, alignment: 0.22);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BibleScreen(
        key: _bibleKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        tourDrawerButtonKey: _tourDrawerButtonKey,
        tourBookSummaryButtonKey: _tourBookSummaryButtonKey,
        tourThemeToggleKey: _tourThemeToggleKey,
      ),
      DictionaryScreen(
        initialLanguage: 'greek',
        tourControlsKey: _dictionaryControlsKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      StudyScreen(
        key: _studyKey,
        onOpenVerse: _navigateToVerse,
        tourTabsKey: _studyTabsKey,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: BereaDrawer(
            onOpenBookSummaries: _openBookSummaries,
            onOpenAuthors: _openAuthors,
            onOpenSearch: _openGlobalSearch,
            onSelectTheologicalHighlight: _openTheologicalFilter,
            onOpenSettings: _openSettings,
            onStartTour: startInteractiveTour,
            tourTheologicalKey: _tourDrawerTheologicalKey,
          ),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A3E34)
                      : const Color(0xFFDFCFAF),
                  width: 1.0,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: isDark
                  ? const Color(0xFF1B1613)
                  : const Color(0xFFEDE4CE),
              indicatorColor: isDark
                  ? const Color(0xFF382A1D)
                  : const Color(0xFFE2D3B5),
              selectedIndex: _index,
              onDestinationSelected: (v) => setState(() => _index = v),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Biblia',
                ),
                NavigationDestination(
                  key: _tourBottomNavDictionaryKey,
                  icon: const Icon(Icons.translate_outlined),
                  selectedIcon: const Icon(Icons.translate),
                  label: 'Diccionario',
                ),
                NavigationDestination(
                  key: _tourBottomNavStudyKey,
                  icon: const Icon(Icons.bookmarks_outlined),
                  selectedIcon: const Icon(Icons.bookmarks),
                  label: 'Mi Estudio',
                ),
              ],
            ),
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
