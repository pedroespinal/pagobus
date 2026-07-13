import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;

  const UpdateInfo({required this.version, required this.downloadUrl});
}

class UpdateService {
  UpdateService._internal();
  static final UpdateService instance = UpdateService._internal();

  /// GitHub repo that hosts PagoBus releases.
  static const String repoOwner = 'pedroespinal';
  static const String repoName = 'pagobus';

  Uri get _latestReleaseUri => Uri.parse(
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest');

  /// Returns update info if a newer release is available on GitHub, or
  /// null if the app is already up to date (or the check failed, e.g. offline).
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(_latestReleaseUri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?) ?? '';
      final remoteVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      if (remoteVersion.isEmpty) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (!_isNewer(remoteVersion, currentVersion)) return null;

      String downloadUrl = data['html_url'] as String? ??
          'https://github.com/$repoOwner/$repoName/releases/latest';
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        final apkAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
          orElse: () => null,
        );
        if (apkAsset != null) {
          downloadUrl = apkAsset['browser_download_url'] as String;
        }
      }

      return UpdateInfo(version: remoteVersion, downloadUrl: downloadUrl);
    } catch (_) {
      return null;
    }
  }

  bool _isNewer(String remote, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();

    final remoteParts = parse(remote);
    final currentParts = parse(current);
    final length = remoteParts.length > currentParts.length
        ? remoteParts.length
        : currentParts.length;

    for (var i = 0; i < length; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r != c) return r > c;
    }
    return false;
  }
}
