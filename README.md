# 🏆 Mondial 2026 - FIFA World Cup™ Companion & Prediction Platform

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.29.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Analytics-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-49%2F49%20Passing-brightgreen?logo=checkmarx)](test/)
[![Status](https://img.shields.io/badge/Tournament_Archive-104%2F104_Matches_Complete-blue)](https://fnnktkygl-code.github.io/mondial_2026/)

### 🌐 [👉 Click here to Launch the Live Web App (Tournament Archive & Predictions)](https://fnnktkygl-code.github.io/mondial_2026/) 👈

**[🇫🇷 Version Française (LISEZMOI.md)](LISEZMOI.md)** • **[🇪🇸 Versión en Español (LEAME.md)](LEAME.md)**

*Production-grade Flutter Web, iOS, macOS, Windows & Android application built for the FIFA World Cup 2026™ — Complete 104-match archive, real-time analytics, dynamic bracket topology resolution, assists & scorers leaderboards, and AI match insights.*

</div>

---

## 📱 App Store & Web Showcase

### 🖥️ Desktop & Tablet Experience

| 🏆 Dynamic Knockout Bracket & Champion | 📅 104-Match Schedule & Live Results |
| :---: | :---: |
| <img src="docs/screenshots/desktop_bracket.png" alt="Complete Tournament Bracket" width="100%"/> | <img src="docs/screenshots/desktop_calendar.png" alt="104 Matches Calendar" width="100%"/> |
| *Full 32-team knockout tree with real scores and champions* | *Filter by stage, group, date, and venue with live scoreboards* |

### 📱 Mobile Experience

| ⚽ 1. Live Matches & Schedule | 📊 2. Match Details & Elo Odds | 🏆 3. Group Stage & Best 3rds | 🎯 4. Golden Boot & Assists |
| :---: | :---: | :---: | :---: |
| <img src="docs/screenshots/mobile_home.jpg" alt="Match Schedule" width="100%"/> | <img src="docs/screenshots/mobile_match_detail.jpg" alt="Match Analytics" width="100%"/> | <img src="docs/screenshots/mobile_groups.jpg" alt="Standings" width="100%"/> | <img src="docs/screenshots/mobile_stats.jpg" alt="Top Scorers" width="100%"/> |
| *Real-time timeline & scores* | *Form analysis & odds* | *Groups A-L & 3rd-place rankings* | *Golden Boot & Assist leaders* |

---

## 🌐 Live Web Application

The full production web application is hosted on GitHub Pages:
- 🔗 **Production URL**: [https://fnnktkygl-code.github.io/mondial_2026/](https://fnnktkygl-code.github.io/mondial_2026/)
- 📦 **100% Offline Capable**: Bundled 104-match FIFA dataset with instant startup.
- ⚡ **Multi-Platform**: Fully responsive across mobile browsers, tablets, and desktop displays.

---

## 🏛️ System Architecture & Engineering Standards

This project adheres to the **5 Pillars of Clean Architecture & Reliability**:

1. **Zero-Fake Data & Complete Archive**:
   - 104 official matches fully modeled with real match facts, extra-time & penalty shootouts, goalscorers, and assist playmakers.
   - Deterministic topological resolution via [`FIFARegulations`](lib/utils/fifa_rules.dart) resolving Groups A–L, third-place rankings, Round of 32, Round of 16, Quarter-Finals, Semi-Finals, and Final.

2. **Reactive State & Clean Architecture**:
   - Strict separation of Concerns: Models (`lib/models/`), Services (`lib/services/`), Widgets (`lib/widgets/`), and Localization (`lib/l10n/`).

3. **Multi-i18n Parity (English, Français, Español)**:
   - Full trilingual support across all screens, team names, stages, stats, and dialogs in [`lib/l10n/translations.dart`](lib/l10n/translations.dart).

4. **100% Test Coverage & Zero Analyzer Diagnostics**:
   - Full test suite passing 49/49 tests verifying bracket routing, Golden Boot computations, and prediction algorithms.
   - `dart analyze` reports **0 errors, 0 warnings, 0 diagnostics**.

5. **AI Match Analysis**:
   - Gemini API integration (`GenieGeminiService`) with defensive token fallbacks, exponential backoff, and 429 quota protection.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.29.0`
- Dart SDK `>=3.7.0`

### Installation
```bash
# Clone the repository
git clone https://github.com/fnnktkygl-code/mondial_2026.git
cd mondial_2026

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Run application locally
flutter run -d chrome
```

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
