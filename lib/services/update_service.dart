import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../l10n/translations.dart';

class WCUpdateService {
  // Replace this with your actual GitHub Pages URL
  static const String _updateUrl = 'https://raw.githubusercontent.com/fnnktkygl-code/mondial_2026/main/web/version.json';

  static Future<void> checkUpdate(BuildContext context, String lang) async {
    try {
      final response = await http.get(Uri.parse(_updateUrl));
      if (!context.mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = data['version'] ?? '1.0.0';
        final int latestBuild = int.tryParse(data['buildNumber']?.toString() ?? '0') ?? 0;
        final String downloadUrl = data['url'] ?? '';
        final String releaseNotes = data['releaseNotes']?[lang] ?? data['releaseNotes']?['en'] ?? '';

        final packageInfo = await PackageInfo.fromPlatform();
        if (!context.mounted) return;
        final currentVersion = packageInfo.version;
        final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

        if (_isNewer(latestVersion, latestBuild, currentVersion, currentBuild)) {
          if (context.mounted) {
            _showUpdateDialog(context, lang, latestVersion, releaseNotes, downloadUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isNewer(String latestVersion, int latestBuild, String currentVersion, int currentBuild) {
    // Basic version comparison: simple string check or split by dot
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    if (latestParts.length > currentParts.length) return true;
    
    // If versions are same, check build number
    return latestBuild > currentBuild;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String lang,
    String version,
    String notes,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AppColors.accent),
            const SizedBox(width: 12),
            Text(
              AppTranslations.get(lang, 'updateAvailableTitle'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppTranslations.get(lang, 'version')} $version',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            if (notes.isNotEmpty)
              Text(
                notes,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.get(lang, 'later'),
              style: const TextStyle(color: AppColors.textDim),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: Text(AppTranslations.get(lang, 'updateNow')),
          ),
        ],
      ),
    );
  }
}
