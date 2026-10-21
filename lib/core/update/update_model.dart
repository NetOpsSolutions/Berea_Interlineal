/// Información detallada de una release publicada en GitHub.
class AppReleaseInfo {
  final String tagName;
  final String version;
  final String title;
  final String releaseNotes;
  final DateTime publishedAt;
  final String htmlUrl;
  final String apkDownloadUrl;
  final String apkFileName;
  final int apkSizeBytes;
  final bool isPrerelease;

  const AppReleaseInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.releaseNotes,
    required this.publishedAt,
    required this.htmlUrl,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    required this.isPrerelease,
  });

  /// Tamaño formateado en MB / KB
  String get formattedApkSize => formatBytes(apkSizeBytes);

  /// Construye un [AppReleaseInfo] a partir del payload JSON de la API de GitHub Releases.
  factory AppReleaseInfo.fromGitHubJson(Map<String, dynamic> json) {
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

    // Buscar el asset de extensión .apk
    String apkUrl = '';
    String apkName = 'logos_k_logos_$cleanVer.apk';
    int apkSize = 0;

    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final item in assets) {
      if (item is Map<String, dynamic>) {
        final aName = item['name'] as String? ?? '';
        if (aName.toLowerCase().endsWith('.apk')) {
          apkName = aName;
          apkUrl = item['browser_download_url'] as String? ?? '';
          apkSize = (item['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }
    }

    return AppReleaseInfo(
      tagName: tag,
      version: cleanVer.isEmpty ? tag : cleanVer,
      title: name.isEmpty ? 'Versión $tag' : name,
      releaseNotes: body,
      publishedAt: publishedDate,
      htmlUrl: html,
      apkDownloadUrl: apkUrl,
      apkFileName: apkName,
      apkSizeBytes: apkSize,
      isPrerelease: prerelease,
    );
  }
}

/// Estados de comprobación y actualización OTA
enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
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
  final String message;

  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.releaseInfo,
    required this.message,
  });

  bool get hasUpdate => status == UpdateStatus.updateAvailable && releaseInfo != null;
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
