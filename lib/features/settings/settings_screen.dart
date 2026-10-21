import 'package:flutter/material.dart';

import '../../core/update/update_dialog.dart';
import '../../core/update/update_model.dart';
import '../../core/update/update_service.dart';
import '../../data/study_service.dart';
import '../splash/splash_screen.dart';
import '../study/study_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final void Function(String bookId, int chapter, int verse)? onOpenVerse;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.onOpenVerse,
  });

  void _openStudy(
    BuildContext context, {
    required int initialIndex,
    StudyNotesFilter notesFilter = StudyNotesFilter.all,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          onOpenVerse: onOpenVerse,
          initialIndex: initialIndex,
          initialNotesFilter: notesFilter,
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
        final bookmarksCount = StudyService.instance.bookmarks.length;
        final verseNotesCount = StudyService.instance.verseNotes.length;
        final strongNotesCount = StudyService.instance.strongNotes.length;
        final historyCount = StudyService.instance.history.length;
        final isFluentDefault = StudyService.instance.fluentReadingMode;

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Apariencia y Lectura
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Lectura y Visualización',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Modo oscuro'),
                subtitle: const Text('Alterna entre tema claro y tema oscuro'),
                secondary: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => onToggleTheme(),
              ),
              SwitchListTile(
                title: const Text('Modo lectura fluida'),
                subtitle: const Text(
                  'Oculta el interlineal por defecto y subraya discretamente palabras Strong',
                ),
                secondary: const Icon(Icons.auto_stories),
                value: isFluentDefault,
                onChanged: (val) =>
                    StudyService.instance.setFluentReadingMode(val),
              ),

              const Divider(),

              // Estadísticas de datos personales
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Mi Estudio Personal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Marcadores guardados'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$bookmarksCount',
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
                onTap: () => _openStudy(context, initialIndex: 0),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Notas en versículos'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$verseNotesCount',
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
                onTap: () => _openStudy(
                  context,
                  initialIndex: 1,
                  notesFilter: StudyNotesFilter.verses,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Notas en palabras Strong'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$strongNotesCount',
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
                onTap: () => _openStudy(
                  context,
                  initialIndex: 1,
                  notesFilter: StudyNotesFilter.strong,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial de visitas'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$historyCount',
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
                onTap: () => _openStudy(context, initialIndex: 2),
              ),

              const Divider(),

              // Actualizaciones OTA GitHub
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Actualizaciones del Sistema (OTA)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const _UpdaterCard(),

              const Divider(),

              // Información y novedades v1.3
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Acerca de la Aplicación',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Versión instalada'),
                subtitle: Text('Logos K Logos v${UpdateService.instance.currentVersion} • Edición Oficial'),
                leading: const Icon(Icons.info_outline),
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
                        themeMode: themeMode,
                        onToggleTheme: onToggleTheme,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novedades en Versión 1.3:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _featureRow(
                          icon: Icons.system_update_rounded,
                          title: 'Actualizador In-App OTA',
                          desc: 'Detección automática, descarga con barra de progreso e instalación de versiones desde GitHub Releases.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.touch_app,
                          title: 'Accesos directos en Mi Estudio',
                          desc: 'Toca Marcadores, Notas de versículo, Notas Strong o Historial desde Ajustes para abrirlos al instante.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.auto_awesome,
                          title: 'Pantalla de bienvenida',
                          desc: 'Animación inicial elegante con logo, lema de estudio, idiomas y barra de carga fluida.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.link,
                          title: 'Hipervínculos Strong',
                          desc: 'Toca referencias derivadas entre paréntesis (ej: (con 3588)) para abrir ese Strong directamente.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.format_paint,
                          title: 'Dónde aparece desplegable',
                          desc: 'Acordeón por libro con todos los versículos y la palabra resaltada en marcador sin cambiar el color de la fuente.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.bookmark,
                          title: 'Marcadores',
                          desc: 'Guarda tus versículos favoritos con un solo toque.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.edit_note,
                          title: 'Notas personales',
                          desc: 'Anotaciones teológicas por versículo o por palabra Strong.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.history,
                          title: 'Historial',
                          desc: 'Registro automático de las últimas referencias visitadas.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.auto_stories,
                          title: 'Modo lectura fluida',
                          desc: 'Lectura limpia en español con términos Strong subrayados discretamente.',
                          theme: theme,
                        ),
                        _featureRow(
                          icon: Icons.search,
                          title: 'Búsqueda global',
                          desc: 'Búsqueda simultánea en Biblia y diccionarios Strong desde una sola barra.',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const ListTile(
                title: Text('Repositorio Oficial'),
                subtitle: Text('https://github.com/NetOpsSolutions/Logos_K_Logos'),
                leading: Icon(Icons.code_rounded),
              ),
              const ListTile(
                title: Text('Fuentes textuales'),
                subtitle: Text(
                  'BHS (Hebreo), Tischendorf (Griego), Concordancia y Diccionarios Strong, STEPBible',
                ),
                leading: Icon(Icons.source_outlined),
              ),
              const ListTile(
                title: Text('Licencias y créditos'),
                subtitle: Text('Recursos de dominio público y licencias académicas abiertas'),
                leading: Icon(Icons.gavel_outlined),
              ),
            ],
          ),
        );
      },
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

/// Tarjeta interactiva de control para el sistema de actualizaciones OTA
class _UpdaterCard extends StatefulWidget {
  const _UpdaterCard();

  @override
  State<_UpdaterCard> createState() => _UpdaterCardState();
}

class _UpdaterCardState extends State<_UpdaterCard> {
  bool _isChecking = false;

  Future<void> _checkUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final res = await UpdateService.instance.checkForUpdates(isManual: true);

      if (!mounted) return;

      if (res.hasUpdate && res.releaseInfo != null) {
        showUpdateDialog(context, res.releaseInfo!);
      } else if (res.status == UpdateStatus.upToDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(child: Text(res.message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (res.status == UpdateStatus.noReleases) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.lightBlueAccent),
                const SizedBox(width: 12),
                Expanded(child: Text(res.message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(child: Text(res.message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _openDemo() {
    final demoRelease = UpdateService.instance.getSimulatedDemoRelease();
    showUpdateDialog(context, demoRelease, isDemo: true);
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
            color: theme.colorScheme.outlineVariant.withAlpha(120),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(150),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cloud_sync_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text(
                'Buscar actualizaciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Versión actual: v$currentVer • GitHub Releases'),
              trailing: _isChecking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : FilledButton.tonal(
                      onPressed: _checkUpdates,
                      child: const Text('Comprobar'),
                    ),
              onTap: _isChecking ? null : _checkUpdates,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(
                Icons.preview_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
              title: const Text(
                'Probar diálogo de novedades (Demo OTA)',
                style: TextStyle(fontSize: 13.5),
              ),
              subtitle: const Text(
                'Previsualiza la ventana interactiva y la descarga simulada',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _openDemo,
            ),
          ],
        ),
      ),
    );
  }
}
