import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/update/update_dialog.dart';
import '../core/update/update_service.dart';
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
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final GlobalKey<BibleScreenState> _bibleKey = GlobalKey<BibleScreenState>();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _scheduleSilentUpdateCheck();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _scheduleSilentUpdateCheck() {
    // Evitar temporizadores asíncronos pendientes durante pruebas unitarias
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _updateTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Colors.amberAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Nueva versión ${release.tagName} disponible'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VER NOVEDADES',
              textColor: Colors.amberAccent,
              onPressed: () {
                showUpdateDialog(context, release);
              },
            ),
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      BibleScreen(key: _bibleKey),
      GlobalSearchScreen(onOpenVerse: _navigateToVerse),
      const DictionaryScreen(initialLanguage: 'greek'),
      StudyScreen(onOpenVerse: _navigateToVerse),
      SettingsScreen(
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
        onOpenVerse: _navigateToVerse,
      ),
    ];

    return Scaffold(
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
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Mi Estudio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
