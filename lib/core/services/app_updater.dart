import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Checks GitHub Releases for updates and installs them.
class AppUpdater {
  static const _repo = 'NguyenQuangTrung19/FishCashing';
  static const _assetName = 'FishCash-POS-Windows.zip';

  /// Info about an available update.
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;

  const AppUpdater._({this.latestVersion, this.downloadUrl, this.releaseNotes});

  bool get hasUpdate => downloadUrl != null;

  /// Check GitHub Releases for a newer version.
  static Future<AppUpdater> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.0.0"

      final response = await http
          .get(Uri.parse(
              'https://api.github.com/repos/$_repo/releases/latest'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const AppUpdater._();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tagName'] ?? data['tag_name'] ?? '') as String;
      final latestVersion = tagName.replaceFirst('v', '');

      if (!_isNewer(latestVersion, currentVersion)) {
        return const AppUpdater._();
      }

      // Find the ZIP asset
      final assets = (data['assets'] as List?) ?? [];
      String? downloadUrl;
      for (final asset in assets) {
        final name = (asset as Map<String, dynamic>)['name'] as String?;
        if (name == _assetName) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      return AppUpdater._(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: data['body'] as String?,
      );
    } catch (_) {
      return const AppUpdater._();
    }
  }

  /// Download ZIP, extract, create updater script, launch + exit.
  Future<void> downloadAndInstall({
    required void Function(double progress) onProgress,
  }) async {
    if (downloadUrl == null) return;

    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, 'fishcash_update.zip');
    final extractDir = p.join(tempDir.path, 'fishcash_update');

    // 1. Download ZIP with progress
    final request = http.Request('GET', Uri.parse(downloadUrl!));
    final streamedResponse = await request.send();
    final totalBytes = streamedResponse.contentLength ?? 0;
    var receivedBytes = 0;

    final sink = File(zipPath).openWrite();
    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    // 2. Extract ZIP
    final extractPath = Directory(extractDir);
    if (extractPath.existsSync()) {
      extractPath.deleteSync(recursive: true);
    }
    extractPath.createSync(recursive: true);

    final zipBytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      final outPath = p.join(extractDir, file.name);
      if (file.isFile) {
        final outFile = File(outPath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }

    // 3. Create updater batch script
    final appDir = p.dirname(Platform.resolvedExecutable);
    final batPath = p.join(tempDir.path, 'fishcash_updater.bat');

    final batContent = '''
@echo off
echo ========================================
echo   FishCash POS - Dang cap nhat...
echo ========================================
echo.

:: Wait for app to close
timeout /t 3 /nobreak > nul

:: Copy new files
xcopy /s /y /q "$extractDir\\*" "$appDir\\"

:: Clean up
rmdir /s /q "$extractDir"
del "$zipPath"

:: Restart app
start "" "$appDir\\fishcash_pos.exe"

:: Self-delete
del "%~f0"
''';

    await File(batPath).writeAsString(batContent);

    // 4. Launch updater and exit app
    await Process.start(
      'cmd',
      ['/c', batPath],
      mode: ProcessStartMode.detached,
    );

    exit(0);
  }

  /// Compare versions: returns true if remote > current.
  static bool _isNewer(String remote, String current) {
    final r = remote.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? (r[i] ?? 0) : 0;
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }
}
