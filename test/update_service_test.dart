import 'package:flutter_test/flutter_test.dart';
import 'package:logos_k_logos/core/update/update_model.dart';
import 'package:logos_k_logos/core/update/update_service.dart';

void main() {
  group('UpdateService Version Comparison', () {
    test('Correctly identifies newer patch versions', () {
      expect(UpdateService.isRemoteVersionNewer('1.3.0', '1.3.1'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('1.3.0', 'v1.3.1'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('v1.3.0', '1.3.1'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('1.3.0', '1.3.0'), isFalse);
      expect(UpdateService.isRemoteVersionNewer('1.3.1', '1.3.0'), isFalse);
    });

    test('Correctly identifies minor and major version increments', () {
      expect(UpdateService.isRemoteVersionNewer('1.3.0', '1.4.0'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('1.3.5', '2.0.0'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('2.0.0', '1.9.9'), isFalse);
    });

    test('Correctly handles build numbers and suffixes', () {
      expect(UpdateService.isRemoteVersionNewer('1.3.0+4', '1.3.0+5'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('1.3.0+4', '1.3.1+1'), isTrue);
      expect(UpdateService.isRemoteVersionNewer('1.3.0+5', '1.3.0+4'), isFalse);
    });
  });

  group('AppReleaseInfo JSON Parsing', () {
    test('Parses GitHub Releases payload with APK asset correctly', () {
      final json = {
        'tag_name': 'v1.3.1',
        'name': 'Logos K Logos 1.3.1',
        'body': '## Novedades\n- Correcciones y mejoras',
        'published_at': '2026-10-20T12:00:00Z',
        'html_url': 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/tag/v1.3.1',
        'prerelease': false,
        'assets': [
          {
            'name': 'source.tar.gz',
            'browser_download_url': 'https://example.com/source.tar.gz',
            'size': 1024,
          },
          {
            'name': 'logos_k_logos_1.3.1.apk',
            'browser_download_url': 'https://github.com/NetOpsSolutions/Logos_K_Logos/releases/download/v1.3.1/logos_k_logos_1.3.1.apk',
            'size': 47185920,
          }
        ],
      };

      final info = AppReleaseInfo.fromGitHubJson(json);

      expect(info.tagName, equals('v1.3.1'));
      expect(info.version, equals('1.3.1'));
      expect(info.title, equals('Logos K Logos 1.3.1'));
      expect(info.apkFileName, equals('logos_k_logos_1.3.1.apk'));
      expect(info.apkDownloadUrl, contains('.apk'));
      expect(info.apkSizeBytes, equals(47185920));
      expect(info.formattedApkSize, contains('45.0 MB'));
    });
  });

  group('DownloadProgress and Formatters', () {
    test('formatBytes formats units accurately', () {
      expect(formatBytes(500), equals('500 B'));
      expect(formatBytes(1024 * 50), equals('50.0 KB'));
      expect(formatBytes(1024 * 1024 * 20), equals('20.0 MB'));
      expect(formatBytes(1024 * 1024 * 1024 * 2), equals('2.00 GB'));
    });

    test('DownloadProgress calculations', () {
      const p = DownloadProgress(
        receivedBytes: 25000000,
        totalBytes: 50000000,
        progress: 0.5,
        speedBytesPerSec: 2500000,
      );

      expect(p.percentFormatted, equals('50%'));
      expect(p.totalFormatted, contains('47.7 MB'));
      expect(p.speedFormatted, contains('/s'));
    });

    test('Simulated demo release is valid', () {
      final demo = UpdateService.instance.getSimulatedDemoRelease();
      expect(demo.tagName, equals('v1.3.1'));
      expect(demo.apkFileName, endsWith('.apk'));
      expect(demo.releaseNotes, contains('Actualizador In-App OTA'));
    });
  });
}
