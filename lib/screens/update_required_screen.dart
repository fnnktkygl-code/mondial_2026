import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../services/update_service.dart';

class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _isLoading = false;

  Future<void> _launchUpdateUrl() async {
    setState(() => _isLoading = true);
    try {
      final String updateUrl = await WCUpdateService.getUpdateUrl();
      final Uri uri = Uri.parse(updateUrl.trim());

      bool launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        debugPrint('Impossible d\'ouvrir $uri');
      }
    } catch (e) {
      debugPrint('Erreur lors du lancement de la mise à jour: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.system_update, size: 80, color: AppColors.accent),
                const SizedBox(height: 24),
                const Text(
                  "Mise à jour requise",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Une nouvelle version importante de Prono Challenge est disponible. Vous devez la télécharger pour continuer à pronostiquer !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _launchUpdateUrl,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.background,
                          ),
                        )
                      : const Text(
                          "Accéder à la dernière version",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
