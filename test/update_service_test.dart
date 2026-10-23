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

  group('DeviceArchitecture & ABI Matching', () {
    test('Deduces ABI accurately from file names', () {
      expect(ReleaseApkAsset.detectAbiFromFileName('app-arm64-v8a-release.apk'), equals('arm64-v8a'));
      expect(ReleaseApkAsset.detectAbiFromFileName('logos_k_logos_1.3.1_arm64.apk'), equals('arm64-v8a'));
      expect(ReleaseApkAsset.detectAbiFromFileName('app-armeabi-v7a-release.apk'), equals('armeabi-v7a'));
      expect(ReleaseApkAsset.detectAbiFromFileName('logos_k_logos_armv7.apk'), equals('armeabi-v7a'));
      expect(ReleaseApkAsset.detectAbiFromFileName('app-x86_64-release.apk'), equals('x86_64'));
      expect(ReleaseApkAsset.detectAbiFromFileName('logos_x86_64.apk'), equals('x86_64'));
      expect(ReleaseApkAsset.detectAbiFromFileName('app-x86-release.apk'), equals('x86'));
      expect(ReleaseApkAsset.detectAbiFromFileName('app-release.apk'), equals('universal'));
      expect(ReleaseApkAsset.detectAbiFromFileName('logos_k_logos_1.3.1.apk'), equals('universal'));
    });

    test('Device compatibility checks', () {
      const arm64Device = DeviceArchitecture(
        primaryAbi: 'arm64-v8a',
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      expect(arm64Device.isCompatibleWith('arm64-v8a'), isTrue);
      expect(arm64Device.isCompatibleWith('armeabi-v7a'), isTrue);
      expect(arm64Device.isCompatibleWith('universal'), isTrue);
      expect(arm64Device.isCompatibleWith('x86_64'), isFalse);
      expect(arm64Device.isCompatibleWith('x86'), isFalse);

      const x86Device = DeviceArchitecture(
        primaryAbi: 'x86_64',
        supportedAbis: ['x86_64', 'x86'],
      );

      expect(x86Device.isCompatibleWith('x86_64'), isTrue);
      expect(x86Device.isCompatibleWith('x86'), isTrue);
      expect(x86Device.isCompatibleWith('arm64-v8a'), isFalse);
    });

    test('Autoselects exact matching APK for ARM 64-bit device', () {
      final assets = [
        const ReleaseApkAsset(
          fileName: 'app-armeabi-v7a-release.apk',
          downloadUrl: 'https://example.com/armv7.apk',
          sizeBytes: 39000000,
          abi: 'armeabi-v7a',
        ),
        const ReleaseApkAsset(
          fileName: 'app-x86_64-release.apk',
          downloadUrl: 'https://example.com/x86_64.apk',
          sizeBytes: 46000000,
          abi: 'x86_64',
        ),
        const ReleaseApkAsset(
          fileName: 'app-arm64-v8a-release.apk',
          downloadUrl: 'https://example.com/arm64.apk',
          sizeBytes: 42000000,
          abi: 'arm64-v8a',
        ),
      ];

      final release = AppReleaseInfo(
        tagName: 'v1.3.1',
        version: '1.3.1',
        title: 'Logos v1.3.1',
        releaseNotes: 'Notas',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://example.com',
        isPrerelease: false,
        apkAssets: assets,
      );

      const arm64Device = DeviceArchitecture(
        primaryAbi: 'arm64-v8a',
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );

      final selected = release.selectBestApk(arm64Device);
      expect(selected, isNotNull);
      expect(selected!.abi, equals('arm64-v8a'));
      expect(selected.fileName, equals('app-arm64-v8a-release.apk'));
    });

    test('Autoselects exact matching APK for x86_64 device (Emulator/PC)', () {
      final assets = [
        const ReleaseApkAsset(
          fileName: 'app-arm64-v8a-release.apk',
          downloadUrl: 'https://example.com/arm64.apk',
          sizeBytes: 42000000,
          abi: 'arm64-v8a',
        ),
        const ReleaseApkAsset(
          fileName: 'app-x86_64-release.apk',
          downloadUrl: 'https://example.com/x86_64.apk',
          sizeBytes: 46000000,
          abi: 'x86_64',
        ),
      ];

      final release = AppReleaseInfo(
        tagName: 'v1.3.1',
        version: '1.3.1',
        title: 'Logos v1.3.1',
        releaseNotes: 'Notas',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://example.com',
        isPrerelease: false,
        apkAssets: assets,
      );

      const x86Device = DeviceArchitecture(
        primaryAbi: 'x86_64',
        supportedAbis: ['x86_64'],
      );

      final selected = release.selectBestApk(x86Device);
      expect(selected, isNotNull);
      expect(selected!.abi, equals('x86_64'));
      expect(selected.fileName, equals('app-x86_64-release.apk'));
    });

    test('Prevents downloading incompatible architecture (e.g. only ARM on x86)', () {
      final assets = [
        const ReleaseApkAsset(
          fileName: 'app-arm64-v8a-release.apk',
          downloadUrl: 'https://example.com/arm64.apk',
          sizeBytes: 42000000,
          abi: 'arm64-v8a',
        ),
      ];

      final release = AppReleaseInfo(
        tagName: 'v1.3.1',
        version: '1.3.1',
        title: 'Logos v1.3.1',
        releaseNotes: 'Notas',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://example.com',
        isPrerelease: false,
        apkAssets: assets,
      );

      const x86Device = DeviceArchitecture(
        primaryAbi: 'x86_64',
        supportedAbis: ['x86_64'],
      );

      final selected = release.selectBestApk(x86Device);
      expect(selected, isNull);
      expect(release.hasCompatibleApk, isFalse);
    });

    test('Falls back to Universal APK when specific split is not present', () {
      final assets = [
        const ReleaseApkAsset(
          fileName: 'app-release.apk',
          downloadUrl: 'https://example.com/universal.apk',
          sizeBytes: 80000000,
          abi: 'universal',
        ),
      ];

      final release = AppReleaseInfo(
        tagName: 'v1.3.1',
        version: '1.3.1',
        title: 'Logos v1.3.1',
        releaseNotes: 'Notas',
        publishedAt: DateTime.now(),
        htmlUrl: 'https://example.com',
        isPrerelease: false,
        apkAssets: assets,
      );

      const armDevice = DeviceArchitecture(
        primaryAbi: 'arm64-v8a',
        supportedAbis: ['arm64-v8a'],
      );

      final selected = release.selectBestApk(armDevice);
      expect(selected, isNotNull);
      expect(selected!.abi, equals('universal'));
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

    test('Simulated demo release autoselects device architecture', () {
      const arm64 = DeviceArchitecture(
        primaryAbi: 'arm64-v8a',
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
      );
      final demo = UpdateService.instance.getSimulatedDemoRelease(arch: arm64);
      expect(demo.tagName, equals('v1.3.1'));
      expect(demo.apkAbi, equals('arm64-v8a'));
      expect(demo.apkFileName, contains('arm64'));
      expect(demo.releaseNotes, contains('arm64-v8a'));
    });
  });
}
