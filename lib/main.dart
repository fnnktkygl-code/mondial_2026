import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'services/prediction_service.dart';
import 'services/firebase_service.dart';
import 'app_colors.dart';
import 'app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mondial 2026',
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
        fontFamily: 'sans-serif',
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
  
  bool _isLiveMode = false; // Toggle between Live Mode & Simulation Mode
  List<WorldCupMatch> _rawMatches = [];
  List<WorldCupMatch> _resolvedMatches = [];
  Map<String, String> _alerts = {};
  String? _supportedTeam;
  bool _isLoading = true;
  String _userTimezone = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    _userTimezone = DateTime.now().timeZoneName;
    if (_userTimezone.isEmpty) {
      _userTimezone = 'UTC';
    }

    Map<String, String> loadedAlerts = await AlertService.loadAlerts();
    final loadedMatches = await ApiService.loadMatches(forceRefresh: _isLiveMode);

    String? supportedTeam;
    // Firebase profile synchronization on launch using local UUID
    try {
      final preds = await PredictionService.loadPredictionData();
      final totalPoints = PredictionService.calculateTotalPoints(preds, loadedMatches);
      supportedTeam = preds.supportedTeam;
      
      await WCFirebaseService.syncUserProfile(
        username: preds.username,
        supportedTeam: preds.supportedTeam,
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
      _supportedTeam = supportedTeam;
      _alerts = loadedAlerts;
      _rawMatches = loadedMatches;
      _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      _isLoading = false;
    });
  }

  /// Toggle Live vs Simulation Mode
  Future<void> _toggleMode(bool isLive) async {
    setState(() {
      _isLiveMode = isLive;
      // If we go live, redirect from simulator tab to matches tab
      if (_isLiveMode && _activeTab == 'simulator') {
        _activeTab = 'matches';
      }
    });
    await _loadInitialData();
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
    }

    groupStandings.forEach((group, teamEntries) {
      teamEntries.sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
        if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
        return a.teamCode.compareTo(b.teamCode);
      });
    });

    // 2. Gather 3rd place teams from groups A to L and rank them
    final List<GroupEntry> thirdPlaces = [];
    groupStandings.forEach((g, list) {
      if (list.length >= 3) {
        thirdPlaces.add(list[2]); // Index 2 is the 3rd placed team
      }
    });
    // Sort 3rd places by points, then GD, then GF
    thirdPlaces.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      return b.goalsFor.compareTo(a.goalsFor);
    });

    // 3. Iteratively resolve placeholders (up to 3 passes to handle R32 -> R16 -> QF -> SF -> Final chains)
    List<WorldCupMatch> resolved = List.from(rawMatches);
    final Map<String, String> matchWinners = {};

    for (int pass = 0; pass < 3; pass++) {
      // Collect current winners
      for (final m in resolved) {
        if (m.isPlayed) {
          if (m.t1Score! > m.t2Score!) {
            matchWinners[m.id] = m.t1;
          } else if (m.t2Score! > m.t1Score!) {
            matchWinners[m.id] = m.t2;
          } else {
            // Draw in knockout -> mock winner as team 1
            matchWinners[m.id] = m.t1;
          }
        }
      }

      for (int i = 0; i < resolved.length; i++) {
        final m = resolved[i];
        String newT1 = m.t1;
        String newT2 = m.t2;

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

        if (newT1 != m.t1 || newT2 != m.t2) {
          resolved[i] = m.copyWith(t1: newT1, t2: newT2);
        }
      }
    }

    return resolved;
  }

  Future<void> _saveAlert(String matchId, String alertType) async {
    final updatedAlerts = await AlertService.saveAlert(matchId, alertType);
    setState(() {
      _alerts = updatedAlerts;
    });

    if (alertType != 'none') {
      final match = _resolvedMatches.firstWhere((m) => m.id == matchId);
      final t1Name = AppTranslations.getTeam(_lang, match.t1);
      final t2Name = AppTranslations.getTeam(_lang, match.t2);
      
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

  // Update simulator match data
  Future<void> _simulateMatchUpdate(WorldCupMatch updatedMatch) async {
    final index = _rawMatches.indexWhere((m) => m.id == updatedMatch.id);
    if (index != -1) {
      setState(() {
        _rawMatches[index] = updatedMatch;
        _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      });
      await ApiService.saveMatchesToCache(_rawMatches);
    }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database reset to defaults successfully.'),
      ),
    );
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
            'https://flagcdn.com/w40/$flagCountryCode.png',
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.get(_lang, 'appTitle'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${AppTranslations.get(_lang, 'timezoneInfo')} ($_userTimezone)',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Mode Toggle Switch
          Row(
            children: [
              Text(
                _isLiveMode
                    ? AppTranslations.get(_lang, 'liveMode')
                    : AppTranslations.get(_lang, 'simMode'),
                style: TextStyle(
                  color: _isLiveMode ? AppColors.accent : Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              Switch(
                value: _isLiveMode,
                activeColor: AppColors.accent,
                inactiveThumbColor: Colors.amber,
                inactiveTrackColor: Colors.amber.withOpacity(0.2),
                onChanged: (val) => _toggleMode(val),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: Row(
              children: [
                _buildLanguageFlagButton('fr', 'fr'),
                _buildLanguageFlagButton('en', 'gb'),
                _buildLanguageFlagButton('es', 'es'),
              ],
            ),
          )
        ],
      ),
      body: _isLoading
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
                            borderRadius: BorderRadius.circular(14),
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    AppTranslations.get(_lang, 'allMatches'),
                                    style: TextStyle(
                                      color: _matchFilter == 'all'
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppTranslations.get(_lang, 'myAlerts'),
                                        style: TextStyle(
                                          color: _matchFilter == 'alerts'
                                              ? Colors.white
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (_alerts.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.accent,
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.list,
                                  color: _viewMode == 'list'
                                      ? Colors.white
                                      : AppColors.textDim,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: _viewMode == 'list'
                                      ? AppColors.border
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => setState(() => _viewMode = 'list'),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.calendar_month_outlined,
                                  color: _viewMode == 'calendar'
                                      ? Colors.white
                                      : AppColors.textDim,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: _viewMode == 'calendar'
                                      ? AppColors.border
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
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
              if (!_isLiveMode) 'simulator',
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
                if (!_isLiveMode)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.logo_dev),
                    label: 'Simulator',
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
      icon: Icon(icon, size: 13, color: isSelected ? Colors.black : AppColors.textMuted),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.black : Colors.white,
        backgroundColor: isSelected ? AppColors.accent : AppColors.card,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
    } else {
      return GroupTableWidget(matches: _resolvedMatches, lang: _lang);
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
      );
    }

    if (_activeTab == 'challenge') {
      return ChallengeViewWidget(
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
        },
      );
    }

    if (_activeTab == 'simulator') {
      return _buildSimulatorTab();
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
                  fontSize: 11,
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

  Widget _buildSimulatorTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛠️ Agenda Simulation Panel',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        const SizedBox(height: 8),
        const Text(
          'Simulate scores, scorers, and game statistics to test the tournament engine. Chained updates dynamically flow down to the final.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Cache to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger.withOpacity(0.12),
                foregroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _resetTournament,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _rawMatches.length,
            itemBuilder: (context, idx) {
              final rawMatch = _rawMatches[idx];
              final resolvedMatch = _resolvedMatches[idx];
              final t1Name = AppTranslations.getTeam(_lang, resolvedMatch.t1);
              final t2Name = AppTranslations.getTeam(_lang, resolvedMatch.t2);

              final isKnockout = resolvedMatch.isKnockout;
              final badgeLabel = isKnockout
                  ? (resolvedMatch.stage ?? 'Knockout')
                  : 'Group ${resolvedMatch.group}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: AppColors.accent),
                          onPressed: () => _showSimEditDetailsSheet(resolvedMatch),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.border,
                            padding: const EdgeInsets.all(6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            t1Name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              rawMatch.isPlayed
                                  ? '${rawMatch.t1Score} - ${rawMatch.t2Score}'
                                  : 'VS',
                              style: TextStyle(
                                color: rawMatch.isPlayed ? AppColors.accent : AppColors.borderStrong,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            t2Name,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (rawMatch.isPlayed && rawMatch.goals.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sports_soccer, size: 12, color: AppColors.textDim),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rawMatch.goals.map((g) => "${g.scorer} ${g.minute}'").join(', '),
                              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Advanced Simulation Drawer to edit Match Scores, Scorers, and Stats
  void _showSimEditDetailsSheet(WorldCupMatch match) {
    final t1Controller = TextEditingController(text: match.t1Score != null ? '${match.t1Score}' : '');
    final t2Controller = TextEditingController(text: match.t2Score != null ? '${match.t2Score}' : '');
    
    // Stats controllers
    final posController = TextEditingController(text: '${match.stats?.possessionT1 ?? 50}');
    final shots1Controller = TextEditingController(text: '${match.stats?.shotsT1 ?? 10}');
    final shots2Controller = TextEditingController(text: '${match.stats?.shotsT2 ?? 10}');
    final target1Controller = TextEditingController(text: '${match.stats?.shotsOnTargetT1 ?? 4}');
    final target2Controller = TextEditingController(text: '${match.stats?.shotsOnTargetT2 ?? 4}');
    final fouls1Controller = TextEditingController(text: '${match.stats?.foulsT1 ?? 12}');
    final fouls2Controller = TextEditingController(text: '${match.stats?.foulsT2 ?? 12}');
    final yellow1Controller = TextEditingController(text: '${match.stats?.yellowCardsT1 ?? 1}');
    final yellow2Controller = TextEditingController(text: '${match.stats?.yellowCardsT2 ?? 1}');
    final red1Controller = TextEditingController(text: '${match.stats?.redCardsT1 ?? 0}');
    final red2Controller = TextEditingController(text: '${match.stats?.redCardsT2 ?? 0}');

    List<GoalEvent> tempGoals = List.from(match.goals);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.borderMid,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Simulate Match ${match.id} Details',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber),
                    ),
                  ),
                  const Divider(color: AppColors.border),

                  // Scrollable Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Scores Row
                          const Text('MATCH SCORE', style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: AppTranslations.getTeam(_lang, match.t1),
                                  controller: t1Controller,
                                  hint: 'Goals',
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.borderStrong)),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildSimTextField(
                                  label: AppTranslations.getTeam(_lang, match.t2),
                                  controller: t2Controller,
                                  hint: 'Goals',
                                  alignRight: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 2. Goals / Scorers Timeline
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GOALS TIMELINE', style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11)),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 14, color: AppColors.accent),
                                label: const Text('Add Goal', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                                onPressed: () async {
                                  final goal = await _showAddGoalDialog(match.t1, match.t2);
                                  if (goal != null) {
                                    setModalState(() {
                                      tempGoals.add(goal);
                                      tempGoals.sort((a, b) => a.minute.compareTo(b.minute));
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: tempGoals.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Text('No goals added yet.', style: TextStyle(color: AppColors.borderStrong, fontSize: 12)),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(tempGoals.length, (idx) {
                                      final g = tempGoals[idx];
                                      final tName = AppTranslations.getTeam(_lang, g.team == 't1' ? match.t1 : match.t2);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.sports_soccer, size: 14, color: AppColors.accent),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "${g.scorer} ${g.minute}' ($tName)${g.assistant != null ? ' - assist: ${g.assistant}' : ''}",
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                              onPressed: () {
                                                setModalState(() {
                                                  tempGoals.removeAt(idx);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // 3. Stats section
                          const Text('MATCH STATISTICS', style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Possession T1 (%)',
                                  controller: posController,
                                  hint: '50',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Possession T2', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${100 - (int.tryParse(posController.text) ?? 50)}%',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Shots T1',
                                  controller: shots1Controller,
                                  hint: '10',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Shots T2',
                                  controller: shots2Controller,
                                  hint: '10',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Shots on Target T1',
                                  controller: target1Controller,
                                  hint: '4',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Shots on Target T2',
                                  controller: target2Controller,
                                  hint: '4',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Fouls T1',
                                  controller: fouls1Controller,
                                  hint: '12',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Fouls T2',
                                  controller: fouls2Controller,
                                  hint: '12',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Yellow Cards T1',
                                  controller: yellow1Controller,
                                  hint: '1',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Yellow Cards T2',
                                  controller: yellow2Controller,
                                  hint: '1',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Red Cards T1',
                                  controller: red1Controller,
                                  hint: '0',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSimTextField(
                                  label: 'Red Cards T2',
                                  controller: red2Controller,
                                  hint: '0',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Save / Reset Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.danger),
                                    foregroundColor: AppColors.danger,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    // Reset match to unplayed
                                    final reset = match.copyWith(
                                      t1Score: null,
                                      t2Score: null,
                                      goals: [],
                                      stats: null,
                                    );
                                    _simulateMatchUpdate(reset);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Reset Match', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.surface,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    final s1 = int.tryParse(t1Controller.text);
                                    final s2 = int.tryParse(t2Controller.text);

                                    MatchStats? newStats;
                                    if (s1 != null && s2 != null) {
                                      newStats = MatchStats(
                                        possessionT1: int.tryParse(posController.text) ?? 50,
                                        shotsT1: int.tryParse(shots1Controller.text) ?? 10,
                                        shotsT2: int.tryParse(shots2Controller.text) ?? 10,
                                        shotsOnTargetT1: int.tryParse(target1Controller.text) ?? 4,
                                        shotsOnTargetT2: int.tryParse(target2Controller.text) ?? 4,
                                        foulsT1: int.tryParse(fouls1Controller.text) ?? 12,
                                        foulsT2: int.tryParse(fouls2Controller.text) ?? 12,
                                        yellowCardsT1: int.tryParse(yellow1Controller.text) ?? 1,
                                        yellowCardsT2: int.tryParse(yellow2Controller.text) ?? 1,
                                        redCardsT1: int.tryParse(red1Controller.text) ?? 0,
                                        redCardsT2: int.tryParse(red2Controller.text) ?? 0,
                                      );
                                    }

                                    final updated = match.copyWith(
                                      t1Score: s1,
                                      t2Score: s2,
                                      goals: tempGoals,
                                      stats: newStats,
                                    );
                                    _simulateMatchUpdate(updated);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Save Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSimTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool alignRight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.borderStrong),
            ),
          ),
        ],
      ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
