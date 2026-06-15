import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:pub_semver/pub_semver.dart';
import '../app_colors.dart';
import '../l10n/translations.dart';

class WCUpdateService {
  // Optionnel: On peut garder l'ancien système pour des infos ou le supprimer
  static const String _updateUrl = 'https://raw.githubusercontent.com/fnnktkygl-code/mondial_2026/main/web/version.json';

  /// Nouvelle méthode bloquante basée sur Firebase Remote Config
  static Future<bool> isUpdateRequired() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      // Configuration pour la prod : intervalle min d'1 heure pour les vérifications
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();

      // 1. Récupérer la version requise depuis Firebase
      String minVersionString = remoteConfig.getString('min_app_version');
      if (minVersionString.isEmpty) return false;

      // 2. Récupérer la version actuelle de l'appareil
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersionString = packageInfo.version;

      // 3. Comparaison sécurisée avec pub_semver
      Version minVersion = Version.parse(minVersionString);
      Version currentVersion = Version.parse(currentVersionString);

      // Si la version actuelle est strictement inférieure à la version requise
      return currentVersion < minVersion;
    } catch (e) {
      debugPrint("Erreur lors de la vérification de mise à jour (Firebase): $e");
      // En cas d'erreur (pas de réseau, etc.), on ne bloque pas l'utilisateur
      return false;
    }
  }

  /// Récupérer le lien de téléchargement direct de l'APK.
  /// Priorité : Firebase Remote Config → API GitHub (URL directe CDN) → fallback.
  /// L'URL directe CDN évite la chaîne de redirections GitHub qui ouvrirait
  /// la page HTML de la release au lieu de déclencher le téléchargement APK.
  static Future<String> getUpdateUrl() async {
    // 1. Firebase Remote Config (prioritaire)
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final url = remoteConfig.getString('update_url');
      if (url.isNotEmpty) return url;
    } catch (e) {
      debugPrint("Erreur lors de la récupération de update_url (Firebase): $e");
    }

    // 2. API GitHub → URL directe CDN de l'asset APK
    try {
      const apiUrl = 'https://api.github.com/repos/fnnktkygl-code/mondial_2026/releases/latest';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            final downloadUrl = asset['browser_download_url'] as String? ?? '';
            if (downloadUrl.isNotEmpty) {
              debugPrint('URL directe APK depuis GitHub API: $downloadUrl');
              return downloadUrl;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'URL APK via GitHub API: $e');
    }

    // 3. Fallback : URL de redirection (peut ouvrir le navigateur)
    return 'https://github.com/fnnktkygl-code/mondial_2026/releases/latest/download/app-release.apk';
  }

  /// Ancienne méthode non-bloquante (facultative) conservée si vous l'utilisez ailleurs
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
    final latestParts = latestVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    if (latestParts.length > currentParts.length) return true;
    
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
              final uri = Uri.parse(url.trim());
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Impossible d\'ouvrir $uri : $e');
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
