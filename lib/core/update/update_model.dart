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
  final String apiUrl;
  final int sizeBytes;
  final String abi; // 'arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86', 'universal'

  const ReleaseApkAsset({
    required this.fileName,
    required this.downloadUrl,
    this.apiUrl = '',
    required this.sizeBytes,
    required this.abi,
  });

  String get formattedSize => formatBytes(sizeBytes);

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'apiUrl': apiUrl,
        'sizeBytes': sizeBytes,
        'abi': abi,
      };

  factory ReleaseApkAsset.fromMap(Map<String, dynamic> map) => ReleaseApkAsset(
        fileName: map['fileName']?.toString() ?? '',
        downloadUrl: map['downloadUrl']?.toString() ?? '',
        apiUrl: map['apiUrl']?.toString() ?? '',
        sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
        abi: map['abi']?.toString() ?? 'universal',
      );

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

/// Representa un paquete instalador .ipa para iOS (iPhone / iPad) adjunto en una release de GitHub.
class ReleaseIpaAsset {
  final String fileName;
  final String downloadUrl;
  final String apiUrl;
  final int sizeBytes;

  const ReleaseIpaAsset({
    required this.fileName,
    required this.downloadUrl,
    this.apiUrl = '',
    required this.sizeBytes,
  });

  String get formattedSize => formatBytes(sizeBytes);

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'apiUrl': apiUrl,
        'sizeBytes': sizeBytes,
      };

  factory ReleaseIpaAsset.fromMap(Map<String, dynamic> map) => ReleaseIpaAsset(
        fileName: map['fileName']?.toString() ?? '',
        downloadUrl: map['downloadUrl']?.toString() ?? '',
        apiUrl: map['apiUrl']?.toString() ?? '',
        sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      );
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
  final bool isDemo;
  final List<ReleaseApkAsset> apkAssets;
  final ReleaseIpaAsset? ipaAsset;

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
    this.isDemo = false,
    required this.apkAssets,
    this.ipaAsset,
    ReleaseApkAsset? selectedApk,
    DeviceArchitecture? targetArchitecture,
  })  : _selectedApk = selectedApk,
        _targetArchitecture = targetArchitecture;

  /// El APK seleccionado específicamente para el dispositivo del usuario
  ReleaseApkAsset? get selectedApk => _selectedApk;
  DeviceArchitecture? get targetArchitecture => _targetArchitecture;

  /// Retorna verdadero si hay un APK compatible para el dispositivo
  bool get hasCompatibleApk => _selectedApk != null;

  /// Retorna verdadero si existe un instalador para iOS (.ipa) en la release
  bool get hasCompatibleIpa => ipaAsset != null;

  /// Propiedades delegadas al instalador .ipa para iOS
  String get ipaDownloadUrl => ipaAsset?.downloadUrl ?? '';
  String get ipaFileName => ipaAsset?.fileName ?? '';
  int get ipaSizeBytes => ipaAsset?.sizeBytes ?? 0;
  String get formattedIpaSize => ipaAsset != null ? ipaAsset!.formattedSize : '';

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

    // Recolectar todos los assets de extensión .apk y paquetes .ipa para iOS
    final assets = json['assets'] as List<dynamic>? ?? [];
    final apkAssets = <ReleaseApkAsset>[];
    ReleaseIpaAsset? ipaAsset;

    for (final item in assets) {
      if (item is Map<String, dynamic>) {
        final aName = item['name'] as String? ?? '';
        final url = item['browser_download_url'] as String? ?? '';
        final apiUrl = item['url'] as String? ?? '';
        final size = (item['size'] as num?)?.toInt() ?? 0;

        if (aName.toLowerCase().endsWith('.apk')) {
          final detectedAbi = ReleaseApkAsset.detectAbiFromFileName(aName);
          apkAssets.add(
            ReleaseApkAsset(
              fileName: aName,
              downloadUrl: url,
              apiUrl: apiUrl,
              sizeBytes: size,
              abi: detectedAbi,
            ),
          );
        } else if (aName.toLowerCase().endsWith('.ipa')) {
          ipaAsset = ReleaseIpaAsset(
            fileName: aName,
            downloadUrl: url,
            apiUrl: apiUrl,
            sizeBytes: size,
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
      ipaAsset: ipaAsset,
    );

    if (deviceArch != null) {
      releaseInfo.selectBestApk(deviceArch);
    } else if (apkAssets.isNotEmpty) {
      releaseInfo._selectedApk = apkAssets.first;
    }

    return releaseInfo;
  }

  /// Resumen limpio en texto plano para mostrar en el Centro de Notificaciones de Android
  String get plainNotesPreview {
    final lines = releaseNotes
        .split('\n')
        .map((l) => l
            .replaceAll(RegExp(r'^#+\s*'), '')
            .replaceAll('**', '')
            .replaceAll(RegExp(r'^[\-\*]\s+'), '• ')
            .trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .toList();
    if (lines.isEmpty) {
      return 'Incluye mejoras de rendimiento, experiencia de lectura y herramientas de estudio.';
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toMap() => {
        'tagName': tagName,
        'version': version,
        'title': title,
        'releaseNotes': releaseNotes,
        'publishedAt': publishedAt.toIso8601String(),
        'htmlUrl': htmlUrl,
        'isPrerelease': isPrerelease,
        'isDemo': isDemo,
        'apkAssets': apkAssets.map((a) => a.toMap()).toList(),
        if (ipaAsset != null) 'ipaAsset': ipaAsset!.toMap(),
      };

  factory AppReleaseInfo.fromPersistedMap(
    Map<String, dynamic> map, {
    DeviceArchitecture? deviceArch,
  }) {
    final rawAssets = map['apkAssets'] as List<dynamic>? ?? const [];
    final assets = rawAssets
        .whereType<Map>()
        .map((m) => ReleaseApkAsset.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final ipaMap = map['ipaAsset'] as Map<String, dynamic>?;
    final ipaAsset = ipaMap != null ? ReleaseIpaAsset.fromMap(ipaMap) : null;

    final info = AppReleaseInfo(
      tagName: map['tagName']?.toString() ?? '',
      version: map['version']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      releaseNotes: map['releaseNotes']?.toString() ?? '',
      publishedAt: DateTime.tryParse(map['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      htmlUrl: map['htmlUrl']?.toString() ?? '',
      isPrerelease: map['isPrerelease'] == true,
      isDemo: map['isDemo'] == true,
      apkAssets: assets,
      ipaAsset: ipaAsset,
    );

    if (deviceArch != null) {
      info.selectBestApk(deviceArch);
    } else if (assets.isNotEmpty) {
      info._selectedApk = assets.first;
    }
    return info;
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
