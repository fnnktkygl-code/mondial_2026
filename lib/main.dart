import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mondial_2026/services/player_database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'widgets/anthem_player_sheet.dart';
import 'services/prediction_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'services/odds_service.dart';
import 'services/team_profile_service.dart';
import 'services/update_service.dart';
import 'utils/fifa_rules.dart';
import 'widgets/mascots_dialog.dart';
import 'widgets/landing_page.dart';
import 'widgets/staging_panel.dart';
import 'widgets/wc_tooltip.dart';
import 'screens/update_required_screen.dart';
import 'app_colors.dart';
import 'app_constants.dart';
import 'package:app_links/app_links.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Analytics
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Initialize Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  await WCNotificationService.init();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('es', null);
  await WCTeamProfileService.loadMediaMap();
  await PlayerDatabaseService.loadPlayers();
  
  bool requireUpdate = false;
  try {
    requireUpdate = await WCUpdateService.isUpdateRequired();
  } catch (e) {
    debugPrint("Update check failed: $e");
  }

  runApp(MyApp(requireUpdate: requireUpdate));
}

class MyApp extends StatelessWidget {
  final bool requireUpdate;
  const MyApp({super.key, this.requireUpdate = false});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
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
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textSecondary,
              displayColor: AppColors.textPrimary,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
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
      home: requireUpdate ? const UpdateRequiredScreen() : const LandingPageWrapper(),
      ),
    );
  }
}

class LandingPageWrapper extends StatefulWidget {
  const LandingPageWrapper({super.key});

  @override
  State<LandingPageWrapper> createState() => _LandingPageWrapperState();
}

class _LandingPageWrapperState extends State<LandingPageWrapper> {
  bool _showApp = false;

  @override
  Widget build(BuildContext context) {
    if (!_showApp) {
      return LandingPage(
        onGetStarted: () {
          setState(() {
            _showApp = true;
          });
        },
      );
    }
    return const MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lang = 'fr';
  String _activeTab =
      'matches'; // 'matches', 'standings', 'bracket', 'challenge'
  String _standingsSubTab = 'groups'; // 'groups', 'scorers', 'assists', 'team'
  String _matchFilter = 'all'; // 'all', 'alerts'
  String _viewMode = 'list'; // 'list', 'calendar'
  String _challengeInitialSubTab = 'preds';

  List<WorldCupMatch> _rawMatches = [];
  List<WorldCupMatch> _resolvedMatches = [];
  Map<String, String> _alerts = {};
  String? _supportedTeam;
  bool _isLoading = true;
  String _userTimezone = '';
  PredictionData? _userPreds;
  String? _pendingGroupPayload;
  Key _challengeViewKey = UniqueKey();
  Map<String, double> _currentOdds = {};

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  late ConfettiController _confettiController;
  late ScrollController _listScrollController;

  @override
  void initState() {
    super.initState();
    WCNotificationService.init(onTap: _onNotificationTap);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _listScrollController = ScrollController();
    _initDeepLinks();
    _loadInitialData();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _confettiController.dispose();
    _listScrollController.dispose();
    WCAudioService.instance.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    debugPrint("INIT: Starting _loadInitialData");

    try {
      _userTimezone = DateTime.now().timeZoneName;
      if (_userTimezone.isEmpty) _userTimezone = 'UTC';

      debugPrint("INIT: Loading core data (Alerts, Matches, Preds)");
      // Parallelize core data loading to minimize wait time
      final results = await Future.wait([
        AlertService.loadAlerts().catchError((e) {
          debugPrint("Error loading alerts: $e");
          return <String, String>{};
        }),
        ApiService.loadMatches(forceRefresh: kIsLiveMode && !kIsStaging).catchError((e) {
          debugPrint("Error loading matches: $e");
          return <WorldCupMatch>[];
        }),
        PredictionService.loadPredictionData().catchError((e) {
          debugPrint("Error loading predictions: $e");
          return PredictionData();
        }),
      ]).timeout(const Duration(seconds: 12), onTimeout: () {
        debugPrint("INIT: Global timeout reached during core load");
        throw TimeoutException("Core data load timed out");
      });

      final loadedAlerts = results[0] as Map<String, String>;
      final loadedMatches = results[1] as List<WorldCupMatch>;
      final userPreds = results[2] as PredictionData;

      if (mounted) {
        setState(() {
          _userPreds = userPreds;
          _supportedTeam = userPreds.supportedTeam;
          _alerts = loadedAlerts;
          _rawMatches = loadedMatches;
          _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
          // Stop loading as soon as core data is ready to show the UI
          _isLoading = false;
        });
        debugPrint("INIT: Core UI state updated, spinner stopped");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentMatch();
        });
      }

      // Continue with non-blocking tasks
      _finishInitialization(userPreds, loadedMatches, loadedAlerts);

    } catch (e, stack) {
      debugPrint("FATAL INIT ERROR: $e");
      debugPrint(stack.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles secondary initialization tasks without blocking the main UI.
  Future<void> _finishInitialization(
    PredictionData userPreds,
    List<WorldCupMatch> loadedMatches,
    Map<String, String> loadedAlerts,
  ) async {
    debugPrint("INIT: Starting background tasks");
    
    // 1. Sync User Profile (async, non-blocking)
    try {
      final totalPoints = PredictionService.calculateTotalPoints(userPreds, loadedMatches);
      final streak = PredictionService.calculateActiveStreak(userPreds, loadedMatches);
      final guruCount = PredictionService.calculateExactGuessesCount(userPreds, loadedMatches);

      WCFirebaseService.syncUserProfile(
        username: userPreds.username,
        supportedTeam: userPreds.supportedTeam,
        points: totalPoints,
        streak: streak,
        guruCount: guruCount,
        avatar: userPreds.avatar,
      ).timeout(const Duration(seconds: 8)).catchError((e) => debugPrint("Profile sync failed: $e"));
    } catch (e) {
      debugPrint("Error preparing profile sync: $e");
    }

    // 2. Deep Links
    String? startupPayload = _pendingGroupPayload;
    if (startupPayload == null) {
      try {
        final queryParams = Uri.base.queryParameters;
        if (queryParams.containsKey('group')) {
          startupPayload = queryParams['group']!;
        }
      } catch (_) {}
    }

    if (startupPayload != null && startupPayload.isNotEmpty) {
      final payload = startupPayload;
      if (kIsWeb) {
        bool skipPrompt = false;
        try {
          skipPrompt = Uri.base.queryParameters['skip_prompt'] == 'true';
        } catch (_) {}
        if (!skipPrompt) {
          final confirm = await _showOpenInAppDialog(payload);
          if (confirm) {
            try {
              final opened = await launchUrl(
                Uri.parse("mondial2026://group?group=$payload"),
                mode: LaunchMode.externalApplication,
              );
              if (opened) {
                _pendingGroupPayload = null;
                return; // Native app successfully opened, abort Web initialization
              }
            } catch (e) {
              debugPrint("Could not launch custom scheme: $e");
            }
          }
        }
      }

      // Normal joining/onboarding flow
      if (userPreds.username.isEmpty || userPreds.supportedTeam == null || userPreds.supportedTeam!.isEmpty) {
        _pendingGroupPayload = payload;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showProfileModal();
            _showBeautifulSnackBar(AppTranslations.get(_lang, 'pleaseCompleteProfileToJoin'));
          }
        });
      } else {
        _pendingGroupPayload = null;
        await PredictionService.joinCustomGroup(payload);
        if (!mounted) return;
        setState(() {
          _activeTab = 'challenge';
          _challengeInitialSubTab = 'groups';
          _challengeViewKey = UniqueKey();
        });
        _showBeautifulSnackBar(AppTranslations.get(_lang, 'groupJoined'));
      }
    }

    if (!mounted) return;

    // 3. Odds & Notifications
    _updateTournamentOddsAndCheckNotifications();

    // 4. Update Check (non-web only)
    if (!kIsWeb && mounted) {
      if (!context.mounted) return;
      WCUpdateService.checkUpdate(context, _lang);
    }

    // 5. Notifications Permissions & Scheduling
    try {
      await WCNotificationService.requestPermissions();
      
      // Filter matches for HT/FT alerts: Fav team + Predicted + Manual Alerts
      final filteredMatches = _resolvedMatches.where((m) {
        final isFav = _supportedTeam != null && 
            (m.t1.toLowerCase() == _supportedTeam!.toLowerCase() || 
             m.t2.toLowerCase() == _supportedTeam!.toLowerCase());
        final hasPred = _userPreds?.matchPredictions.containsKey(m.id) ?? false;
        final hasAlert = _alerts.containsKey(m.id) && _alerts[m.id] != 'none';
        return isFav || hasPred || hasAlert;
      }).toList();

      await WCNotificationService.scheduleHalfTimeAndFullTimeNotifications(
        matches: filteredMatches,
        lang: _lang,
      );

      // Schedule "Missing Predictions" reminder for the next 3 days
      if (_userPreds != null) {
        await WCNotificationService.schedulePredictionReminders(
          matches: _resolvedMatches,
          userPredictions: _userPreds!.matchPredictions,
          lang: _lang,
        );
      }
    } catch (e) {
      debugPrint("Notification scheduling error: $e");
    }

    // 6. First Launch Profile Modal
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final firstShown = prefs.getBool('wc2026_first_profile_shown') ?? false;
      if (!firstShown) {
        await prefs.setBool('wc2026_first_profile_shown', true);
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showProfileModal();
        });
      }
    } catch (e) {
      debugPrint("First launch modal error: $e");
    }
    
    debugPrint("INIT: All background tasks completed");
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint("Deep link received: $uri");
      _handleDeepLinkUri(uri);
    }, onError: (err) {
      debugPrint("Deep link error: $err");
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint("Cold start deep link: $uri");
        _handleDeepLinkUri(uri);
      }
    }).catchError((err) {
      debugPrint("Cold start deep link error: $err");
    });
  }

  void _handleDeepLinkUri(Uri uri) async {
    try {
      final queryParams = uri.queryParameters;
      if (queryParams.containsKey('group')) {
        final base64Payload = queryParams['group']!;
        if (base64Payload.isNotEmpty) {
          if (kIsWeb && !_isLoading && mounted) {
            bool skipPrompt = false;
            try {
              skipPrompt = uri.queryParameters['skip_prompt'] == 'true';
            } catch (_) {}
            if (!skipPrompt) {
              final confirm = await _showOpenInAppDialog(base64Payload);
              if (confirm) {
                try {
                  final opened = await launchUrl(
                    Uri.parse("mondial2026://group?group=$base64Payload"),
                    mode: LaunchMode.externalApplication,
                  );
                  if (opened) return; // Native app successfully opened, stop Web flow
                } catch (e) {
                  debugPrint("Could not launch custom scheme: $e");
                }
              }
            }
          }

          final upreds = _userPreds;
          // If predictions/profile is not loaded yet or username is empty, store as pending
          if (upreds == null || upreds.username.isEmpty || upreds.supportedTeam == null || upreds.supportedTeam!.isEmpty) {
            _pendingGroupPayload = base64Payload;
            // Only show modal if app is already initialized
            if (!_isLoading && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showProfileModal();
                _showBeautifulSnackBar(AppTranslations.get(_lang, 'pleaseCompleteProfileToJoin'));
              });
            }
          } else {
            final success = await PredictionService.joinCustomGroup(base64Payload);
            if (!mounted) return;
            setState(() {
              _activeTab = 'challenge';
              _challengeInitialSubTab = 'groups';
              _challengeViewKey = UniqueKey();
            });
            if (success) {
              _showBeautifulSnackBar(AppTranslations.get(_lang, 'groupJoined'));
            } else {
              _showBeautifulSnackBar(AppTranslations.get(_lang, 'groupJoinFailed'));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error handling deep link: $e");
    }
  }

  Future<bool> _showOpenInAppDialog(String payload) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🌍', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text('Ouvrir dans l\'application ?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Voulez-vous ouvrir ce groupe d\'invitation dans l\'application Prono Challenge de votre appareil pour une meilleure expérience ?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Rester sur le Web', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ouvrir l\'application', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAnthemsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnthemPlayerSheet(matches: _resolvedMatches, lang: _lang);
      },
    );
  }

  void _showMascotsModal() {
    WCMascotsDialog.show(context, _lang);
  }

  void _showProfileModal() {
    if (_userPreds == null) return;
    final isDismissible = _pendingGroupPayload == null;
    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) {
        return UserProfileDialog(
          lang: _lang,
          matches: _resolvedMatches,
          userPreds: _userPreds!,
          isDismissible: isDismissible,
          showSnackBar: (msg) => _showBeautifulSnackBar(msg),
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
              _supportedTeam = freshPreds.supportedTeam;
              _challengeViewKey = UniqueKey();
            });
            _updateTournamentOddsAndCheckNotifications();

            // Join the group if a payload was pending
            if (_pendingGroupPayload != null) {
              final payload = _pendingGroupPayload!;
              _pendingGroupPayload = null;
              final success = await PredictionService.joinCustomGroup(payload);
              if (mounted) {
                setState(() {
                  _activeTab = 'challenge';
                  _challengeInitialSubTab = 'groups';
                  _challengeViewKey = UniqueKey();
                });
                if (success) {
                  _showBeautifulSnackBar(AppTranslations.get(_lang, 'groupJoined'));
                } else {
                  _showBeautifulSnackBar(AppTranslations.get(_lang, 'groupJoinFailed'));
                }
              }
            }
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

  List<WorldCupMatch> _resolveMatchesPlaceholders(
    List<WorldCupMatch> rawMatches,
  ) {
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
      final t1Entry = groupStandings[grp]!.firstWhere(
        (e) => e.teamCode == m.t1,
      );
      final t2Entry = groupStandings[grp]!.firstWhere(
        (e) => e.teamCode == m.t2,
      );

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

    final List<GroupEntry> thirdPlaces = [];
    groupStandings.forEach((g, list) {
      if (list.length >= 3) {
        thirdPlaces.add(list[2]);
      }
    });
    thirdPlaces.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
      if (b.fairPlay != a.fairPlay) return b.fairPlay.compareTo(a.fairPlay);
      final rankA = WCTeamProfileService.getFifaRanking(a.teamCode);
      final rankB = WCTeamProfileService.getFifaRanking(b.teamCode);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.teamCode.compareTo(b.teamCode);
    });

    final bool allGroupsComplete =
        groupStandings.isNotEmpty &&
        groupStandings.values.every((list) => list.every((e) => e.played == 3));

    List<WorldCupMatch> resolved = List.from(rawMatches);
    final Map<String, String> matchWinners = {};
    final Map<String, String> matchLosers = {};

    for (int pass = 0; pass < 6; pass++) {
      for (final m in resolved) {
        if (m.isPlayed) {
          if (m.t1Score! > m.t2Score!) {
            matchWinners[m.id] = m.t1;
            matchLosers[m.id] = m.t2;
          } else if (m.t2Score! > m.t1Score!) {
            matchWinners[m.id] = m.t2;
            matchLosers[m.id] = m.t1;
          } else {
            matchWinners[m.id] = m.t1;
            matchLosers[m.id] = m.t2;
          }
        }
      }

      for (int i = 0; i < resolved.length; i++) {
        final m = resolved[i];
        String newT1 = m.t1;
        String newT2 = m.t2;

        if (m.isKnockout) {
          if (newT1.toLowerCase() == 'tbd') {
            newT1 = _getKnockoutPlaceholderT1(m.id);
          }
          if (newT2.toLowerCase() == 'tbd') {
            newT2 = _getKnockoutPlaceholderT2(m.id);
          }
        }

        if (newT1.length == 2 &&
            (newT1.startsWith('1') || newT1.startsWith('2'))) {
          final pos = newT1.substring(0, 1);
          final grp = newT1.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final isGroupComplete = groupList.every((e) => e.played == 3);
            if (isGroupComplete) {
              final idx = int.parse(pos) - 1;
              if (idx < groupList.length) newT1 = groupList[idx].teamCode;
            }
          }
        }
        if (newT2.length == 2 &&
            (newT2.startsWith('1') || newT2.startsWith('2'))) {
          final pos = newT2.substring(0, 1);
          final grp = newT2.substring(1, 2);
          final groupList = groupStandings[grp];
          if (groupList != null && groupList.isNotEmpty) {
            final isGroupComplete = groupList.every((e) => e.played == 3);
            if (isGroupComplete) {
              final idx = int.parse(pos) - 1;
              if (idx < groupList.length) newT2 = groupList[idx].teamCode;
            }
          }
        }

        if (newT1.startsWith('3rd') && newT1.length > 3) {
          if (allGroupsComplete) {
            final idx = int.parse(newT1.substring(3)) - 1;
            if (idx >= 0 && idx < thirdPlaces.length) {
              newT1 = thirdPlaces[idx].teamCode;
            }
          }
        }
        if (newT2.startsWith('3rd') && newT2.length > 3) {
          if (allGroupsComplete) {
            final idx = int.parse(newT2.substring(3)) - 1;
            if (idx >= 0 && idx < thirdPlaces.length) {
              newT2 = thirdPlaces[idx].teamCode;
            }
          }
        }

        if (newT1.startsWith('w') && newT1.length > 1) {
          final refId = 'm${newT1.substring(1)}';
          if (matchWinners.containsKey(refId)) newT1 = matchWinners[refId]!;
        }
        if (newT2.startsWith('w') && newT2.length > 1) {
          final refId = 'm${newT2.substring(1)}';
          if (matchWinners.containsKey(refId)) newT2 = matchWinners[refId]!;
        }

        if (newT1.startsWith('l') && newT1.length > 1) {
          final refId = 'm${newT1.substring(1)}';
          if (matchLosers.containsKey(refId)) newT1 = matchLosers[refId]!;
        }
        if (newT2.startsWith('l') && newT2.length > 1) {
          final refId = 'm${newT2.substring(1)}';
          if (matchLosers.containsKey(refId)) newT2 = matchLosers[refId]!;
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
      case 'm49':
        return '1A';
      case 'm50':
        return '2B';
      case 'm51':
        return '1C';
      case 'm52':
        return '2A';
      case 'm53':
        return '1E';
      case 'm54':
        return '2F';
      case 'm55':
        return '1G';
      case 'm56':
        return '2H';
      case 'm57':
        return '1B';
      case 'm58':
        return '2E';
      case 'm59':
        return '1D';
      case 'm60':
        return '2K';
      case 'm61':
        return '1F';
      case 'm62':
        return '1H';
      case 'm63':
        return '1I';
      case 'm64':
        return '1K';
      case 'm65':
        return 'w49';
      case 'm66':
        return 'w51';
      case 'm67':
        return 'w53';
      case 'm68':
        return 'w55';
      case 'm69':
        return 'w57';
      case 'm70':
        return 'w59';
      case 'm71':
        return 'w61';
      case 'm72':
        return 'w63';
      case 'm73':
        return 'w65';
      case 'm74':
        return 'w67';
      case 'm75':
        return 'w69';
      case 'm76':
        return 'w71';
      case 'm77':
        return 'w73';
      case 'm78':
        return 'w75';
      case 'm79':
        return 'l77';
      case 'm80':
        return 'w77';
      default:
        return 'tbd';
    }
  }

  String _getKnockoutPlaceholderT2(String matchId) {
    switch (matchId) {
      case 'm49':
        return '3rd1';
      case 'm50':
        return '2C';
      case 'm51':
        return '3rd2';
      case 'm52':
        return '2D';
      case 'm53':
        return '3rd3';
      case 'm54':
        return '2G';
      case 'm55':
        return '3rd4';
      case 'm56':
        return '2I';
      case 'm57':
        return '3rd5';
      case 'm58':
        return '2J';
      case 'm59':
        return '3rd6';
      case 'm60':
        return '2L';
      case 'm61':
        return '3rd7';
      case 'm62':
        return '3rd8';
      case 'm63':
        return '1J';
      case 'm64':
        return '1L';
      case 'm65':
        return 'w50';
      case 'm66':
        return 'w52';
      case 'm67':
        return 'w54';
      case 'm68':
        return 'w56';
      case 'm69':
        return 'w58';
      case 'm70':
        return 'w60';
      case 'm71':
        return 'w62';
      case 'm72':
        return 'w64';
      case 'm73':
        return 'w66';
      case 'm74':
        return 'w68';
      case 'm75':
        return 'w70';
      case 'm76':
        return 'w72';
      case 'm77':
        return 'w74';
      case 'm78':
        return 'w76';
      case 'm79':
        return 'l78';
      case 'm80':
        return 'w78';
      default:
        return 'tbd';
    }
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

      DateTime scheduledTime = match.date;
      if (alertType == '1h') {
        scheduledTime = match.date.subtract(const Duration(hours: 1));
      }

      await WCNotificationService.scheduleMatchNotification(
        matchId: matchId,
        title: AppTranslations.get(_lang, 'matchStartingSoonTitle'),
        body: AppTranslations.get(
          _lang,
          "matchStartingSoonBody",
        ).replaceAll("{t1}", t1Name).replaceAll('{t2}', t2Name),
        scheduledDate: scheduledTime,
      );

      if (match.t1Score != null && match.t2Score != null) {
        await WCNotificationService.showImmediateScoreNotification(
          match: match,
          lang: _lang,
        );
      }

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
                  AppTranslations.get(
                    _lang,
                    'alertReminderSet',
                  ).replaceAll('{t1}', t1Name).replaceAll('{t2}', t2Name),
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
    debugPrint("DEBUG: Opening match details for ${match.id}");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MatchDetailSheet(
        match: match,
        allMatches: _resolvedMatches,
        lang: _lang,
        activeAlert: _alerts[match.id],
        onSaveAlert: (alertType) => _saveAlert(match.id, alertType),
        prediction: _userPreds?.matchPredictions[match.id],
        boosterMatchIds: _userPreds?.boosterMatchIds ?? [],
        onBoosterChanged: (bool isActive) async {
          if (_userPreds == null) return;
          setState(() {
            if (isActive) {
              if (!_userPreds!.boosterMatchIds.contains(match.id)) {
                _userPreds!.boosterMatchIds.add(match.id);
              }
            } else {
              _userPreds!.boosterMatchIds.remove(match.id);
            }
          });
          await PredictionService.savePredictionData(_userPreds!);
          final totalPoints = PredictionService.calculateTotalPoints(_userPreds!, _resolvedMatches);
          final streak = PredictionService.calculateActiveStreak(_userPreds!, _resolvedMatches);
          final guruCount = PredictionService.calculateExactGuessesCount(_userPreds!, _resolvedMatches);
          await WCFirebaseService.syncUserProfile(
            username: _userPreds!.username,
            supportedTeam: _userPreds!.supportedTeam,
            points: totalPoints,
            streak: streak,
            guruCount: guruCount,
            avatar: _userPreds!.avatar,
          );
        },
        onPredictionChanged: (t1Score, t2Score, etWinner, pkWinner, predictedScorers) =>
            _saveDirectPrediction(match.id, t1Score, t2Score, etWinner, pkWinner, predictedScorers),

      ),
    );
  }

  void _showBeautifulSnackBar(String message, {String emoji = '🎯'}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
        elevation: 4,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        content: Row(
          children: [
            Text('$emoji ', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Saves a prediction directly from the match details modal sheet and triggers Firestore sync.
  Future<void> _saveDirectPrediction(
    String matchId,
    int t1Score,
    int t2Score,
    String? etWinner,
    bool? pkWinner,
    Map<String, int>? predictedScorers,
  ) async {
    if (_userPreds == null) return;

    setState(() {
      _userPreds!.matchPredictions[matchId] = MatchPrediction(
        matchId: matchId,
        t1Score: t1Score,
        t2Score: t2Score,
        extraTimeWinner: etWinner,
        penaltyWinner: pkWinner,
        predictedScorers: predictedScorers,
      );
    });

    await PredictionService.savePredictionData(_userPreds!);
    final totalPoints = PredictionService.calculateTotalPoints(
      _userPreds!,
      _rawMatches,
    );
    final streak = PredictionService.calculateActiveStreak(
      _userPreds!,
      _rawMatches,
    );
    final guruCount = PredictionService.calculateExactGuessesCount(
      _userPreds!,
      _rawMatches,
    );

    await WCFirebaseService.syncUserProfile(
      username: _userPreds!.username,
      supportedTeam: _userPreds!.supportedTeam,
      points: totalPoints,
      streak: streak,
      guruCount: guruCount,
      avatar: _userPreds!.avatar,
    );

    // Refresh prediction views (ChallengeView tab) instantly
    setState(() {
      _challengeViewKey = UniqueKey();
    });

    _showBeautifulSnackBar(
      AppTranslations.get(_lang, 'predictionSavedTooltip'),
      emoji: '🎯',
    );
  }
  // ... existing code ...

  void _onNotificationTap(String payload) {
    if (payload == 'calendar') {
      setState(() => _activeTab = 'matches');
    } else if (payload.startsWith('match_')) {
      final matchId = payload.replaceFirst('match_', '');
      try {
        final match = _resolvedMatches.firstWhere((m) => m.id == matchId);
        _showMatchDetails(match);
      } catch (e) {
        debugPrint("Match not found for notification: $matchId");
      }
    } else if (payload == 'leaderboard') {
      setState(() {
        _activeTab = 'challenge';
        _challengeInitialSubTab = 'leaderboard';
        _challengeViewKey = UniqueKey(); // Force refresh to apply new sub-tab
      });
    }
  }

  void _updateTournamentOddsAndCheckNotifications() {
    final newOdds = WCOddsService.calculateOdds(_resolvedMatches);
    
    // Check for "Big Match" notifications instead of abstract odds shifts
    final now = DateTime.now();
    final upcomingBigMatch = _resolvedMatches.firstWhere(
      (m) => !m.isPlayed && 
             m.date.isAfter(now) && 
             m.date.isBefore(now.add(const Duration(hours: 24))) &&
             (kTeamRatings[m.t1.toLowerCase()] ?? 0) > 1750 && 
             (kTeamRatings[m.t2.toLowerCase()] ?? 0) > 1750,
      orElse: () => _resolvedMatches.first,
    );

    if (upcomingBigMatch.id != _resolvedMatches.first.id) {
       // logic to show a preview if not already shown...
    }

    if (_supportedTeam != null) {
      final favCode = _supportedTeam!.toLowerCase();
      final double oldProb = _currentOdds[favCode] ?? 0.0;
      final double newProb = newOdds[favCode] ?? 0.0;

      if (newProb == 0.0 && oldProb > 0.0) {
        final flag = _getCountryFlagEmoji(favCode);
        final nickname = WCNotificationService.getTeamNickname(favCode, _lang);
        
        WCNotificationService.showNotification(
          id: 9999,
          title: AppTranslations.get(_lang, 'eliminationTitle'),
          body: AppTranslations.get(_lang, 'eliminationBody')
              .replaceAll('{nickname}', nickname)
              .replaceAll('{flag}', flag),
          payload: 'calendar',
        );
      }
    }

    setState(() {
      _currentOdds = newOdds;
    });
  }

  String _getCountryFlagEmoji(String countryCode) {
    final Map<String, String> flags = {
      'ar': '🇦🇷',
      'br': '🇧🇷',
      'fr': '🇫🇷',
      'es': '🇪🇸',
      'en': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'pt': '🇵🇹',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'nl': '🇳🇱',
      'be': '🇧🇪',
      'uy': '🇺🇾',
      'hr': '🇭🇷',
      'ma': '🇲🇦',
      'co': '🇨🇴',
      'mx': '🇲🇽',
      'us': '🇺🇸',
      'jp': '🇯🇵',
      'kr': '🇰🇷',
      'sn': '🇸🇳',
      'ng': '🇳🇬',
      'cm': '🇨🇲',
      'ca': '🇨🇦',
      'dz': '🇩🇿',
      'eg': '🇪🇬',
      'sco': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      'za': '🇿🇦',
      'qa': '🇶🇦',
      'ch': '🇨🇭',
      'ht': '🇭🇹',
      'au': '🇦🇺',
      'tr': '🇹🇷',
      'cw': '🇨🇼',
      'cv': '🇨🇻',
      'ci': '🇨🇮',
      'se': '🇸🇪',
      'tn': '🇹🇳',
      'cd': '🇨🇩',
      'uz': '🇺🇿',
      'gh': '🇬染',
      'pa': '🇵🇦',
      'no': '🇳🇴',
      'iq': '🇮🇶',
      'at': '🇦🇹',
      'jo': '🇯🇴',
      'sa': '🇸🇦',
      'nz': '🇳🇿',
      'ir': '🇮🇷',
      'ec': '🇪🇨',
      'ba': '🇧🇦',
      'py': '🇵🇾',
      'pl': '🇵🇱',
      'cl': '🇨🇱',
      'pe': '🇵🇪',
      'hu': '🇭🇺',
      'cz': '🇨🇿',
      'ro': '🇷🇴',
      'bg': '🇧🇬',
      'rs': '🇷🇸',
      'ua': '🇺🇦',
      've': '🇻🇪',
      'dk': '🇩🇰',
    };
    return flags[countryCode.toLowerCase()] ?? '🏳️';
  }

  String _getLanguageFlag(String langCode) {
    switch (langCode) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      default:
        return '🏳️';
    }
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
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_icon.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF006847), // Mexico Green
                    Color(0xFF002868), // USA Blue
                    Color(0xFFFF0000), // Canada Red
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  AppTranslations.get(_lang, 'appTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (kIsStaging)
            WCTooltip(
              message: 'Staging Debug',
              child: IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.amber),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => const StagingPanelWidget(),
                  ).then((_) {
                    // Rafraîchir les données pour que l'UI affiche les simulations !
                    _loadInitialData();
                  });
                },
              ),
            ),
          // 1. Bouton sélecteur de langue dynamique
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 45),
            color: AppColors.card,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (String value) {
              setState(() => _lang = value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'fr',
                child: Text(
                  '🇫🇷  Français',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'en',
                child: Text(
                  '🇬🇧  English',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'es',
                child: Text(
                  '🇪🇸  Español',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageFlag(_lang),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textDim,
                  ),
                ],
              ),
            ),
          ),

          // 2. Bouton options contextuel
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 45),
            color: AppColors.card,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (String value) {
              if (value == 'anthems') _showAnthemsModal();
              if (value == 'mascots') _showMascotsModal();
              if (value == 'privacy') {
                launchUrl(Uri.parse('https://fnnktkygl-code.github.io/mondial_2026/privacy.html'));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'anthems',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.get(_lang, 'anthemsTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'mascots',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.get(_lang, 'mascotsTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    ],
                    ),
                    ),
                    PopupMenuItem<String>(
                    value: 'privacy',
                    child: Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppTranslations.get(_lang, 'privacyPolicy'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    ],
                    ),
                    ),
                    ],
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // 3. Bouton Profil
          if (_userPreds != null)
            GestureDetector(
              onTap: _showProfileModal,
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 16),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  backgroundImage:
                      (_userPreds!.avatar.isNotEmpty &&
                          _userPreds!.avatar.contains('.png'))
                      ? AssetImage(_userPreds!.avatar)
                      : null,
                  child:
                      (_userPreds!.avatar.isEmpty ||
                          !_userPreds!.avatar.contains('.png'))
                      ? const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppColors.accent,
                        )
                      : null,
                ),
              ),
            ),
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
                                borderRadius: BorderRadius.circular(
                                  kCardRadius,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _matchFilter = 'all'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _matchFilter == 'all'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          kButtonRadius,
                                        ),
                                      ),
                                      child: Text(
                                        AppTranslations.get(
                                          _lang,
                                          'allMatches',
                                        ),
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
                                    onTap: () =>
                                        setState(() => _matchFilter = 'alerts'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _matchFilter == 'alerts'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          kButtonRadius,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.notifications_none_outlined,
                                            size: 14,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppTranslations.get(
                                              _lang,
                                              'myAlerts',
                                            ),
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
                                borderRadius: BorderRadius.circular(
                                  kCardRadius,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  WCTooltip(
                                    message: AppTranslations.get(
                                      _lang,
                                      'listView',
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.list_alt,
                                        size: 20,
                                        color: AppColors.accent,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: _viewMode == 'list'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            kButtonRadius,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() => _viewMode = 'list');
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _scrollToCurrentMatch();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  WCTooltip(
                                    message: AppTranslations.get(
                                      _lang,
                                      'calendarView',
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 20,
                                        color: AppColors.accent,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: _viewMode == 'calendar'
                                            ? AppColors.border
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            kButtonRadius,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          setState(() => _viewMode = 'calendar'),
                                    ),
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
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Builder(
          builder: (context) {
            final tabsList = ['matches', 'standings', 'bracket', 'challenge'];
            final currentIndex = tabsList
                .indexOf(_activeTab)
                .clamp(0, tabsList.length - 1);

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
                if (tabsList[index] == 'matches') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCurrentMatch();
                  });
                }
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
          },
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStandingsSubTabButton(
                  'groups',
                  AppTranslations.get(_lang, 'groupsTab'),
                  Icons.table_rows,
                ),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton(
                  'scorers',
                  AppTranslations.get(_lang, 'scorersTab'),
                  Icons.sports_soccer,
                ),
                const SizedBox(width: 8),
                _buildStandingsSubTabButton(
                  'team',
                  AppTranslations.get(_lang, 'teamStatsTab'),
                  Icons.search,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _getStandingsSubTabContent()),
      ],
    );
  }

  Widget _buildStandingsSubTabButton(
    String subTab,
    String label,
    IconData icon,
  ) {
    final isSelected = _standingsSubTab == subTab;
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.black : AppColors.textMuted,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.black : Colors.white,
        backgroundColor: isSelected ? AppColors.accent : AppColors.card,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
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
    } else if (_standingsSubTab == 'team') {
      return TeamStatsWidget(
        matches: _resolvedMatches,
        lang: _lang,
        onMatchTap: _showMatchDetails,
      );
    } else {
      return GroupTableWidget(
        matches: _resolvedMatches,
        lang: _lang,
        supportedTeamCode: _supportedTeam,
      );
    }
  }

  Future<void> _refreshMatches() async {
    final matches = await ApiService.loadMatches(forceRefresh: true);
    if (mounted) {
      setState(() {
        _rawMatches = matches;
        _resolvedMatches = _resolveMatchesPlaceholders(_rawMatches);
      });
    }
  }

  void _scrollToCurrentMatch() {
    if (_resolvedMatches.isEmpty || !_listScrollController.hasClients || _viewMode != 'list') return;

    final Map<String, List<WorldCupMatch>> matchesByDate = {};
    for (var m in _resolvedMatches) {
      final dateLabel = DateFormat.yMd(_lang).format(m.date);
      matchesByDate.putIfAbsent(dateLabel, () => []).add(m);
    }

    final sortedDates = matchesByDate.keys.toList()
      ..sort((a, b) {
        final d1 = DateFormat.yMd(_lang).parse(a);
        final d2 = DateFormat.yMd(_lang).parse(b);
        return d1.compareTo(d2);
      });

    final now = DateTime.now();
    WorldCupMatch? targetMatch;

    // Look for live match
    try {
      targetMatch = _resolvedMatches.firstWhere((m) {
        final localDate = m.date.toLocal();
        final duration = m.isKnockout 
            ? const Duration(minutes: 180) 
            : const Duration(minutes: 120);
        return !m.isPlayed && 
            m.status != 'FINISHED' && 
            now.isAfter(localDate) && 
            now.isBefore(localDate.add(duration));
      });
    } catch (_) {
      // Look for next upcoming match
      try {
        targetMatch = _resolvedMatches.firstWhere(
          (m) => !m.isPlayed && m.status != 'FINISHED' && m.date.isAfter(now),
        );
      } catch (_) {
        // Fallback to the last match
        if (_resolvedMatches.isNotEmpty) {
          targetMatch = _resolvedMatches.last;
        }
      }
    }

    if (targetMatch == null) return;

    final targetDateStr = DateFormat.yMd(_lang).format(targetMatch.date);
    final targetIndex = sortedDates.indexOf(targetDateStr);

    if (targetIndex >= 0) {
      double scrollOffset = 0.0;
      for (int i = 0; i < targetIndex; i++) {
        final dateLabel = sortedDates[i];
        final numMatches = matchesByDate[dateLabel]?.length ?? 0;
        // Daily header (~46.0 px) + match cards (~155.0 px each)
        scrollOffset += 46.0 + (numMatches * 155.0);
      }

      final maxScroll = _listScrollController.position.maxScrollExtent;
      scrollOffset = scrollOffset.clamp(0.0, maxScroll);

      _listScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
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
        supportedTeamCode: _userPreds?.supportedTeam,
        predictions: _userPreds?.matchPredictions,
      );
    }

    if (_activeTab == 'challenge') {
      return ChallengeViewWidget(
        key: _challengeViewKey,
        matches: _resolvedMatches,
        lang: _lang,
        initialSubTab: _challengeInitialSubTab,
        onProfileTap: _showProfileModal,
        showSnackBar: (msg) => _showBeautifulSnackBar(msg),
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

    if (filteredMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.borderStrong,
            ),
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
        hasPredicted: (match) {
          if (_userPreds == null) return false;
          return _userPreds!.matchPredictions.containsKey(match.id);
        },
        userPredictions: _userPreds?.matchPredictions,
        alertType: (match) =>
            PredictionService.getPredictionResult(match, _userPreds),
        supportedTeamCode: _supportedTeam,
        onMatchTap: _showMatchDetails,
      );
    }

    final sortedDates = matchesByDate.keys.toList()
      ..sort((a, b) {
        final d1 = DateFormat.yMd(_lang).parse(a);
        final d2 = DateFormat.yMd(_lang).parse(b);
        return d1.compareTo(d2);
      });

    return RefreshIndicator(
      onRefresh: _refreshMatches,
      child: ListView.builder(
        controller: _listScrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIdx) {
          final dateLabel = sortedDates[dateIdx];
          final dayMatches = matchesByDate[dateLabel]!;
          final firstMatchDate = dayMatches.first.date;
          final weekdayStr = DateFormat(
            'EEEE d MMMM',
            _lang,
          ).format(firstMatchDate);

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
                  matches: _resolvedMatches,
                  lang: _lang,
                  hasAlert: _hasAlert(m),
                  userPrediction: _userPreds?.matchPredictions[m.id],
                  alertType: (WorldCupMatch match) =>
                      PredictionService.getPredictionResult(match, _userPreds),
                  predictionResult:
                      PredictionService.getPredictionResult(m, _userPreds),
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
      ),
    );
  }
}
