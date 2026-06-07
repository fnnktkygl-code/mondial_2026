import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/match.dart';
import 'services/api_service.dart';
import 'services/alert_service.dart';
import 'l10n/translations.dart';
import 'widgets/match_card.dart';
import 'widgets/match_detail_sheet.dart';
import 'widgets/group_table.dart';
import 'widgets/calendar_view.dart';
import 'widgets/bracket_view.dart';
import 'widgets/stats_view.dart';
import 'widgets/challenge_view.dart';
import 'widgets/profile_dialog.dart';
import 'widgets/team_selector.dart';
import 'widgets/anthem_player_sheet.dart';
import 'services/prediction_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'services/odds_service.dart';
import 'services/team_profile_service.dart';
import 'utils/fifa_rules.dart';
import 'widgets/title_odds_view.dart';
import 'widgets/mascots_dialog.dart';
import 'app_colors.dart';
import 'app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await WCNotificationService.init();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('es', null);
  await WCTeamProfileService.loadMediaMap();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prono Challenge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accent,
        cardColor: AppColors.card,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accent,
          selectionColor: AppColors.accent,
          selectionHandleColor: AppColors.accent,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textSecondary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textDim,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lang = 'fr';
  String _activeTab = 'matches'; // 'matches', 'standings', 'bracket', 'challenge', 'simulator'
  String _standingsSubTab = 'groups'; // 'groups', 'scorers', 'assists', 'team'
  String _matchFilter = 'all'; // 'all', 'alerts'
  String _viewMode = 'list'; // 'list', 'calendar'
  List<WorldCupMatch> _rawMatches = [];
  List<WorldCupMatch> _resolvedMatches = [];
  Map<String, String> _alerts = {};
  String? _supportedTeam;
  bool _isLoading = true;
  String _userTimezone = '';
  PredictionData? _userPreds;
  Key _challengeViewKey = UniqueKey();
  Map<String, double> _currentOdds = {};
  Map<String, double> _previousOdds = {};

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadInitialData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    WCAudioService.instance.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    _userTimezone = DateTime.now().timeZoneName;
    if (_userTimezone.isEmpty) {
      _userTimezone = 'UTC';
    }

    Map<String, String> loadedAlerts = await AlertService.loadAlerts();
    final loadedMatches = await ApiService.loadMatches(forceRefresh: true);

    String? supportedTeam;
    PredictionData? userPreds;
    // Firebase profile synchronization on launch using local UUID
    try {
      userPreds = await PredictionService.loadPredictionData();
      final totalPoints = PredictionService.calculateTotalPoints(userPreds, loadedMatches);
      supportedTeam = userPreds.supportedTeam;
      
      await WCFirebaseService.syncUserProfile(
        username: userPreds.username,
        supportedTeam: userPreds.supportedTeam,
        points: totalPoints,
      );
    } catch (e) {
      debugPrint("Firebase initial sync error: $e");
    }

    // Try to parse shared prediction group from URL if on Web
    try {
      final queryParams = Uri.base.queryParameters;
      if (queryParams.containsKey('group')) {
        final base64Payload = queryParams['group']!;
        if (base64Payload.isNotEmpty) {
          await PredictionService.joinCustomGroup(base64Payload);
          _activeTab = 'challenge';
        }
      }
    } catch (_) {
      // Ignore URL parsing exceptions
    }

    setState(() {
      _userPreds = userPreds;
      _supportedTeam = supportedTeam;
      _alerts = loadedAlerts;
      _rawMatches = loadedMatches;
      _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      _isLoading = false;
    });
    _updateTournamentOddsAndCheckNotifications();

    try {
      await WCNotificationService.requestPermissions();
    } catch (_) {}

    try {
      await WCNotificationService.scheduleHalfTimeAndFullTimeNotifications(
        matches: _resolvedMatches,
        lang: _lang,
      );
    } catch (e) {
      debugPrint("Error scheduling HT/FT notifications on load: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final firstShown = prefs.getBool('wc2026_first_profile_shown') ?? false;
      if (!firstShown) {
        await prefs.setBool('wc2026_first_profile_shown', true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showProfileModal();
        });
      }
    } catch (e) {
      debugPrint("Error checking first launch profile show: $e");
    }
  }

  void _showAnthemsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnthemPlayerSheet(
          matches: _resolvedMatches,
          lang: _lang,
        );
      },
    );
  }

  void _showMascotsModal() {
    WCMascotsDialog.show(context, _lang);
  }

  void _showProfileModal() {
    if (_userPreds == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return UserProfileDialog(
          lang: _lang,
          matches: _resolvedMatches,
          userPreds: _userPreds!,
          showSnackBar: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.accent,
              ),
            );
          },
          onSupportedTeamChanged: (teamCode) {
            setState(() {
              _supportedTeam = teamCode;
            });
            _updateTournamentOddsAndCheckNotifications();
          },
          onSaved: () async {
            final freshPreds = await PredictionService.loadPredictionData();
            setState(() {
              _userPreds = freshPreds;
              _challengeViewKey = UniqueKey();
            });
          },
        );
      },
    );
  }


  bool _hasAlert(WorldCupMatch m) {
    final alertVal = _alerts[m.id];
    if (alertVal == 'none') {
      return false;
    }
    final lowerTeam = _supportedTeam?.toLowerCase();
    if (lowerTeam != null && lowerTeam.isNotEmpty) {
      if (m.t1.toLowerCase() == lowerTeam || m.t2.toLowerCase() == lowerTeam) {
        return true;
      }
    }
    return alertVal != null;
  }

  /// Resolve tournament bracket placeholders dynamically based on group standings
  /// and played knockout match results.
  List<WorldCupMatch> _resolveMatchesPlaceholders(List<WorldCupMatch> rawMatches) {
    // 1. Calculate group standings first
    final Map<String, List<GroupEntry>> groupStandings = {};
    for (final m in rawMatches) {
      if (m.group == null || m.group!.isEmpty) continue;
      final grp = m.group!;
      groupStandings.putIfAbsent(grp, () => []);
      final list = groupStandings[grp]!;
      if (!list.any((e) => e.teamCode == m.t1)) list.add(GroupEntry(m.t1));
      if (!list.any((e) => e.teamCode == m.t2)) list.add(GroupEntry(m.t2));
    }

    for (final m in rawMatches) {
      if (m.group == null || m.group!.isEmpty || !m.isPlayed) continue;
      final grp = m.group!;
      final t1Entry = groupStandings[grp]!.firstWhere((e) => e.teamCode == m.t1);
      final t2Entry = groupStandings[grp]!.firstWhere((e) => e.teamCode == m.t2);

      t1Entry.played++;
      t2Entry.played++;
      t1Entry.goalsFor += m.t1Score!;
      t1Entry.goalsAgainst += m.t2Score!;
      t2Entry.goalsFor += m.t2Score!;
      t2Entry.goalsAgainst += m.t1Score!;

      if (m.t1Score! > m.t2Score!) {
        t1Entry.wins++;
        t2Entry.losses++;
      } else if (m.t1Score! < m.t2Score!) {
        t2Entry.wins++;
        t1Entry.losses++;
      } else {
        t1Entry.draws++;
        t2Entry.draws++;
      }

      if (m.stats != null) {
        t1Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          m.stats!.yellowCardsT1,
          m.stats!.redCardsT1,
        );
        t2Entry.fairPlay -= FIFARegulations.calculateDisciplinaryDeduction(
          m.stats!.yellowCardsT2,
          m.stats!.redCardsT2,
        );
      }
    }

    groupStandings.forEach((group, teamEntries) {
      FIFARegulations.sortStandings(teamEntries, rawMatches);
    });

    // 2. Gather 3rd place teams from groups A to L and rank them
    final List<GroupEntry> thirdPlaces = [];
    groupStandings.forEach((g, list) {
      if (list.length >= 3) {
        thirdPlaces.add(list[2]); // Index 2 is the 3rd placed team
      }
    });
    // Sort 3rd places by points, then GD, then GF, then Fair Play, then FIFA ranking
    thirdPlaces.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.teamCode.compareTo(b.teamCode);
    });

    // 3. Iteratively resolve placeholders (up to 6 passes to handle R32 -> R16 -> QF -> SF -> Final chains)
    List<WorldCupMatch> resolved = List.from(rawMatches);
    final Map<String, String> matchWinners = {};
    final Map<String, String> matchLosers = {};

    for (int pass = 0; pass < 6; pass++) {
      // Collect current winners and losers
      for (final m in resolved) {
        if (m.isPlayed) {
          if (m.t1Score! > m.t2Score!) {
            matchWinners[m.id] = m.t1;
            matchLosers[m.id] = m.t2;
          } else if (m.t2Score! > m.t1Score!) {
            matchWinners[m.id] = m.t2;
            matchLosers[m.id] = m.t1;
          } else {
            // Tie-break: default to team 1 winning
            matchWinners[m.id] = m.t1;
            matchLosers[m.id] = m.t2;
          }
        }
      }

      for (int i = 0; i < resolved.length; i++) {
        final m = resolved[i];
        String newT1 = m.t1;
        String newT2 = m.t2;

        // If knockout match and is currently TBD, initialize its placeholder
        if (m.isKnockout) {
          if (newT1.toLowerCase() == 'tbd') {
            newT1 = _getKnockoutPlaceholderT1(m.id);
          }
          if (newT2.toLowerCase() == 'tbd') {
            newT2 = _getKnockoutPlaceholderT2(m.id);
          }
        }

        // Group Winners / Runners-up placeholders (e.g., "1A", "2B")
        if (newT1.length == 2 && (newT1.startsWith('1') || newT1.startsWith('2'))) {
          final pos = newT1.substring(0, 1);
          final grp = newT1.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final idx = int.parse(pos) - 1;
            if (idx < groupList.length) {
              newT1 = groupList[idx].teamCode;
            }
          }
        }
        if (newT2.length == 2 && (newT2.startsWith('1') || newT2.startsWith('2'))) {
          final pos = newT2.substring(0, 1);
          final grp = newT2.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final idx = int.parse(pos) - 1;
            if (idx < groupList.length) {
              newT2 = groupList[idx].teamCode;
            }
          }
        }

        // Best 3rd place placeholders (e.g., "3rd1" to "3rd8")
        if (newT1.startsWith('3rd') && newT1.length > 3) {
          final idx = int.parse(newT1.substring(3)) - 1;
          if (idx >= 0 && idx < thirdPlaces.length) {
            newT1 = thirdPlaces[idx].teamCode;
          }
        }
        if (newT2.startsWith('3rd') && newT2.length > 3) {
          final idx = int.parse(newT2.substring(3)) - 1;
          if (idx >= 0 && idx < thirdPlaces.length) {
            newT2 = thirdPlaces[idx].teamCode;
          }
        }

        // Match Winner placeholders (e.g., "w49", "w50")
        if (newT1.startsWith('w') && newT1.length > 1) {
          final refId = 'm${newT1.substring(1)}';
          if (matchWinners.containsKey(refId)) {
            newT1 = matchWinners[refId]!;
          }
        }
        if (newT2.startsWith('w') && newT2.length > 1) {
          final refId = 'm${newT2.substring(1)}';
          if (matchWinners.containsKey(refId)) {
            newT2 = matchWinners[refId]!;
          }
        }

        // Match Loser placeholders (e.g., "l77", "l78")
        if (newT1.startsWith('l') && newT1.length > 1) {
          final refId = 'm${newT1.substring(1)}';
          if (matchLosers.containsKey(refId)) {
            newT1 = matchLosers[refId]!;
          }
        }
        if (newT2.startsWith('l') && newT2.length > 1) {
          final refId = 'm${newT2.substring(1)}';
          if (matchLosers.containsKey(refId)) {
            newT2 = matchLosers[refId]!;
          }
        }

        if (newT1 != m.t1 || newT2 != m.t2) {
          resolved[i] = m.copyWith(t1: newT1, t2: newT2);
        }
      }
    }

    return resolved;
  }

  String _getKnockoutPlaceholderT1(String matchId) {
    switch (matchId) {
      case 'm49': return '1A';
      case 'm50': return '2B';
      case 'm51': return '1C';
      case 'm52': return '2A';
      case 'm53': return '1E';
      case 'm54': return '2F';
      case 'm55': return '1G';
      case 'm56': return '2H';
      case 'm57': return '1B';
      case 'm58': return '2E';
      case 'm59': return '1D';
      case 'm60': return '2K';
      case 'm61': return '1F';
      case 'm62': return '1H';
      case 'm63': return '1I';
      case 'm64': return '1K';
      case 'm65': return 'w49';
      case 'm66': return 'w51';
      case 'm67': return 'w53';
      case 'm68': return 'w55';
      case 'm69': return 'w57';
      case 'm70': return 'w59';
      case 'm71': return 'w61';
      case 'm72': return 'w63';
      case 'm73': return 'w65';
      case 'm74': return 'w67';
      case 'm75': return 'w69';
      case 'm76': return 'w71';
      case 'm77': return 'w73';
      case 'm78': return 'w75';
      case 'm79': return 'l77';
      case 'm80': return 'w77';
      default: return 'tbd';
    }
  }

  String _getKnockoutPlaceholderT2(String matchId) {
    switch (matchId) {
      case 'm49': return '3rd1';
      case 'm50': return '2C';
      case 'm51': return '3rd2';
      case 'm52': return '2D';
      case 'm53': return '3rd3';
      case 'm54': return '2G';
      case 'm55': return '3rd4';
      case 'm56': return '2I';
      case 'm57': return '3rd5';
      case 'm58': return '2J';
      case 'm59': return '3rd6';
      case 'm60': return '2L';
      case 'm61': return '3rd7';
      case 'm62': return '3rd8';
      case 'm63': return '1J';
      case 'm64': return '1L';
      case 'm65': return 'w50';
      case 'm66': return 'w52';
      case 'm67': return 'w54';
      case 'm68': return 'w56';
      case 'm69': return 'w58';
      case 'm70': return 'w60';
      case 'm71': return 'w62';
      case 'm72': return 'w64';
      case 'm73': return 'w66';
      case 'm74': return 'w68';
      case 'm75': return 'w70';
      case 'm76': return 'w72';
      case 'm77': return 'w74';
      case 'm78': return 'w76';
      case 'm79': return 'l78';
      case 'm80': return 'w78';
      default: return 'tbd';
    }
  }

  String _getRandomPlayerName(String teamCode, {required bool isScorer, String? excludeName}) {
    final rand = Random();
    final code = teamCode.toLowerCase();

    final Map<String, List<String>> squadPlayers = {
      'sn': ['S. Mané', 'I. Sarr', 'B. Dia', 'P. Gueye', 'K. Koulibaly', 'N. Mendy', 'F. Diedhiou', 'K. Diatta', 'P. Sarr', 'M. Niang'],
      'fr': ['K. Mbappé', 'A. Griezmann', 'O. Dembélé', 'M. Thuram', 'K. Coman', 'A. Tchouaméni', 'A. Rabiot', 'E. Camavinga', 'W. Saliba', 'D. Upamecano'],
      'ar': ['L. Messi', 'J. Álvarez', 'L. Martínez', 'A. Di María', 'E. Fernández', 'A. Mac Allister', 'R. De Paul', 'N. Molina', 'C. Romero', 'N. Otamendi'],
      'br': ['Vinícius Jr.', 'Neymar Jr.', 'Rodrygo', 'Raphinha', 'Richarlison', 'G. Martinelli', 'Casemiro', 'Bruno G.', 'Marquinhos', 'Éder Militão'],
      'es': ['Alvaro Morata', 'Lamine Yamal', 'Nico Williams', 'Dani Olmo', 'Pedri', 'Gavi', 'Rodri', 'Fabián Ruiz', 'Dani Carvajal', 'Robin Le Normand'],
      'de': ['Kai Havertz', 'J. Musiala', 'Florian Wirtz', 'L. Sané', 'S. Gnabry', 'Ilkay Gündogan', 'Leon Goretzka', 'Joshua Kimmich', 'Antonio Rüdiger', 'Jonathan Tah'],
      'pt': ['C. Ronaldo', 'Bruno Fernandes', 'Bernardo Silva', 'Rafael Leão', 'João Félix', 'Gonçalo Ramos', 'Vitinha', 'Rúben Neves', 'Rúben Dias', 'João Cancelo'],
      'en': ['Harry Kane', 'Jude Bellingham', 'Bukayo Saka', 'Phil Foden', 'Marcus Rashford', 'Declan Rice', 'J. Maddison', 'Kieran Trippier', 'John Stones', 'Kyle Walker'],
      'it': ['F. Chiesa', 'C. Immobile', 'G. Scamacca', 'G. Raspadori', 'N. Barella', 'L. Pellegrini', 'Manuel Locatelli', 'F. Dimarco', 'A. Bastoni', 'G. Di Lorenzo'],
      'nl': ['Memphis Depay', 'Cody Gakpo', 'D. Malen', 'Xavi Simons', 'F. de Jong', 'T. Reijnders', 'Virgil van Dijk', 'Nathan Aké', 'D. Dumfries', 'Matthijs de Ligt'],
      'be': ['R. Lukaku', 'J. Doku', 'L. Trossard', 'K. De Bruyne', 'Y. Tielemans', 'Amadou Onana', 'Wout Faes', 'Timothy Castagne', 'Jan Vertonghen', 'Zeno Debast'],
      'uy': ['Darwin Núñez', 'Luis Suárez', 'F. Valverde', 'R. Bentancur', 'N. De La Cruz', 'M. Araujo', 'Ronald Araújo', 'Josema Giménez', 'M. Olivera'],
      'mx': ['S. Giménez', 'H. Lozano', 'U. Antuna', 'Luis Chávez', 'E. Álvarez', 'J. Sánchez', 'C. Montes', 'J. Gallardo'],
      'us': ['C. Pulisic', 'T. Weah', 'F. Balogun', 'W. McKennie', 'Y. Musah', 'T. Adams', 'A. Robinson', 'S. Dest'],
      'ca': ['Jonathan David', 'Alphonso Davies', 'Cyle Larin', 'Tajon Buchanan', 'Stephen Eustáquio', 'Ismaël Koné', 'Alistair Johnston'],
      'ma': ['Y. En-Nesyri', 'A. El Kaabi', 'Hakim Ziyech', 'Sofiane Boufal', 'A. Ounahi', 'Sofyan Amrabat', 'Achraf Hakimi', 'Nayef Aguerd'],
      'jp': ['K. Mitoma', 'Ayase Ueda', 'Ritsu Doan', 'Takefusa Kubo', 'Daichi Kamada', 'Wataru Endo', 'Hiroki Ito', 'Ko Itakura'],
      'kr': ['Son Heung-min', 'Hwang Hee-chan', 'Cho Gue-sung', 'Lee Kang-in', 'Hwang In-beom', 'Kim Min-jae', 'Seol Young-woo'],
    };

    List<String> pool = squadPlayers[code] ?? [];
    if (pool.isEmpty) {
      final genericSurnames = [
        'Silva', 'Santos', 'Gomez', 'Rodriguez', 'Smith', 'Jones', 'Johnson', 'Müller',
        'Schmidt', 'Dubois', 'Martin', 'Russo', 'Bianchi', 'Jovanovic', 'Petrovic',
        'Kovac', 'Nguyen', 'Tanaka', 'Sato', 'Kim', 'Park', 'Al-Sayed', 'Al-Harbi',
        'Diallo', 'Traoré', 'Koné', 'Mensah', 'Ayew'
      ];
      final genericFirstnames = ['J.', 'M.', 'A.', 'D.', 'S.', 'L.', 'H.', 'R.', 'K.', 'E.', 'G.'];
      pool = List.generate(15, (_) => '${genericFirstnames[rand.nextInt(genericFirstnames.length)]} ${genericSurnames[rand.nextInt(genericSurnames.length)]}');
    }

    final filtered = pool.where((name) => name != excludeName).toList();
    if (filtered.isEmpty) {
      return pool[rand.nextInt(pool.length)];
    }
    return filtered[rand.nextInt(filtered.length)];
  }


  Future<void> _saveAlert(String matchId, String alertType) async {
    final updatedAlerts = await AlertService.saveAlert(matchId, alertType);
    setState(() {
      _alerts = updatedAlerts;
    });

    if (alertType == 'none') {
      await WCNotificationService.cancelNotification(matchId);
    } else {
      final match = _resolvedMatches.firstWhere((m) => m.id == matchId);
      final t1Name = AppTranslations.getTeam(_lang, match.t1);
      final t2Name = AppTranslations.getTeam(_lang, match.t2);
      
      // Calculate scheduled date (either at kickoff or 1 hour before)
      DateTime scheduledTime = match.date;
      if (alertType == '1h') {
        scheduledTime = match.date.subtract(const Duration(hours: 1));
      }
      
      await WCNotificationService.scheduleMatchNotification(
        matchId: matchId,
        title: _lang == 'fr' 
            ? '⚽ Match imminent !' 
            : (_lang == 'es' ? '⚽ ¡Partido inminente!' : '⚽ Match starting soon!'),
        body: _lang == 'fr'
            ? 'Le match $t1Name vs $t2Name commence bientôt !'
            : (_lang == 'es' 
                ? '¡El partido entre $t1Name y $t2Name comienza pronto!' 
                : 'The match $t1Name vs $t2Name is starting soon!'),
        scheduledDate: scheduledTime,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          content: Row(
            children: [
              const Text('🔔 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  AppTranslations.get(_lang, 'alertReminderSet')
                      .replaceAll('{t1}', t1Name)
                      .replaceAll('{t2}', t2Name),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          duration: kSnackBarDuration,
        ),
      );
    }
  }

  void _showMatchDetails(WorldCupMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MatchDetailSheet(
          match: match,
          lang: _lang,
          activeAlert: _alerts[match.id],
          onSaveAlert: (alertType) => _saveAlert(match.id, alertType),
        );
      },
    );
  }


  // Reset tournament database
  Future<void> _resetTournament() async {
    setState(() => _isLoading = true);
    final resetMatches = await ApiService.resetCache();
    setState(() {
      _rawMatches = resetMatches;
      _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      _isLoading = false;
    });
    _updateTournamentOddsAndCheckNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database reset to defaults successfully.'),
      ),
    );
  }

  // Reset everything to factory settings
  Future<void> _resetToFactorySettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // clears all predictions, groups, alerts, first_profile_shown flag, etc.
    try {
      await WCNotificationService.cancelAll();
    } catch (_) {}
    try {
      WCAudioService.instance.stop();
    } catch (_) {}

    // Reset API matches cache
    final resetMatches = await ApiService.resetCache();

    // Reset local state fields
    _alerts = {};
    _supportedTeam = null;

    // Reload prediction data (will generate new empty prediction data)
    final freshPreds = await PredictionService.loadPredictionData();

    setState(() {
      _userPreds = freshPreds;
      _rawMatches = resetMatches;
      _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      _activeTab = 'matches'; // go to match tab
      _challengeViewKey = UniqueKey();
      _isLoading = false;
    });
    _updateTournamentOddsAndCheckNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lang == 'fr' 
            ? 'Application réinitialisée avec succès en version usine.' 
            : 'Application successfully reset to factory settings.'),
        backgroundColor: AppColors.accent,
      ),
    );
    _showProfileModal();
  }

  void _updateTournamentOddsAndCheckNotifications() {
    final newOdds = WCOddsService.calculateOdds(_resolvedMatches);
    if (_supportedTeam != null) {
      final favCode = _supportedTeam!.toLowerCase();
      final double oldProb = _currentOdds[favCode] ?? 0.0;
      final double newProb = newOdds[favCode] ?? 0.0;
      
      // If odds changed, dispatch a push notification
      if (oldProb.toStringAsFixed(1) != newProb.toStringAsFixed(1)) {
        final flag = _getCountryFlagEmoji(favCode);
        final nickname = WCNotificationService.getTeamNickname(favCode, _lang);
        
        String title = '';
        String body = '';
        
        if (newProb == 0.0) {
          title = _lang == 'fr' ? '❌ Élimination !' : (_lang == 'es' ? '❌ ¡Eliminación!' : '❌ Elimination!');
          body = _lang == 'fr' 
              ? 'Le rêve prend fin pour $nickname $flag ! Son parcours au Mondial 2026 s\'arrête ici.'
              : (_lang == 'es' 
                  ? '¡El sueño termina para $nickname $flag! Su camino en el Mundial 2026 termina aquí.' 
                  : 'The dream ends for $nickname $flag! Their World Cup 2026 run ends here.');
        } else if (newProb > oldProb) {
          title = _lang == 'fr' ? '📈 Cote en hausse !' : (_lang == 'es' ? '📈 ¡Cuotas al alza!' : '📈 Odds rising!');
          body = _lang == 'fr'
              ? 'La probabilité de titre pour $nickname $flag monte à ${newProb.toStringAsFixed(1)}% !'
              : (_lang == 'es'
                  ? '¡La probabilidad de título para $nickname $flag sube al ${newProb.toStringAsFixed(1)}%!'
                  : 'Title winning probability for $nickname $flag rises to ${newProb.toStringAsFixed(1)}%!');
        } else {
          title = _lang == 'fr' ? '📉 Cote en baisse !' : (_lang == 'es' ? '📉 ¡Cuotas a la baja!' : '📉 Odds falling!');
          body = _lang == 'fr'
              ? 'La probabilité de titre pour $nickname $flag baisse à ${newProb.toStringAsFixed(1)}%.'
              : (_lang == 'es'
                  ? 'La probabilidad de título para $nickname $flag baja al ${newProb.toStringAsFixed(1)}%.'
                  : 'Title winning probability for $nickname $flag falls to ${newProb.toStringAsFixed(1)}%.');
        }
        
        WCNotificationService.showNotification(
          id: 9999,
          title: title,
          body: body,
        );
      }
    }
    
    setState(() {
      _previousOdds = Map.from(_currentOdds.isEmpty ? newOdds : _currentOdds);
      _currentOdds = newOdds;
    });
  }

  String _getCountryFlagEmoji(String countryCode) {
    final Map<String, String> flags = {
      'ar': '🇦🇷', 'br': '🇧🇷', 'fr': '🇫🇷', 'es': '🇪🇸',
      'en': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'pt': '🇵🇹', 'de': '🇩🇪', 'it': '🇮🇹',
      'nl': '🇳🇱', 'be': '🇧🇪', 'uy': '🇺🇾', 'hr': '🇭🇷',
      'ma': '🇲🇦', 'co': '🇨🇴', 'mx': '🇲🇽', 'us': '🇺🇸',
      'jp': '🇯🇵', 'kr': '🇰🇷', 'sn': '🇸🇳', 'ng': '🇳🇬',
      'cm': '🇨🇲', 'ca': '🇨🇦', 'dz': '🇩🇿', 'eg': '🇪🇬',
      'sco': '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'za': '🇿🇦', 'qa': '🇶🇦', 'ch': '🇨🇭',
      'ht': '🇭🇹', 'au': '🇦🇺', 'tr': '🇹🇷', 'cw': '🇨🇼',
      'cv': '🇨🇻', 'ci': '🇨🇮', 'se': '🇸🇪', 'tn': '🇹🇳',
      'cd': '🇨🇩', 'uz': '🇺🇿', 'gh': '🇬🇭', 'pa': '🇵🇦',
      'no': '🇳🇴', 'iq': '🇮🇶', 'at': '🇦🇹', 'jo': '🇯🇴',
      'sa': '🇸🇦', 'nz': '🇳🇿', 'ir': '🇮🇷', 'ec': '🇪🇨',
      'ba': '🇧🇦', 'py': '🇵🇾', 'pl': '🇵🇱', 'cl': '🇨🇱',
      'pe': '🇵🇪', 'hu': '🇭🇺', 'cz': '🇨🇿', 'ro': '🇷🇴',
      'bg': '🇧🇬', 'rs': '🇷🇸', 'ua': '🇺🇦', 've': '🇻🇪',
      'dk': '🇩🇰',
    };
    return flags[countryCode.toLowerCase()] ?? '🏳️';
  }

  Widget _buildLanguageFlagButton(String langCode, String flagCountryCode) {
    final isSelected = _lang == langCode;
    return GestureDetector(
      onTap: () => setState(() => _lang = langCode),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.borderMid,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            '$kLanguageFlagUrl$flagCountryCode.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMatches = _resolvedMatches.where((m) {
      if (_matchFilter == 'alerts') {
        return _hasAlert(m);
      }
      return true;
    }).toList();

    final Map<String, List<WorldCupMatch>> matchesByDate = {};
    for (final m in filteredMatches) {
      final dateStr = DateFormat.yMd(_lang).format(m.date);
      matchesByDate.putIfAbsent(dateStr, () => []);
      matchesByDate[dateStr]!.add(m);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/logos/fifa_logo_dark.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTranslations.get(_lang, 'appTitle'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (String value) {
              if (value == 'mascots') _showMascotsModal();
              if (value == 'anthems') _showAnthemsModal();
              if (value == 'profile') _showProfileModal();
              if (['en', 'fr', 'es'].contains(value)) {
                setState(() => _lang = value);
                // _saveSettings();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Timezone: $_userTimezone', style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'mascots',
                child: Row(
                  children: [
                    const Icon(Icons.emoji_people, size: 18),
                    const SizedBox(width: 8),
                    Text(_lang == 'fr' ? 'Mascottes' : (_lang == 'es' ? 'Mascotas' : 'Mascots')),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'anthems',
                child: Row(
                  children: [
                    const Icon(Icons.music_note, size: 18),
                    const SizedBox(width: 8),
                    Text(AppTranslations.get(_lang, 'anthemsTitle')),
                  ],
                ),
              ),
              if (_userPreds != null)
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Text(_lang == 'fr' ? 'Mon Profil' : (_lang == 'es' ? 'Mi Perfil' : 'My Profile')),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'fr', child: Text('🇫🇷 Français')),
              const PopupMenuItem<String>(value: 'en', child: Text('🇬🇧 English')),
              const PopupMenuItem<String>(value: 'es', child: Text('🇪🇸 Español')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeTab == 'matches') ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(kCardRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _matchFilter = 'all'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _matchFilter == 'all'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(kButtonRadius),
                                      ),
                                      child: Text(
                                        AppTranslations.get(_lang, 'allMatches'),
                                        style: TextStyle(
                                          color: _matchFilter == 'all'
                                              ? Colors.white
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _matchFilter = 'alerts'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _matchFilter == 'alerts'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(kButtonRadius),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.notifications_none_outlined, size: 14, color: AppColors.accent),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppTranslations.get(_lang, 'myAlerts'),
                                            style: TextStyle(
                                              color: _matchFilter == 'alerts'
                                                  ? Colors.white
                                                  : AppColors.textMuted,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(kCardRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.list_alt,
                                      size: 20,
                                      color: AppColors.accent,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _viewMode == 'list'
                                          ? AppColors.border
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(kButtonRadius)),
                                    ),
                                    onPressed: () => setState(() => _viewMode = 'list'),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: AppColors.accent,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _viewMode == 'calendar'
                                          ? AppColors.border
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(kButtonRadius)),
                                    ),
                                    onPressed: () => setState(() => _viewMode = 'calendar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildActiveView(filteredMatches, matchesByDate),
                      ),
                    ],
                  ),
                ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Builder(
          builder: (context) {
            final tabsList = [
              'matches',
              'standings',
              'bracket',
              'challenge',
            ];
            final currentIndex = tabsList.indexOf(_activeTab).clamp(0, tabsList.length - 1);

            return BottomNavigationBar(
              backgroundColor: AppColors.background,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textDim,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() {
                  _activeTab = tabsList[index];
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.sports_soccer),
                  label: AppTranslations.get(_lang, 'today'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.table_rows),
                  label: AppTranslations.get(_lang, 'standings'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.hub_outlined),
                  label: AppTranslations.get(_lang, 'bracket'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events),
                  label: AppTranslations.get(_lang, 'challengeTab'),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    return Column(
      children: [
        // Sub-tabs Segment Bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStandingsSubTabButton('groups', AppTranslations.get(_lang, 'groupsTab'), Icons.table_rows),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton('scorers', AppTranslations.get(_lang, 'scorersTab'), Icons.sports_soccer),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton('assists', AppTranslations.get(_lang, 'assistsTab'), Icons.star_border),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton('team', AppTranslations.get(_lang, 'teamStatsTab'), Icons.search),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton('odds', AppTranslations.get(_lang, 'oddsTab'), Icons.analytics),
              ],
            ),
          ),
        ),

        // Sub-tab content
        Expanded(
          child: _getStandingsSubTabContent(),
        ),
      ],
    );
  }

  Widget _buildStandingsSubTabButton(String subTab, String label, IconData icon) {
    final isSelected = _standingsSubTab == subTab;
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16, color: isSelected ? Colors.black : AppColors.textMuted),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.black : Colors.white,
        backgroundColor: isSelected ? AppColors.accent : AppColors.card,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
        ),
      ),
      onPressed: () {
        setState(() {
          _standingsSubTab = subTab;
        });
      },
    );
  }

  Widget _getStandingsSubTabContent() {
    if (_standingsSubTab == 'scorers') {
      return ScorersLeaderboardWidget(matches: _resolvedMatches, lang: _lang);
    } else if (_standingsSubTab == 'assists') {
      return AssistsLeaderboardWidget(matches: _resolvedMatches, lang: _lang);
    } else if (_standingsSubTab == 'team') {
      return TeamStatsWidget(
        matches: _resolvedMatches,
        lang: _lang,
        onMatchTap: _showMatchDetails,
      );
    } else if (_standingsSubTab == 'odds') {
      return WCTitleOddsView(
        resolvedMatches: _resolvedMatches,
        lang: _lang,
        supportedTeamCode: _supportedTeam,
        currentOdds: _currentOdds,
        previousOdds: _previousOdds,
      );
    } else {
      return GroupTableWidget(
        matches: _resolvedMatches,
        lang: _lang,
        supportedTeamCode: _supportedTeam,
      );
    }
  }

  Widget _buildActiveView(
    List<WorldCupMatch> filteredMatches,
    Map<String, List<WorldCupMatch>> matchesByDate,
  ) {
    if (_activeTab == 'standings') {
      return _buildStandingsTab();
    }

    if (_activeTab == 'bracket') {
      return BracketViewWidget(
        matches: _resolvedMatches,
        lang: _lang,
        onMatchTap: _showMatchDetails,
        supportedTeamCode: _supportedTeam,
      );
    }

    if (_activeTab == 'challenge') {
      return ChallengeViewWidget(
        key: _challengeViewKey,
        matches: _resolvedMatches,
        lang: _lang,
        showSnackBar: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.accent,
            ),
          );
        },
        onAlertsChanged: (updatedAlerts) {
          setState(() {
            _alerts = updatedAlerts;
          });
        },
        onSupportedTeamChanged: (teamCode) {
          setState(() {
            _supportedTeam = teamCode;
          });
          _updateTournamentOddsAndCheckNotifications();
        },
      );
    }

    // Default: Matches Tab
    if (filteredMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.borderStrong),
            const SizedBox(height: 16),
            Text(
              AppTranslations.get(_lang, 'noAlerts'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 'calendar') {
      return CalendarViewWidget(
        matches: filteredMatches,
        lang: _lang,
        hasAlert: _hasAlert,
        onMatchTap: _showMatchDetails,
      );
    }

    final sortedDates = matchesByDate.keys.toList()
      ..sort((a, b) {
        final d1 = DateFormat.yMd(_lang).parse(a);
        final d2 = DateFormat.yMd(_lang).parse(b);
        return d1.compareTo(d2);
      });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIdx) {
        final dateLabel = sortedDates[dateIdx];
        final dayMatches = matchesByDate[dateLabel]!;
        final firstMatchDate = dayMatches.first.date;
        final weekdayStr = DateFormat('EEEE d MMMM', _lang).format(firstMatchDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
              child: Text(
                weekdayStr.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...dayMatches.map((m) {
              return MatchCard(
                match: m,
                lang: _lang,
                hasAlert: _hasAlert(m),
                alertType: _alerts[m.id] ?? (_hasAlert(m) ? '1h' : null),
                supportedTeamCode: _supportedTeam,
                onAlertToggle: () {
                  if (_hasAlert(m)) {
                    _saveAlert(m.id, 'none');
                  } else {
                    _saveAlert(m.id, '1h');
                  }
                },
                onTap: () => _showMatchDetails(m),
              );
            }),
          ],
        );
      },
    );
  }


void _showTestNotificationDialog() {
    // Hardcoded ISO list to drive the picker interface cleanly
    final List<String> teamCodes = [
      'ar', 'at', 'au', 'ba', 'be', 'bg', 'br', 'ca', 'cd', 'ch', 'ci', 'cl', 
      'cm', 'co', 'cu', 'cv', 'cz', 'de', 'dk', 'dz', 'ec', 'eg', 'en', 'es', 
      'fr', 'sco', 'gh', 'gr', 'hr', 'ht', 'hu', 'iq', 'ir', 'it', 'jo', 'jp', 
      'kr', 'ma', 'mx', 'ng', 'nl', 'no', 'nz', 'pa', 'pe', 'pl', 'pt', 'qa', 
      'ro', 'rs', 'sa', 'se', 'sn', 'tn', 'tr', 'ua', 'us', 'uy', 'uz', 've', 'za'
    ]..sort();

    String t1 = 'fr';
    String t2 = 'dk';
    final t1ScoreController = TextEditingController(text: '2');
    final t2ScoreController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
              title: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text(
                    _lang == 'fr' ? 'Tester les notifications' : (_lang == 'es' ? 'Probar notificaciones' : 'Test Notifications'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lang == 'fr' 
                          ? 'Choisissez deux équipes et un score pour simuler une alerte :' 
                          : (_lang == 'es' ? 'Elige dos equipos y un marcador para simular una alerta:' : 'Choose two teams and a score to simulate a notification:'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Team 1 Selector
                    Text(
                      _lang == 'fr' ? 'Équipe 1' : (_lang == 'es' ? 'Equipo 1' : 'Team 1'),
                      style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        TeamSelectorBottomSheet.show(
                          context: context,
                          lang: _lang,
                          title: _lang == 'fr' ? 'Sélectionner Équipe 1' : 'Select Team 1',
                          selectedTeamCode: t1,
                          teamCodes: teamCodes,
                          onTeamSelected: (val) {
                            setDialogState(() => t1 = val);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_getCountryFlagEmoji(t1)} ${AppTranslations.getTeam(_lang, t1)} ($t1)',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Team 2 Selector
                    Text(
                      _lang == 'fr' ? 'Équipe 2' : (_lang == 'es' ? 'Equipo 2' : 'Team 2'),
                      style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        TeamSelectorBottomSheet.show(
                          context: context,
                          lang: _lang,
                          title: _lang == 'fr' ? 'Sélectionner Équipe 2' : 'Select Team 2',
                          selectedTeamCode: t2,
                          teamCodes: teamCodes,
                          onTeamSelected: (val) {
                            setDialogState(() => t2 = val);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_getCountryFlagEmoji(t2)} ${AppTranslations.getTeam(_lang, t2)} ($t2)',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scores
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang == 'fr' ? 'Score éq. 1' : (_lang == 'es' ? 'Marcador eq. 1' : 'Score Team 1'),
                                style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: t1ScoreController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang == 'fr' ? 'Score éq. 2' : (_lang == 'es' ? 'Marcador eq. 2' : 'Score Team 2'),
                                style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: t2ScoreController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.border,
                              foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final s1 = int.tryParse(t1ScoreController.text) ?? 0;
                              final s2 = int.tryParse(t2ScoreController.text) ?? 0;
                              final body = WCNotificationService.formatScoreNotificationBody(
                                lang: _lang,
                                t1Code: t1,
                                t2Code: t2,
                                t1Score: s1,
                                t2Score: s2,
                                isFinished: false,
                              );
                              final title = _lang == 'fr' ? '⚽ Mi-temps !' : (_lang == 'es' ? '⚽ ¡Medio tiempo!' : '⚽ Half-time!');
                              WCNotificationService.showInstantNotification(
                                id: 'test_ht',
                                title: title,
                                body: body,
                              );
                            },
                            child: Text(_lang == 'fr' ? 'Alerte Mi-temps' : (_lang == 'es' ? 'Alerta Medio Tiempo' : 'Half-Time Alert'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final s1 = int.tryParse(t1ScoreController.text) ?? 0;
                              final s2 = int.tryParse(t2ScoreController.text) ?? 0;
                              final body = WCNotificationService.formatScoreNotificationBody(
                                lang: _lang,
                                t1Code: t1,
                                t2Code: t2,
                                t1Score: s1,
                                t2Score: s2,
                                isFinished: true,
                              );
                              final title = _lang == 'fr' ? '🏆 Fin du match !' : (_lang == 'es' ? '🏆 ¡Fin del partido!' : '🏆 Full-time!');
                              WCNotificationService.showInstantNotification(
                                id: 'test_ft',
                                title: title,
                                body: body,
                              );
                            },
                            child: Text(_lang == 'fr' ? 'Alerte Fin' : (_lang == 'es' ? 'Alerta Fin' : 'Full-Time Alert'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(_lang == 'fr' ? 'Fermer' : (_lang == 'es' ? 'Cerrar' : 'Close'), style: const TextStyle(color: AppColors.textDim)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<GoalEvent?> _showAddGoalDialog(String t1, String t2) async {
    final scorerController = TextEditingController();
    final assistController = TextEditingController();
    final minController = TextEditingController(text: '45');
    String teamSelect = 't1';

    return showDialog<GoalEvent>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
              title: const Text('Add Goal Event', style: TextStyle(color: Colors.amber)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Team choice
                    Row(
                      children: [
                        const Text('Scoring Team: ', style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        ChoiceChip(
                          label: Text(AppTranslations.getTeam(_lang, t1), style: const TextStyle(fontSize: 12)),
                          selected: teamSelect == 't1',
                          onSelected: (sel) {
                            if (sel) setDlgState(() => teamSelect = 't1');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(AppTranslations.getTeam(_lang, t2), style: const TextStyle(fontSize: 12)),
                          selected: teamSelect == 't2',
                          onSelected: (sel) {
                            if (sel) setDlgState(() => teamSelect = 't2');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scorerController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Scorer Name',
                        labelStyle: TextStyle(color: AppColors.textDim),
                        hintText: 'e.g. K. Mbappé',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: assistController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Assistant Name (Optional)',
                        labelStyle: TextStyle(color: AppColors.textDim),
                        hintText: 'e.g. A. Griezmann',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Minute',
                        labelStyle: TextStyle(color: AppColors.textDim),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: () {
                    if (scorerController.text.isNotEmpty) {
                      final goal = GoalEvent(
                        team: teamSelect,
                        scorer: scorerController.text,
                        assistant: assistController.text.isNotEmpty ? assistController.text : null,
                        minute: int.tryParse(minController.text) ?? 45,
                      );
                      Navigator.pop(context, goal);
                    }
                  },
                  child: const Text('Add Goal', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
