import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants.dart';

class AppReleaseInfo {
  final String tagName;
  final String releaseNotes;
  final String apkDownloadUrl;
  final bool isNewerVersion;

  AppReleaseInfo({
    required this.tagName,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.isNewerVersion,
  });
}

class UpdateService {
  static Future<AppReleaseInfo?> checkForUpdates() async {
    try {
      final repo = Constants.githubRepo;
      final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
      final response = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final tagName = data['tag_name']?.toString() ?? '';
      final body = data['body']?.toString() ?? 'Bug fixes and performance improvements.';
      
      String apkUrl = '';
      final assets = data['assets'] as List?;
      if (assets != null) {
        for (final asset in assets) {
          final name = asset['name']?.toString() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url']?.toString() ?? '';
            break;
          }
        }
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final cleanLatest = tagName.replaceAll('v', '').trim();
      final isNewer = _isVersionNewer(cleanLatest, currentVersion);

      return AppReleaseInfo(
        tagName: tagName,
        releaseNotes: body,
        apkDownloadUrl: apkUrl,
        isNewerVersion: isNewer,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isVersionNewer(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }
}
