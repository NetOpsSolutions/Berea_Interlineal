import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/tour/tour_steps_factory.dart';
import '../../core/update/update_dialog.dart';
import '../../core/update/update_model.dart';
import '../../core/update/update_service.dart';
import '../../data/study_service.dart';
import '../splash/splash_screen.dart';
import '../study/study_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;
  final VoidCallback? onStartInteractiveGuide;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.onOpenVerse,
    this.onStartInteractiveGuide,
  });

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey tourReadingSectionKey = GlobalKey(debugLabel: 'tourSettingsReading');
  final GlobalKey tourUpdaterKey = GlobalKey(debugLabel: 'tourSettingsUpdater');
  final GlobalKey tourReplayGuideKey = GlobalKey(debugLabel: 'tourReplayGuide');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Desplaza suavemente la vista de Ajustes hasta dejar visible el bloque requerido por la guía
  Future<void> scrollToTourTarget(GlobalKey targetKey, {double alignment = 0.08}) async {
    if (!mounted) return;
    final ctx = targetKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: alignment,
      );
    }
  }

  void _openStudy(
    BuildContext context, {
    required int initialIndex,
    StudyNotesFilter notesFilter = StudyNotesFilter.all,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          onOpenVerse: widget.onOpenVerse,
          initialIndex: initialIndex,
          initialNotesFilter: notesFilter,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: StudyService.instance,
      builder: (context, _) {
        final study = StudyService.instance;
        final bookmarksCount = study.bookmarks.length;
        final highlightsCount = study.highlights.length;
        final verseNotesCount = study.verseNotes.length;
        final strongNotesCount = study.strongNotes.length;
        final historyCount = study.history.length;
        final isFluentDefault = study.fluentReadingMode;
        final isChapterMode = study.chapterReadingMode;
        final scale = study.readingFontScale;
        final scalePercent = (scale * 100).round();
        final currentVersion = UpdateService.instance.currentVersion;

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Bloque: Lectura y Visualización ──────────────────────────
                Column(
                  key: tourReadingSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(theme, 'Lectura y Visualización'),
                    SwitchListTile(
                      title: const Text('Modo oscuro'),
                      subtitle: const Text('Alterna entre tema claro y tema oscuro'),
                      secondary: Icon(
                        widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                      ),
                      value: widget.themeMode == ThemeMode.dark,
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                    SwitchListTile(
                      title: const Text('Lectura por capítulo completo'),
                      subtitle: const Text(
                        'Vista corrida con scroll vertical fluido, swipe lateral e interlineal expandible',
                      ),
                      secondary: const Icon(Icons.menu_book_rounded),
                      value: isChapterMode,
                      onChanged: (val) => study.setChapterReadingMode(val),
                    ),
                    SwitchListTile(
                      title: const Text('Modo lectura fluida'),
                      subtitle: const Text(
                        'Oculta el interlineal por defecto y subraya discretamente palabras Strong',
                      ),
                      secondary: const Icon(Icons.auto_stories),
                      value: isFluentDefault,
                      onChanged: (val) => study.setFluentReadingMode(val),
                    ),
                  ],
                ),

                // Control de tamaño de fuente y fuentes académicas SIL OFL
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_size_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tamaño de letra bíblica',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$scalePercent%',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: scale,
                            min: 0.85,
                            max: 1.45,
                            divisions: 12,
                            label: '$scalePercent%',
                            onChanged: (v) => study.setReadingFontScale(v),
                          ),
                          const Divider(height: 16),
                          Text(
                            'Tipografía Hebrea (Antiguo Testamento)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: AcademicFonts.hebrewOptions
                                .map((o) => ButtonSegment(
                                      value: o.family,
                                      label: Text(o.name, style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            selected: {study.hebrewFontFamily},
                            onSelectionChanged: (s) => study.setHebrewFontFamily(s.first),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                AcademicFonts.hebrewOptions.first.sampleText,
                                style: study.originalScriptStyle(
                                  isHebrew: true,
                                  fontSize: 19,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tipografía Griega (Nuevo Testamento)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: AcademicFonts.greekOptions
                                .map((o) => ButtonSegment(
                                      value: o.family,
                                      label: Text(o.name, style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            selected: {study.greekFontFamily},
                            onSelectionChanged: (s) => study.setGreekFontFamily(s.first),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha(140),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AcademicFonts.greekOptions.first.sampleText,
                              style: study.originalScriptStyle(
                                isHebrew: false,
                                fontSize: 17,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // ── 2. Bloque: Mi Estudio Personal ──────────────────────────────
                _buildSectionHeader(theme, 'Mi Estudio Personal'),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.bookmark_outline,
                  title: 'Marcadores guardados',
                  count: bookmarksCount,
                  onTap: () => _openStudy(context, initialIndex: 0),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.palette_outlined,
                  title: 'Versículos resaltados',
                  count: highlightsCount,
                  onTap: () => _openStudy(context, initialIndex: 1),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.edit_note,
                  title: 'Notas en versículos',
                  count: verseNotesCount,
                  onTap: () => _openStudy(
                    context,
                    initialIndex: 2,
                    notesFilter: StudyNotesFilter.verses,
                  ),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.translate,
                  title: 'Notas en palabras Strong',
                  count: strongNotesCount,
                  onTap: () => _openStudy(
                    context,
                    initialIndex: 2,
                    notesFilter: StudyNotesFilter.strong,
                  ),
                ),
                _buildStudyCounterTile(
                  theme: theme,
                  icon: Icons.history,
                  title: 'Historial de visitas',
                  count: historyCount,
                  onTap: () => _openStudy(context, initialIndex: 3),
                ),

                const Divider(),

                // ── 3. Bloque: Acerca de la Aplicación ──────────────────────────
                _buildSectionHeader(theme, 'Acerca de la Aplicación'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versión instalada'),
                  subtitle: Text('Berea Interlineal v$currentVersion • Edición Oficial'),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Ver animación de bienvenida'),
                  subtitle: const Text('Reproducir presentación de inicio y logo'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplashScreen(
                          themeMode: widget.themeMode,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  key: tourReplayGuideKey,
                  leading: const Icon(Icons.explore_outlined),
                  title: const Text('Ver guía de uso'),
                  subtitle: const Text(
                    'Iniciar recorrido interactivo animado de la versión',
                  ),
                  onTap: widget.onStartInteractiveGuide,
                ),

                // ── 4. Tarjeta de Novedades Limpia (Específica de la versión) ───
                _buildCleanVersionFeaturesCard(theme, currentVersion),

                const Divider(),

                // ── 5. Bloque: Centro de Actualizaciones Oficial ────────────────
                Column(
                  key: tourUpdaterKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(theme, 'Actualizaciones del Sistema'),
                    const _UpdaterCard(),
                  ],
                ),

                const Divider(),

                // ── 6. Bloque: Recursos y Licencias ─────────────────────────────
                _buildSectionHeader(theme, 'Recursos y Licencias'),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Repositorio Oficial'),
                  subtitle: const Text('https://github.com/NetOpsSolutions/Berea_Interlineal'),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  onTap: () {
                    UpdateService.instance.openUrl(
                      'https://github.com/NetOpsSolutions/Berea_Interlineal',
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.source_outlined),
                  title: Text('Fuentes textuales y tipográficas'),
                  subtitle: Text(
                    'BHS (Hebreo), Tischendorf (Griego), Strong, STEPBible • Tipografías Ezra SIL, Gentium Plus, Cardo y Frank Ruhl Libre (SIL OFL)',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('Licencias y créditos'),
                  subtitle: Text('Recursos de dominio público y licencias académicas abiertas'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye la tarjeta concisa de hitos propios de [rawVersion] (sin listas acumuladas).
  Widget _buildCleanVersionFeaturesCard(ThemeData theme, String rawVersion) {
    final cleanVer = TourStepsFactory.normalizeVersion(rawVersion);
    final items = _featuresForVersion(cleanVer);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Novedades en Versión ${cleanVer.isEmpty ? rawVersion : cleanVer}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in items)
                _featureRow(
                  icon: item.icon,
                  title: item.title,
                  desc: item.desc,
                  theme: theme,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_VersionFeatureItem> _featuresForVersion(String cleanVer) {
    switch (cleanVer) {
      case '1.3.0':
        return const [
          _VersionFeatureItem(
            icon: Icons.play_circle_outline,
            title: 'Presentación Oficial y Arranque Ágil',
            desc: 'Animación solemne de bienvenida con carga rápida de manuscritos offline.',
          ),
          _VersionFeatureItem(
            icon: Icons.menu_book_rounded,
            title: 'Lectura Bíblica Interlineal',
            desc: 'Texto en Hebreo, Griego y Español palabra por palabra con fonética y morfología.',
          ),
          _VersionFeatureItem(
            icon: Icons.search_rounded,
            title: 'Búsqueda Global y Léxicos Strong',
            desc: 'Consulta instantánea de citas bíblicas, palabras clave y raíces del AT y NT.',
          ),
          _VersionFeatureItem(
            icon: Icons.bookmarks_rounded,
            title: 'Mi Estudio y Modo Oscuro',
            desc: 'Marcadores, notas personales e historial con tema oscuro cómodo por defecto.',
          ),
          _VersionFeatureItem(
            icon: Icons.explore_rounded,
            title: 'Guía Interactiva de Uso',
            desc: 'Recorrido animado en el primer inicio y disponible bajo demanda en Ajustes.',
          ),
        ];

      case '1.3.1':
        return const [
          _VersionFeatureItem(
            icon: Icons.storage_rounded,
            title: 'Persistencia Permanente SQLite ACID',
            desc: 'Base dedicada logos_user_data.db que conserva notas y marcadores ante reinicios.',
          ),
          _VersionFeatureItem(
            icon: Icons.sync_rounded,
            title: 'Migrador Automático sin Pérdida',
            desc: 'Importación transparente al instante de tus favoritos previos hacia SQLite.',
          ),
          _VersionFeatureItem(
            icon: Icons.link_rounded,
            title: 'Hipervínculos entre Códigos Strong',
            desc: 'Enlaces táctiles en palabras derivadas para saltar directo a su raíz léxica.',
          ),
          _VersionFeatureItem(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Concordancia «Dónde Aparece»',
            desc: 'Ocurrencias agrupadas en acordeón por libro bíblico con resaltado nítido.',
          ),
          _VersionFeatureItem(
            icon: Icons.system_update_rounded,
            title: 'Actualizador OTA Multi-Procesador',
            desc: 'Detección automática de CPU (arm64-v8a, armeabi-v7a, x86_64) con barra de progreso.',
          ),
        ];

      case '1.3.2':
      default:
        return const [
          _VersionFeatureItem(
            icon: Icons.verified_rounded,
            title: 'Identidad Oficial Berea Interlineal',
            desc: 'Nuevo logotipo inspirado en Hechos 17:11 con Biblia iluminada y lupa exegética.',
          ),
          _VersionFeatureItem(
            icon: Icons.menu_book_rounded,
            title: 'Lectura por Capítulo Completo y Swipe',
            desc: 'Scroll continuo con expansión interlineal al toque y gestos laterales entre capítulos.',
          ),
          _VersionFeatureItem(
            icon: Icons.text_fields_rounded,
            title: 'Tipografías Académicas SIL OFL',
            desc: 'Fuentes Ezra SIL, Frank Ruhl Libre, Cardo y Gentium Plus con selector «TT».',
          ),
          _VersionFeatureItem(
            icon: Icons.palette_rounded,
            title: '5 Resaltadores Teológicos',
            desc: 'Clasifica versículos o frases en Promesas, Mandamientos, Atributos, Advertencias y Profecía.',
          ),
          _VersionFeatureItem(
            icon: Icons.notifications_active_outlined,
            title: 'Notificaciones Nativas y Contraste AAA',
            desc: 'Avisos de actualización en la bandeja de Android con legibilidad óptima claro/oscuro.',
          ),
          _VersionFeatureItem(
            icon: Icons.explore_rounded,
            title: 'Guía de Uso Interactiva Contextual',
            desc: 'Recorrido animado automático tras actualizar, repetible siempre en «Ver guía de uso».',
          ),
        ];
    }
  }

  Widget _buildStudyCounterTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionFeatureItem {
  final IconData icon;
  final String title;
  final String desc;

  const _VersionFeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

/// Tarjeta limpia de producción para el sistema de actualizaciones OTA (sin simuladores)
class _UpdaterCard extends StatefulWidget {
  const _UpdaterCard();

  @override
  State<_UpdaterCard> createState() => _UpdaterCardState();
}

class _UpdaterCardState extends State<_UpdaterCard> {
  bool _isChecking = false;
  DeviceArchitecture? _arch;
  DateTime? _lastCheckedAt;

  @override
  void initState() {
    super.initState();
    UpdateService.instance.getDeviceArchitecture().then((arch) {
      if (mounted) setState(() => _arch = arch);
    });
  }

  String _formatCheckTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd/$mo/${dt.year} $hh:$mm';
  }

  Future<void> _checkUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final res = await UpdateService.instance.checkForUpdates(isManual: true);

      if (!mounted) return;
      setState(() => _lastCheckedAt = DateTime.now());

      if (res.hasUpdate && res.releaseInfo != null) {
        await UpdateService.instance.showSystemUpdateNotification(
          res.releaseInfo!,
          force: true,
        );
        if (!mounted) return;
        showUpdateDialog(context, res.releaseInfo!);
      } else if (res.isIncompatible) {
        AppSnackBar.show(
          context,
          icon: Icons.phonelink_erase_rounded,
          tone: AppSnackBarTone.warning,
          message: res.message,
          duration: const Duration(seconds: 6),
        );
      } else if (res.status == UpdateStatus.upToDate) {
        AppSnackBar.show(
          context,
          icon: Icons.check_circle_rounded,
          tone: AppSnackBarTone.success,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      } else if (res.status == UpdateStatus.noReleases) {
        AppSnackBar.show(
          context,
          icon: Icons.info_outline_rounded,
          tone: AppSnackBarTone.info,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      } else {
        AppSnackBar.show(
          context,
          icon: Icons.warning_amber_rounded,
          tone: AppSnackBarTone.warning,
          message: res.message,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentVer = UpdateService.instance.currentVersion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(140),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buscar actualizaciones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Versión actual: v$currentVer • GitHub Releases',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.memory_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _arch != null
                                    ? 'CPU: ${_arch!.readableName}'
                                    : 'Detectando arquitectura...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_lastCheckedAt != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Última verificación: ${_formatCheckTime(_lastCheckedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _isChecking ? null : _checkUpdates,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.system_update_rounded, size: 19),
                  label: Text(
                    _isChecking ? 'Comprobando en GitHub...' : 'Comprobar actualizaciones',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
