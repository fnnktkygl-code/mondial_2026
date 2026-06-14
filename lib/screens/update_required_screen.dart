import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';

class UpdateRequiredScreen extends StatelessWidget {
  // Remplacez par le lien de téléchargement de votre APK ou de votre page GitHub
  final String updateUrl = "https://github.com/fnnktkygl-code/mondial_2026/releases";

  const UpdateRequiredScreen({super.key});

  Future<void> _launchUpdateUrl() async {
    final Uri url = Uri.parse(updateUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Impossible d\'ouvrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un PopScope pour empêcher l'utilisateur de revenir en arrière avec le bouton retour Android
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background, // Pour coller à votre thème
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
                    color: AppColors.textPrimary
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Une nouvelle version importante de Prono Challenge est disponible. Vous devez la télécharger pour continuer à pronostiquer !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, 
                    color: AppColors.textSecondary
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
                  onPressed: _launchUpdateUrl,
                  child: const Text(
                    "Télécharger la mise à jour", 
                    style: TextStyle(
                      fontSize: 18, 
                      color: AppColors.background, 
                      fontWeight: FontWeight.bold
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
