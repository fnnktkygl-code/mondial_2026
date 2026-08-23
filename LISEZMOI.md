# 🏆 Prono Challenge (Mondial 2026) — Archive Officielle & Plateforme de Pronostics

<div align="center">

[![Langue: Français](https://img.shields.io/badge/Langue-Fran%C3%A7ais%20%F0%9F%87%AB%F0%9F%87%B7-emerald?style=for-the-badge)](LISEZMOI.md)
[![Language: English](https://img.shields.io/badge/Language-English%20%F0%9F%87%AC%F0%9F%87%A7-blue?style=for-the-badge)](README.md)
[![Idioma: Español](https://img.shields.io/badge/Idioma-Espa%C3%B1ol%20%F0%9F%87%AA%F0%9F%87%B8-orange?style=for-the-badge)](LEAME.md)

<br/>

[![Déploiement Web](https://img.shields.io/badge/GitHub%20Pages-D%C3%A9ploy%C3%A9%20Production-brightgreen?logo=github&style=flat-square)](https://fnnktkygl-code.github.io/mondial_2026/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203.x-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20Reactive%20Pillars-emerald?style=flat-square)](ARCHITECTURE.md)
[![Analyse Statique](https://img.shields.io/badge/Dart%20Analyze-0%20Erreurs%20%2F%200%20Warnings-brightgreen?style=flat-square)](ARCHITECTURE.md)
[![Tests Automatisés](https://img.shields.io/badge/Tests%20Unitaires-100%25%20Valid%C3%A9s-brightgreen?style=flat-square)](test/)
[![Tournoi FIFA 2026](https://img.shields.io/badge/Format%20FIFA-104%20Matchs%20Complets-blue?style=flat-square)](assets/initial_matches.json)
[![Moteur IA](https://img.shields.io/badge/IA%20Pr%C3%A9dictive-Google%20Gemini-orange?logo=google&style=flat-square)](lib/services/genie_gemini_service.dart)
[![Licence: MIT](https://img.shields.io/badge/Licence-MIT-yellow.svg?style=flat-square)](LICENSE)

<p align="center">
  <strong>Prono Challenge (Mondial 2026)</strong> est une application multiplateforme de référence pour revivre, explorer et simuler l'intégralité de la <strong>Coupe du Monde FIFA 2026</strong> (48 nations, 104 matchs, 12 groupes, 16es de finale jusqu'à la consécration finale).<br/>
  Conçue selon les standards d'ingénierie les plus stricts (Clean Architecture, zéro avertissement linter, tests automatisés à 100%, moteur Elo dynamique, prédictions tactiques par IA Gemini et support multilingue intégral).
</p>

[**🚀 Lancer l'Application Web**](https://fnnktkygl-code.github.io/mondial_2026/) • [**📐 Manuel d'Architecture**](ARCHITECTURE.md) • [**🇬🇧 English README**](README.md) • [**🇪🇸 Versión en Español (LEAME.md)**](LEAME.md) • [**📊 Données du Tournoi**](assets/initial_matches.json)

</div>

---

## 📱 Aperçu & Galerie Vitrine

### 💻 Expérience Desktop (Grand Écran)

<div align="center">
  <table>
    <tr>
      <td width="50%" align="center">
        <strong>🌳 Tableau Final & Arbre Éliminatoire (104 Matchs)</strong><br/><br/>
        <img src="docs/screenshots/desktop_bracket.png" alt="Tableau du tournoi Mondial 2026" width="100%" style="border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,0.4);" /><br/>
        <sub>Arbre complet des 16es à la Finale avec connecteurs vectoriels et mise en surbrillance des vainqueurs</sub>
      </td>
      <td width="50%" align="center">
        <strong>🗓️ Calendrier des Matchs & Navigation Dynamique</strong><br/><br/>
        <img src="docs/screenshots/desktop_calendar.png" alt="Calendrier Desktop Mondial 2026" width="100%" style="border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,0.4);" /><br/>
        <sub>Vue chronologique des 104 matchs, scores en direct, filtres par phase et fuseau horaire local</sub>
      </td>
    </tr>
  </table>
</div>

<br/>

### 📱 Expérience Mobile (iPhone & Android — Galerie Fonctionnelle)

<div align="center">
  <table>
    <tr>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_home.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Accueil & Matchs" /><br/>
        <strong>⚽ 1. Matchs en Direct</strong><br/>
        <sub>Scores & Calendrier</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_match_detail.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Fiche de Match & Buteurs" /><br/>
        <strong>📊 2. Fiche de Match</strong><br/>
        <sub>Compositions & Cotes Elo</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_groups.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Classements & Poules" /><br/>
        <strong>🏆 3. Groupes FIFA</strong><br/>
        <sub>12 Poules & Meilleurs 3es</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_stats.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Stats & Buteurs" /><br/>
        <strong>🎯 4. Soulier & Passeurs</strong><br/>
        <sub>Buteurs & Assists</sub>
      </td>
    </tr>
  </table>
</div>

---

## ✨ Fonctionnalités Majeures

| Module | Description & Capacités Clés |
| :--- | :--- |
| **🗓️ Calendrier des 104 Matchs** | Navigation chronologique fluide, filtres par date, groupe et phase finale, horaires convertis dans le fuseau horaire local de l'utilisateur. |
| **🌳 Arbre Éliminatoire Sans Faille** | Tableau final complet (R32, R16, QF, SF, 3e place, Finale) avec zéro placeholder non résolu et dessin vectoriel sur-mesure. |
| **📊 Classements & Règles FIFA Officielles** | Calcul strict des 12 groupes (A à L), tableau des 8 meilleurs 3es repêchés et application des tiebreakers (différence de buts, fair-play). |
| **🎯 Buteurs & Passeurs Décisifs** | Tableaux d'honneur individuels complets (Soulier d'Or, Playmakers) avec normalisation des noms et statistiques par équipe. |
| **📈 Cotes Dynamiques & Algorithme Elo** | Calcul des probabilités de titre et des cotes 1X2 ajustées en temps réel après chaque rencontre disputée. |
| **🤖 IA Tactique Genie Gemini** | Analyses enrichies des rencontres (historique, forme, compositions, clés tactiques) avec fallback déterministe résilient en cas de coupure réseau. |
| **🌍 Trilinguisme Natif (100% Parité)** | Interface et contenus intégralement disponibles en **Français 🇫🇷**, **Anglais 🇬🇧** et **Espagnol 🇪🇸**. |

---

## 🏗️ Architecture & Piliers Techniques

Le projet applique les **5 Piliers d'Ingénierie** détaillés dans [`ARCHITECTURE.md`](ARCHITECTURE.md) :

1. **Vérité Mathématique & Rigueur Factuelle** : Conformité intégrale au format officiel de la FIFA pour la Coupe du Monde 2026 à 48 équipes.
2. **Architecture Réactive Découplée** : Séparation stricte entre widgets d'interface, moteur de règles (`FIFARegulations`) et couches de persistance.
3. **Zéro Diagnostic Linter & Tests Automatisés** : 0 erreur / 0 warning sous `dart analyze`, suite de tests unitaires et d'intégration validée à 100%.
4. **Résilience IA & Protection 429** : Gestion intelligente des quotas avec registre de cooldown et génération locale déterministe.
5. **Ergonomie UI/UX & Accessibilité** : Design system immersif, contraste WCAG AA, animations fluides à 60 FPS.

---

## 🚀 Démarrage Rapide

### Prérequis
- [Flutter SDK](https://flutter.dev) (v3.22.0 ou ultérieur)
- [Dart SDK](https://dart.dev) (v3.4.0 ou ultérieur)

### Installation & Lancement

```bash
# 1. Cloner le dépôt
git clone https://github.com/fnnktkygl-code/mondial_2026.git
cd mondial_2026

# 2. Récupérer les dépendances
flutter pub get

# 3. Lancer l'analyse statique (0 avertissement garanti)
flutter analyze

# 4. Exécuter l'ensemble des tests automatisés
flutter test

# 5. Démarrer l'application (Mode Normal / Archive)
flutter run
```

### Environnement Staging (Optionnel)
Pour activer le panneau de débogage et de simulation interactif :
```bash
flutter run --dart-define=STAGING=true
```

---

## 📁 Structure du Projet

```text
lib/
├── l10n/              # Dictionnaire multilingue (FR, EN, ES)
├── models/            # Entités immuables (WorldCupMatch, GoalEvent, TournamentStats)
├── screens/           # Écrans principaux (Règles, Feedback, Dialogues)
├── services/          # Services métier (API, Elo, Cotes, Prédictions, Gemini IA)
├── utils/             # Règlements officiels FIFA & routage du tableau éliminatoire
├── widgets/           # Composants UI (Calendrier, Bracket, Classements, Fiche Match)
└── main.dart          # Point d'entrée de l'application & routage réactif
test/
├── bracket_resolution_test.dart  # Validation de l'arbre éliminatoire complet
├── fifa_rules_test.dart          # Validation des règlements et tiebreakers FIFA
├── models/                       # Tests des modèles de données et getters d'état
├── services/                     # Tests des services métier et algorithmes
└── widgets/                      # Tests des composants d'interface
```

---

## 📄 Licence

Ce projet est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE) pour plus d'informations.
