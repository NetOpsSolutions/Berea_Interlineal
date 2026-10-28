import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'update_model.dart';
import 'update_service.dart';

bool _isUpdateModalActive = false;

/// Muestra la hoja modal / diálogo interactivo de actualización OTA con soporte multi-arquitectura
Future<void> showUpdateDialog(
  BuildContext context,
  AppReleaseInfo release, {
  bool isDemo = false,
}) async {
  if (_isUpdateModalActive) return;
  _isUpdateModalActive = true;
  try {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateModalSheet(
        release: release,
        isDemo: isDemo || release.isDemo,
      ),
    );
  } finally {
    _isUpdateModalActive = false;
  }
}

class UpdateModalSheet extends StatefulWidget {
  final AppReleaseInfo release;
  final bool isDemo;

  const UpdateModalSheet({
    super.key,
    required this.release,
    this.isDemo = false,
  });

  @override
  State<UpdateModalSheet> createState() => _UpdateModalSheetState();
}

class _UpdateModalSheetState extends State<UpdateModalSheet> {
  UpdateStatus _status = UpdateStatus.idle;
  DownloadProgress? _progress;
  CancellationToken? _cancelToken;
  String? _downloadedApkPath;
  String? _errorMessage;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (!widget.release.hasCompatibleApk) return;

    UpdateService.instance.cancelSystemUpdateNotification();

    setState(() {
      _status = UpdateStatus.downloading;
      _errorMessage = null;
      _cancelToken = CancellationToken();
    });

    if (widget.isDemo) {
      // Simulación visual fluida para modo demostración
      for (int i = 1; i <= 100; i++) {
        if (_cancelToken?.isCancelled ?? false) return;
        await Future.delayed(const Duration(milliseconds: 25));
        if (!mounted) return;
        setState(() {
          _progress = DownloadProgress(
            receivedBytes: (widget.release.apkSizeBytes * (i / 100)).toInt(),
            totalBytes: widget.release.apkSizeBytes,
            progress: i / 100.0,
            speedBytesPerSec: 4.2 * 1024 * 1024,
          );
        });
      }
      if (!mounted) return;
      setState(() {
        _status = UpdateStatus.downloadCompleted;
      });
      return;
    }

    try {
      final file = await UpdateService.instance.downloadApk(
        release: widget.release,
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
        cancelToken: _cancelToken!,
      );

      if (!mounted) return;

      if (file != null && await file.exists()) {
        _downloadedApkPath = file.path;
        setState(() {
          _status = UpdateStatus.downloadCompleted;
        });

        // Intentar instalación automática directa
        _proceedToInstall();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = UpdateStatus.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _status = UpdateStatus.idle;
      _progress = null;
    });
  }

  Future<void> _proceedToInstall() async {
    if (widget.isDemo) {
      Navigator.pop(context);
      AppSnackBar.show(
        context,
        icon: Icons.check_circle_rounded,
        tone: AppSnackBarTone.success,
        message: 'Simulación completada: ${widget.release.apkFileName} (${widget.release.apkAbi}).',
      );
      return;
    }

    if (_downloadedApkPath == null) return;

    if (!kIsWeb && Platform.isAndroid) {
      final canInstall = await UpdateService.instance.canRequestPackageInstalls();
      if (!canInstall) {
        setState(() {
          _status = UpdateStatus.permissionRequired;
        });
        return;
      }
    }

    try {
      setState(() => _status = UpdateStatus.installing);
      await UpdateService.instance.installApk(_downloadedApkPath!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = UpdateStatus.error;
        _errorMessage = 'Error al iniciar la instalación: $e';
      });
    }
  }

  Future<void> _openPermissionSettings() async {
    await UpdateService.instance.openInstallPermissionSettings();
    if (!mounted) return;

    final canInstall = await UpdateService.instance.canRequestPackageInstalls();
    if (canInstall) {
      setState(() {
        _status = UpdateStatus.downloadCompleted;
      });
      _proceedToInstall();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final arch = widget.release.targetArchitecture;
    final isIOS = (!kIsWeb && Platform.isIOS) || theme.platform == TargetPlatform.iOS;
    final isCompatible = isIOS
        ? (widget.release.hasCompatibleIpa || widget.release.htmlUrl.isNotEmpty)
        : widget.release.hasCompatibleApk;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Píldora superior de arrastre
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant.withAlpha(150),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Encabezado con información de versión y arquitectura
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompatible
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer.withAlpha(150),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isIOS
                        ? Icons.phone_iphone_rounded
                        : (isCompatible ? Icons.system_update_rounded : Icons.warning_amber_rounded),
                    size: 30,
                    color: isCompatible
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Nueva Versión ${widget.release.tagName}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.isDemo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF78350F)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFD97706),
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                'DEMO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Insignia de arquitectura detectada o plataforma iOS
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isIOS ? Icons.phone_iphone_rounded : Icons.memory_rounded,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isIOS ? 'iOS (iPhone / iPad)' : (arch != null ? arch.shortTag : 'auto'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isIOS && widget.release.hasCompatibleIpa)
                            Text(
                              widget.release.formattedIpaSize,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else if (!isIOS && isCompatible)
                            Text(
                              widget.release.formattedApkSize,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      if (isIOS && widget.release.hasCompatibleIpa) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.release.ipaFileName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (!isIOS && isCompatible) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.release.apkFileName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Aviso de incompatibilidad si ningún APK coincide con la CPU (sólo Android)
          if (!isIOS && !isCompatible)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withAlpha(120)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phonelink_erase_rounded, color: theme.colorScheme.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta actualización no contiene paquetes compilados para tu procesador (${arch?.readableName ?? "CPU no compatible"}). Para evitar daños o cierres inesperados, la instalación se ha bloqueado.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cuerpo con notas de la versión (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notas de la versión',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ReleaseNotesFormattedView(notes: widget.release.releaseNotes),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Panel de acción según estado
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            child: _buildActionSection(context, theme, isCompatible),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, ThemeData theme, bool isCompatible) {
    final isIOS = (!kIsWeb && Platform.isIOS) || theme.platform == TargetPlatform.iOS;
    if (isIOS) {
      return _buildIosActionSection(context, theme);
    }

    if (!isCompatible) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ),
        ],
      );
    }

    switch (_status) {
      case UpdateStatus.downloading:
        final prog = _progress;
        final percent = prog?.percentFormatted ?? '0%';
        final currentText = prog != null ? '${prog.receivedFormatted} / ${prog.totalFormatted}' : 'Conectando...';
        final speedText = prog?.speedFormatted ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Descargando actualización...',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  percent,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prog?.progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentText,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (speedText.isNotEmpty)
                  Text(
                    speedText,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cancelDownload,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar descarga'),
            ),
          ],
        );

      case UpdateStatus.permissionRequired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Android requiere que autorices la instalación de aplicaciones para Berea Interlineal.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openPermissionSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Autorizar en Ajustes'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _proceedToInstall,
              child: const Text('Ya otorgué el permiso, continuar'),
            ),
          ],
        );

      case UpdateStatus.downloadCompleted:
        final isDark = theme.brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                  width: 0.9,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Descarga de ${widget.release.apkFileName} completada con éxito.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF064E3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _proceedToInstall,
              icon: const Icon(Icons.install_mobile_rounded),
              label: const Text('Instalar Actualización Ahora'),
            ),
          ],
        );

      case UpdateStatus.installing:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                SizedBox(width: 12),
                Text('Lanzando instalador del sistema...'),
              ],
            ),
          ),
        );

      case UpdateStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'Ocurrió un error inesperado al actualizar.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar descarga'),
            ),
          ],
        );

      case UpdateStatus.idle:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(180),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¿Deseas descargar e instalar la versión ${widget.release.version} (${widget.release.formattedApkSize}) ahora?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Más tarde'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Actualizar'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildIosActionSection(BuildContext context, ThemeData theme) {
    final ipaUrl = widget.release.hasCompatibleIpa
        ? widget.release.ipaDownloadUrl
        : widget.release.htmlUrl;
    final hasIpa = widget.release.hasCompatibleIpa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(180),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_iphone_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasIpa
                      ? 'Instalador .ipa (${widget.release.formattedIpaSize}) disponible. En iOS puedes instalarlo fácilmente usando AltStore, Sideloadly o TrollStore.'
                      : 'Puedes descargar la versión ${widget.release.version} directamente desde la página oficial de releases en GitHub.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () async {
                  if (widget.isDemo) {
                    Navigator.pop(context);
                    AppSnackBar.show(
                      context,
                      icon: Icons.check_circle_rounded,
                      tone: AppSnackBarTone.success,
                      message: 'Simulación iOS: Abriendo paquete ${widget.release.ipaFileName.isNotEmpty ? widget.release.ipaFileName : "Berea_Interlineal.ipa"}.',
                    );
                    return;
                  }
                  await UpdateService.instance.openUrl(ipaUrl);
                },
                icon: const Icon(Icons.open_in_browser_rounded),
                label: Text(
                  hasIpa ? 'Descargar .IPA iOS' : 'Ver Release en GitHub',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget interno para renderizar de manera elegante el texto Markdown de notas de la versión.
class _ReleaseNotesFormattedView extends StatelessWidget {
  final String notes;

  const _ReleaseNotesFormattedView({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = notes.split('\n');

    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      // Omitir tablas tecnicas de distribucion y bloques de checksums para el usuario
      if (trimmed.contains('¿Qué paquete descargar?') ||
          trimmed.contains('Verificación de Integridad') ||
          trimmed.contains('SHA-256 Checksums') ||
          trimmed.startsWith('| Archivo') ||
          trimmed.startsWith('|---|') ||
          trimmed.startsWith('| `')) {
        break;
      }

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(4).trim(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              line.substring(3).trim(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(2).trim(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final content = line.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _buildRichInline(content, theme),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildRichInline(line, theme),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichInline(String text, ThemeData theme) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      final isBold = i % 2 == 1;

      spans.add(
        TextSpan(
          text: part,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            height: 1.4,
            fontSize: 13.5,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
