import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'update_model.dart';

/// Token para permitir cancelar descargas en curso
class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Servicio integral para actualización In-App (OTA Updater) desde GitHub Releases
/// con autodetección de arquitectura de procesador (ABIs).
class UpdateService extends ChangeNotifier {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  static const String githubOwner = 'NetOpsSolutions';
  static const String githubRepo = 'Logos_K_Logos';
  static const String fallbackVersion = '1.3.0';
  static const int fallbackBuildNumber = 4;

  static const MethodChannel _channel = MethodChannel('com.example.logos_k_logos/updater');

  String _cachedVersion = fallbackVersion;
  int _cachedBuildNumber = fallbackBuildNumber;
  bool _versionQueried = false;

  DeviceArchitecture? _cachedArchitecture;

  UpdateStatus _status = UpdateStatus.idle;
  UpdateCheckResult? _lastResult;
  DownloadProgress? _currentProgress;

  UpdateStatus get status => _status;
  UpdateCheckResult? get lastResult => _lastResult;
  DownloadProgress? get currentProgress => _currentProgress;
  String get currentVersion => _cachedVersion;
  int get currentBuildNumber => _cachedBuildNumber;
  DeviceArchitecture? get currentArchitecture => _cachedArchitecture;

  /// Detecta y obtiene la arquitectura nativa del procesador del dispositivo móvil
  Future<DeviceArchitecture> getDeviceArchitecture() async {
    if (_cachedArchitecture != null) return _cachedArchitecture!;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>('getDeviceArchitecture');
        if (res != null) {
          _cachedArchitecture = DeviceArchitecture.fromMap(res);
          return _cachedArchitecture!;
        }
      } catch (e) {
        debugPrint('[UpdateService] Error consultando arquitectura nativa: $e');
      }
    }

    _cachedArchitecture = DeviceArchitecture.generic();
    return _cachedArchitecture!;
  }

  /// Obtiene la versión actual de la aplicación desde la plataforma nativa
  Future<String> getAppVersion() async {
    if (_versionQueried) return _cachedVersion;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>('getAppVersion');
        if (res != null) {
          final vName = res['versionName'] as String?;
          final vCode = (res['versionCode'] as num?)?.toInt();
          if (vName != null && vName.isNotEmpty) {
            _cachedVersion = vName;
          }
          if (vCode != null && vCode > 0) {
            _cachedBuildNumber = vCode;
          }
          _versionQueried = true;
          return _cachedVersion;
        }
      } catch (e) {
        debugPrint('[UpdateService] Error consultando versión nativa: $e');
      }
    }

    _cachedVersion = fallbackVersion;
    _cachedBuildNumber = fallbackBuildNumber;
    _versionQueried = true;
    return _cachedVersion;
  }

  /// Consulta la API de GitHub Releases para verificar si hay una nueva versión
  /// y autoselecciona el paquete APK que coincide con la arquitectura de la CPU.
  Future<UpdateCheckResult> checkForUpdates({bool isManual = false}) async {
    _status = UpdateStatus.checking;
    notifyListeners();

    await getAppVersion();
    final deviceArch = await getDeviceArchitecture();

    final url = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 12);

      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'LogosKLogos-MobileApp/1.0');

      final response = await request.close().timeout(const Duration(seconds: 12));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final release = AppReleaseInfo.fromGitHubJson(data, deviceArch: deviceArch);

        if (release.apkAssets.isEmpty) {
          final res = UpdateCheckResult(
            status: UpdateStatus.noReleases,
            currentVersion: _cachedVersion,
            releaseInfo: release,
            deviceArchitecture: deviceArch,
            message: 'Hay una versión publicada (${release.tagName}), pero no contiene instaladores APK adjuntos.',
          );
          _lastResult = res;
          _status = UpdateStatus.noReleases;
          notifyListeners();
          return res;
        }

        final isNewer = isRemoteVersionNewer(_cachedVersion, release.version);

        if (isNewer) {
          if (release.hasCompatibleApk) {
            final chosenApk = release.selectedApk!;
            final res = UpdateCheckResult(
              status: UpdateStatus.updateAvailable,
              currentVersion: _cachedVersion,
              releaseInfo: release,
              deviceArchitecture: deviceArch,
              message: '¡Nueva versión ${release.tagName} compatible con tu arquitectura (${chosenApk.abi})!',
            );
            _lastResult = res;
            _status = UpdateStatus.updateAvailable;
            notifyListeners();
            return res;
          } else {
            // Existe nueva versión, pero ninguno de sus APKs es compatible con el procesador del usuario
            final res = UpdateCheckResult(
              status: UpdateStatus.incompatibleArchitecture,
              currentVersion: _cachedVersion,
              releaseInfo: release,
              deviceArchitecture: deviceArch,
              message: 'Hay una versión ${release.tagName} disponible, pero ningún archivo publicado es compatible con tu procesador (${deviceArch.readableName}).',
            );
            _lastResult = res;
            _status = UpdateStatus.incompatibleArchitecture;
            notifyListeners();
            return res;
          }
        } else {
          final res = UpdateCheckResult(
            status: UpdateStatus.upToDate,
            currentVersion: _cachedVersion,
            releaseInfo: release,
            deviceArchitecture: deviceArch,
            message: 'Logos K Logos está actualizado a la última versión disponible (v$_cachedVersion).',
          );
          _lastResult = res;
          _status = UpdateStatus.upToDate;
          notifyListeners();
          return res;
        }
      } else if (response.statusCode == 404) {
        final res = UpdateCheckResult(
          status: UpdateStatus.noReleases,
          currentVersion: _cachedVersion,
          deviceArchitecture: deviceArch,
          message: 'Aún no se han publicado releases en el repositorio oficial de GitHub.',
        );
        _lastResult = res;
        _status = UpdateStatus.noReleases;
        notifyListeners();
        return res;
      } else if (response.statusCode == 403) {
        final res = UpdateCheckResult(
          status: UpdateStatus.error,
          currentVersion: _cachedVersion,
          deviceArchitecture: deviceArch,
          message: 'Límite de solicitudes de la API de GitHub alcanzado temporalmente. Inténtalo más tarde.',
        );
        _lastResult = res;
        _status = UpdateStatus.error;
        notifyListeners();
        return res;
      } else {
        final res = UpdateCheckResult(
          status: UpdateStatus.error,
          currentVersion: _cachedVersion,
          deviceArchitecture: deviceArch,
          message: 'Respuesta inesperada del servidor de actualizaciones (${response.statusCode}).',
        );
        _lastResult = res;
        _status = UpdateStatus.error;
        notifyListeners();
        return res;
      }
    } on SocketException {
      final res = UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: _cachedVersion,
        deviceArchitecture: deviceArch,
        message: 'Sin conexión a internet. Verifica tu red e inténtalo nuevamente.',
      );
      _lastResult = res;
      _status = UpdateStatus.error;
      notifyListeners();
      return res;
    } on TimeoutException {
      final res = UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: _cachedVersion,
        deviceArchitecture: deviceArch,
        message: 'Tiempo de espera agotado al conectar con GitHub Releases.',
      );
      _lastResult = res;
      _status = UpdateStatus.error;
      notifyListeners();
      return res;
    } catch (e) {
      final res = UpdateCheckResult(
        status: UpdateStatus.error,
        currentVersion: _cachedVersion,
        deviceArchitecture: deviceArch,
        message: 'Error al comprobar actualizaciones: $e',
      );
      _lastResult = res;
      _status = UpdateStatus.error;
      notifyListeners();
      return res;
    }
  }

  /// Compara dos cadenas de versión semántica (ej. "1.3.0" vs "1.3.1").
  /// Retorna `true` si [remote] es estrictamente mayor que [current].
  static bool isRemoteVersionNewer(String current, String remote) {
    try {
      final cleanCurrent = current.replaceFirst(RegExp(r'^[vV]'), '').trim();
      final cleanRemote = remote.replaceFirst(RegExp(r'^[vV]'), '').trim();

      final currentParts = _parseVersionParts(cleanCurrent);
      final remoteParts = _parseVersionParts(cleanRemote);

      final maxLen = currentParts.length > remoteParts.length ? currentParts.length : remoteParts.length;

      for (int i = 0; i < maxLen; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final r = i < remoteParts.length ? remoteParts[i] : 0;

        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersionParts(String version) {
    final mainPart = version.split(RegExp(r'[+\-]')).first;
    final parts = mainPart.split('.');
    final result = <int>[];
    for (final p in parts) {
      final parsed = int.tryParse(p) ?? 0;
      result.add(parsed);
    }
    if (version.contains('+')) {
      final buildStr = version.split('+').last;
      final buildNum = int.tryParse(buildStr);
      if (buildNum != null) {
        result.add(buildNum);
      }
    }
    return result;
  }

  /// Descarga el archivo APK en segundo plano con cálculo de progreso y velocidad en tiempo real.
  Future<File?> downloadApk({
    required AppReleaseInfo release,
    required void Function(DownloadProgress) onProgress,
    required CancellationToken cancelToken,
  }) async {
    _status = UpdateStatus.downloading;
    notifyListeners();

    try {
      String cacheDirPath = '';
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final res = await _channel.invokeMethod<String>('getCacheDir');
          if (res != null && res.isNotEmpty) {
            cacheDirPath = res;
          }
        } catch (_) {}
      }

      if (cacheDirPath.isEmpty) {
        cacheDirPath = Directory.systemTemp.path;
      }

      final fileName = release.apkFileName.isNotEmpty
          ? release.apkFileName
          : 'logos_k_logos_${release.version}.apk';
      final file = File('$cacheDirPath/$fileName');

      // Si ya existía un archivo descargado previamente, borrarlo para evitar residuos
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      final uri = Uri.parse(release.apkDownloadUrl);
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 8;
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      request.headers.set(HttpHeaders.userAgentHeader, 'LogosKLogos-MobileApp/1.0');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió con código HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final sink = file.openWrite();

      final stopwatch = Stopwatch()..start();
      int lastBytesSample = 0;
      double speed = 0.0;
      DateTime lastSampleTime = DateTime.now();

      await for (final chunk in response) {
        if (cancelToken.isCancelled) {
          await sink.close();
          if (await file.exists()) {
            await file.delete();
          }
          _status = UpdateStatus.idle;
          notifyListeners();
          return null;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastSampleTime).inMilliseconds;
        if (elapsedMs >= 400) {
          final bytesDiff = receivedBytes - lastBytesSample;
          speed = (bytesDiff / (elapsedMs / 1000.0));
          lastBytesSample = receivedBytes;
          lastSampleTime = now;
        }

        final double prog = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        final p = DownloadProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          progress: prog,
          speedBytesPerSec: speed,
        );
        _currentProgress = p;
        onProgress(p);
      }

      await sink.close();
      stopwatch.stop();

      _status = UpdateStatus.downloadCompleted;
      notifyListeners();
      return file;
    } catch (e) {
      _status = UpdateStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Comprueba si la aplicación tiene permiso para instalar paquetes desconocidos en Android 8.0+.
  Future<bool> canRequestPackageInstalls() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
        return res ?? true;
      } catch (e) {
        debugPrint('[UpdateService] Error comprobando permisos de instalación: $e');
        return true;
      }
    }
    return false;
  }

  /// Abre los Ajustes del sistema operativo para otorgar permiso de instalación desconocida.
  Future<bool> openInstallPermissionSettings() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
        return res ?? false;
      } catch (e) {
        debugPrint('[UpdateService] Error abriendo ajustes de permisos: $e');
        return false;
      }
    }
    return false;
  }

  /// Invoca el instalador nativo del paquete APK descargado.
  Future<bool> installApk(String filePath) async {
    _status = UpdateStatus.installing;
    notifyListeners();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<bool>('installApk', {'filePath': filePath});
        _status = UpdateStatus.idle;
        notifyListeners();
        return res ?? false;
      } catch (e) {
        _status = UpdateStatus.error;
        notifyListeners();
        debugPrint('[UpdateService] Error invocando instalador nativo: $e');
        rethrow;
      }
    } else {
      _status = UpdateStatus.idle;
      notifyListeners();
      throw UnsupportedError('La instalación directa de APK solo es compatible con Android.');
    }
  }

  /// Proporciona una release simulada multi-arquitectura para demostración y verificación de UI.
  AppReleaseInfo getSimulatedDemoRelease({DeviceArchitecture? arch}) {
    final targetArch = arch ?? _cachedArchitecture ?? DeviceArchitecture.generic();

    final assets = [
      const ReleaseApkAsset(
        fileName: 'logos_k_logos_1.3.1_arm64-v8a.apk',
        downloadUrl: 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/download/v1.3.1/logos_k_logos_1.3.1_arm64-v8a.apk',
        sizeBytes: 42467328, // ~40.5 MB
        abi: 'arm64-v8a',
      ),
      const ReleaseApkAsset(
        fileName: 'logos_k_logos_1.3.1_armeabi-v7a.apk',
        downloadUrl: 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/download/v1.3.1/logos_k_logos_1.3.1_armeabi-v7a.apk',
        sizeBytes: 39845888, // ~38.0 MB
        abi: 'armeabi-v7a',
      ),
      const ReleaseApkAsset(
        fileName: 'logos_k_logos_1.3.1_x86_64.apk',
        downloadUrl: 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/download/v1.3.1/logos_k_logos_1.3.1_x86_64.apk',
        sizeBytes: 46137344, // ~44.0 MB
        abi: 'x86_64',
      ),
      const ReleaseApkAsset(
        fileName: 'logos_k_logos_1.3.1_universal.apk',
        downloadUrl: 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/download/v1.3.1/logos_k_logos_1.3.1_universal.apk',
        sizeBytes: 78643200, // ~75.0 MB
        abi: 'universal',
      ),
    ];

    final release = AppReleaseInfo(
      tagName: 'v1.3.1',
      version: '1.3.1',
      title: 'Logos K Logos v1.3.1 - Novedades y Mejoras',
      releaseNotes: '''
## 🚀 Novedades y Correcciones de la Versión 1.3.1

### 🧠 Detección Inteligente de Arquitectura CPU
- La aplicación autodetecta la arquitectura nativa de tu procesador (**${targetArch.readableName}**).
- Descarga exclusivamente el paquete APK compilado para tu CPU, ahorrando datos y evitando fallos de incompatibilidad.

### ✨ Nuevas Características
- **Actualizador In-App OTA**: Descarga e instala futuras versiones directamente desde GitHub Releases sin tiendas externas.
- **Rendimiento**: Carga instantánea de versículos y reducción del consumo de memoria en dispositivos de gama media.

### 🐛 Correcciones de Errores
- Corrección de sincronización de modo lectura fluida al reiniciar.
- Ajuste en el espaciado tipográfico para acentos en griego y cantilaciones en hebreo.
- Optimización de caché de búsqueda global.
''',
      publishedAt: DateTime.now(),
      htmlUrl: 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/latest',
      isPrerelease: false,
      apkAssets: assets,
    );

    release.selectBestApk(targetArch);
    return release;
  }
}
