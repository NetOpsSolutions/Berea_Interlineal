/// Representa la arquitectura de hardware del dispositivo móvil.
class DeviceArchitecture {
  final String primaryAbi;
  final List<String> supportedAbis;
  final String manufacturer;
  final String model;
  final int sdkInt;

  const DeviceArchitecture({
    required this.primaryAbi,
    required this.supportedAbis,
    this.manufacturer = '',
    this.model = '',
    this.sdkInt = 0,
  });

  /// Arquitectura genérica por defecto cuando no se detecta plataforma nativa
  factory DeviceArchitecture.generic() => const DeviceArchitecture(
        primaryAbi: 'arm64-v8a',
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

  factory DeviceArchitecture.fromMap(Map<String, dynamic> map) {
    final primary = (map['primaryAbi'] as String?)?.trim().toLowerCase() ?? 'unknown';
    final abisList = (map['supportedAbis'] as List?)
            ?.map((e) => e.toString().trim().toLowerCase())
            .toList() ??
        [primary];
    return DeviceArchitecture(
      primaryAbi: primary,
      supportedAbis: abisList,
      manufacturer: (map['manufacturer'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
    );
  }

  /// Nombre comercial amigable para mostrar en la interfaz de usuario
  String get readableName {
    switch (primaryAbi) {
      case 'arm64-v8a':
      case 'arm64':
      case 'aarch64':
        return 'ARM 64 bits (arm64-v8a)';
      case 'armeabi-v7a':
      case 'armeabi':
      case 'armv7':
        return 'ARM 32 bits (armeabi-v7a)';
      case 'x86_64':
      case 'x86-64':
        return 'Intel/AMD 64 bits (x86_64)';
      case 'x86':
        return 'Intel/AMD 32 bits (x86)';
      default:
        return primaryAbi.isNotEmpty && primaryAbi != 'unknown'
            ? 'Arquitectura $primaryAbi'
            : 'Arquitectura Universal';
    }
  }

  /// Etiqueta corta para Chips o Insignias visuales
  String get shortTag {
    switch (primaryAbi) {
      case 'arm64-v8a':
      case 'arm64':
      case 'aarch64':
        return 'arm64-v8a';
      case 'armeabi-v7a':
      case 'armeabi':
        return 'armeabi-v7a';
      case 'x86_64':
        return 'x86_64';
      case 'x86':
        return 'x86';
      default:
        return primaryAbi;
    }
  }

  /// Comprueba si este dispositivo puede ejecutar un APK compilado para [apkAbi]
  bool isCompatibleWith(String apkAbi) {
    final cleanApkAbi = apkAbi.toLowerCase().trim();
    if (cleanApkAbi == 'universal') return true;
    if (cleanApkAbi == primaryAbi) return true;
    return supportedAbis.contains(cleanApkAbi);
  }
}

/// Representa un archivo APK adjunto en una release de GitHub con su arquitectura detectada.
class ReleaseApkAsset {
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final String abi; // 'arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86', 'universal'

  const ReleaseApkAsset({
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.abi,
  });

  String get formattedSize => formatBytes(sizeBytes);

  String get readableAbiLabel {
    switch (abi) {
      case 'arm64-v8a':
        return 'ARM 64-bit (Dispositivos modernos)';
      case 'armeabi-v7a':
        return 'ARM 32-bit (Dispositivos estándar)';
      case 'x86_64':
        return 'x86_64 (Emuladores y PCs)';
      case 'x86':
        return 'x86 32-bit (Emuladores)';
      case 'universal':
      default:
        return 'Universal (Todas las arquitecturas)';
    }
  }

  /// Deduce de forma inteligente la arquitectura ABI del archivo APK según su nombre
  static String detectAbiFromFileName(String fileName) {
    final lower = fileName.toLowerCase();

    // 1. x86_64 debe evaluarse antes que x86
    if (lower.contains('x86_64') || lower.contains('x86-64') || lower.contains('amd64')) {
      return 'x86_64';
    }

    // 2. x86 (asegurando que no sea x86_64)
    if (lower.contains('x86')) {
      return 'x86';
    }

    // 3. arm64-v8a
    if (lower.contains('arm64-v8a') ||
        lower.contains('arm64') ||
        lower.contains('aarch64') ||
        lower.contains('v8a')) {
      return 'arm64-v8a';
    }

    // 4. armeabi-v7a
    if (lower.contains('armeabi-v7a') ||
        lower.contains('armeabi') ||
        lower.contains('armv7') ||
        lower.contains('v7a')) {
      return 'armeabi-v7a';
    }

    // 5. Por descarte o APK único universal (ej: app-release.apk, logos_k_logos_1.3.1.apk)
    return 'universal';
  }
}

/// Información detallada de una release publicada en GitHub con soporte multi-arquitectura.
class AppReleaseInfo {
  final String tagName;
  final String version;
  final String title;
  final String releaseNotes;
  final DateTime publishedAt;
  final String htmlUrl;
  final bool isPrerelease;
  final List<ReleaseApkAsset> apkAssets;

  ReleaseApkAsset? _selectedApk;
  DeviceArchitecture? _targetArchitecture;

  AppReleaseInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.releaseNotes,
    required this.publishedAt,
    required this.htmlUrl,
    required this.isPrerelease,
    required this.apkAssets,
    ReleaseApkAsset? selectedApk,
    DeviceArchitecture? targetArchitecture,
  })  : _selectedApk = selectedApk,
        _targetArchitecture = targetArchitecture;

  /// El APK seleccionado específicamente para el dispositivo del usuario
  ReleaseApkAsset? get selectedApk => _selectedApk;
  DeviceArchitecture? get targetArchitecture => _targetArchitecture;

  /// Retorna verdadero si hay un APK compatible para el dispositivo
  bool get hasCompatibleApk => _selectedApk != null;

  /// Propiedades delegadas al APK seleccionado (con fallback seguro)
  String get apkDownloadUrl => _selectedApk?.downloadUrl ?? (apkAssets.isNotEmpty ? apkAssets.first.downloadUrl : '');
  String get apkFileName => _selectedApk?.fileName ?? (apkAssets.isNotEmpty ? apkAssets.first.fileName : '');
  int get apkSizeBytes => _selectedApk?.sizeBytes ?? (apkAssets.isNotEmpty ? apkAssets.first.sizeBytes : 0);
  String get formattedApkSize => formatBytes(apkSizeBytes);
  String get apkAbi => _selectedApk?.abi ?? 'universal';

  /// Asigna y selecciona el APK óptimo según la arquitectura del dispositivo móvil
  ReleaseApkAsset? selectBestApk(DeviceArchitecture deviceArch) {
    _targetArchitecture = deviceArch;
    if (apkAssets.isEmpty) {
      _selectedApk = null;
      return null;
    }

    // 1. Coincidencia exacta con la ABI primaria del dispositivo
    for (final apk in apkAssets) {
      if (apk.abi == deviceArch.primaryAbi) {
        _selectedApk = apk;
        return apk;
      }
    }

    // 2. Coincidencia con alguna ABI secundaria soportada (en orden de preferencia)
    for (final supported in deviceArch.supportedAbis) {
      for (final apk in apkAssets) {
        if (apk.abi == supported) {
          _selectedApk = apk;
          return apk;
        }
      }
    }

    // 3. Fallback a APK Universal (ej: app-release.apk o universal)
    for (final apk in apkAssets) {
      if (apk.abi == 'universal') {
        _selectedApk = apk;
        return apk;
      }
    }

    // 4. Si ningún paquete es compatible con el procesador (evita descarga e instalación rota)
    _selectedApk = null;
    return null;
  }

  /// Construye un [AppReleaseInfo] a partir del payload JSON de la API de GitHub Releases.
  factory AppReleaseInfo.fromGitHubJson(Map<String, dynamic> json, {DeviceArchitecture? deviceArch}) {
    final tag = json['tag_name'] as String? ?? '';
    final cleanVer = tag.replaceFirst(RegExp(r'^[vV]'), '').trim();
    final name = json['name'] as String? ?? 'Versión $cleanVer';
    final body = json['body'] as String? ?? 'No hay notas de la versión disponibles.';
    final publishedStr = json['published_at'] as String?;
    final publishedDate = publishedStr != null
        ? DateTime.tryParse(publishedStr) ?? DateTime.now()
        : DateTime.now();
    final html = json['html_url'] as String? ?? '';
    final prerelease = json['prerelease'] as bool? ?? false;

    // Recolectar todos los assets de extensión .apk
    final assets = json['assets'] as List<dynamic>? ?? [];
    final apkAssets = <ReleaseApkAsset>[];

    for (final item in assets) {
      if (item is Map<String, dynamic>) {
        final aName = item['name'] as String? ?? '';
        if (aName.toLowerCase().endsWith('.apk')) {
          final url = item['browser_download_url'] as String? ?? '';
          final size = (item['size'] as num?)?.toInt() ?? 0;
          final detectedAbi = ReleaseApkAsset.detectAbiFromFileName(aName);

          apkAssets.add(
            ReleaseApkAsset(
              fileName: aName,
              downloadUrl: url,
              sizeBytes: size,
              abi: detectedAbi,
            ),
          );
        }
      }
    }

    final releaseInfo = AppReleaseInfo(
      tagName: tag,
      version: cleanVer.isEmpty ? tag : cleanVer,
      title: name.isEmpty ? 'Versión $tag' : name,
      releaseNotes: body,
      publishedAt: publishedDate,
      htmlUrl: html,
      isPrerelease: prerelease,
      apkAssets: apkAssets,
    );

    if (deviceArch != null) {
      releaseInfo.selectBestApk(deviceArch);
    } else if (apkAssets.isNotEmpty) {
      releaseInfo._selectedApk = apkAssets.first;
    }

    return releaseInfo;
  }
}

/// Estados de comprobación y actualización OTA
enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  incompatibleArchitecture,
  noReleases,
  downloading,
  downloadCompleted,
  permissionRequired,
  installing,
  error,
}

/// Resultado de una verificación de actualización
class UpdateCheckResult {
  final UpdateStatus status;
  final String currentVersion;
  final AppReleaseInfo? releaseInfo;
  final DeviceArchitecture? deviceArchitecture;
  final String message;

  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.releaseInfo,
    this.deviceArchitecture,
    required this.message,
  });

  bool get hasUpdate => status == UpdateStatus.updateAvailable && releaseInfo != null && releaseInfo!.hasCompatibleApk;
  bool get isIncompatible => status == UpdateStatus.incompatibleArchitecture;
}

/// Progreso en tiempo real de la descarga del APK
class DownloadProgress {
  final int receivedBytes;
  final int totalBytes;
  final double progress; // 0.0 a 1.0
  final double speedBytesPerSec;

  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this.speedBytesPerSec,
  });

  String get receivedFormatted => formatBytes(receivedBytes);
  String get totalFormatted => totalBytes > 0 ? formatBytes(totalBytes) : 'Descargando...';
  String get percentFormatted => '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';
  String get speedFormatted {
    if (speedBytesPerSec <= 0) return '';
    return '${formatBytes(speedBytesPerSec.toInt())}/s';
  }
}

/// Helper para formatear bytes a cadenas legibles
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
