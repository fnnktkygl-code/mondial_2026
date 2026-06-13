import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/prediction_service.dart';

import '../services/player_database_service.dart';

// Player pools for simulation
// REMOVED: Now using PlayerDatabaseService


const List<Map<String, String>> r32Pairings = [
  {'id': 'm49', 't1': '1A', 't2': '3rd1'},
  {'id': 'm50', 't1': '2B', 't2': '2C'},
  {'id': 'm51', 't1': '1C', 't2': '3rd2'},
  {'id': 'm52', 't1': '2A', 't2': '2D'},
  {'id': 'm53', 't1': '1E', 't2': '3rd3'},
  {'id': 'm54', 't1': '2F', 't2': '2G'},
  {'id': 'm55', 't1': '1G', 't2': '3rd4'},
  {'id': 'm56', 't1': '2H', 't2': '2I'},
  {'id': 'm57', 't1': '1B', 't2': '3rd5'},
  {'id': 'm58', 't1': '2E', 't2': '2J'},
  {'id': 'm59', 't1': '1D', 't2': '3rd6'},
  {'id': 'm60', 't1': '2K', 't2': '2L'},
  {'id': 'm61', 't1': '1F', 't2': '3rd7'},
  {'id': 'm62', 't1': '1H', 't2': '3rd8'},
  {'id': 'm63', 't1': '1I', 't2': '1J'},
  {'id': 'm64', 't1': '1K', 't2': '1L'}
];

class StagingPanelWidget extends StatefulWidget {
  const StagingPanelWidget({super.key});

  @override
  State<StagingPanelWidget> createState() => _StagingPanelWidgetState();
}

class _StagingPanelWidgetState extends State<StagingPanelWidget> {
  final _usersController = TextEditingController(text: '50');
  final _groupsController = TextEditingController(text: '10');
  final _levelController = TextEditingController(text: '3');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    PlayerDatabaseService.loadPlayers();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── HELPER: Realistic Goals & Stats ──────────────────────────────────────────

  List<GoalEvent> _simulateGoals(String t1, String t2, int score1, int score2, Random rand) {
    final List<GoalEvent> goalsList = [];
    
    // Team code to Full Name mapping (Matches JSON keys)
    final Map<String, String> teamCodeToName = {
      'mx': 'Mexico', 'co': 'Colombia', 'cm': 'Cameroon', 'kr': 'South Korea',
      'us': 'USA', 'en': 'England', 'ng': 'Nigeria', 'jp': 'Japan',
      'ca': 'Canada', 'fr': 'France', 'sn': 'Senegal', 'de': 'Germany',
      'br': 'Brazil', 'ar': 'Argentina', 'ma': 'Morocco', 'es': 'Spain',
      'it': 'Italy', 'pt': 'Portugal', 'nl': 'Netherlands', 'be': 'Belgium',
      'hr': 'Croatia', 'uy': 'Uruguay', 'se': 'Sweden', 'ch': 'Switzerland',
      'dk': 'Denmark', 'pl': 'Poland', 'ua': 'Ukraine', 'dz': 'Algeria',
      'eg': 'Egypt', 'tn': 'Tunisia', 'gh': 'Ghana', 'ci': 'Ivory Coast',
      'cl': 'Chile', 'pe': 'Peru', 'ec': 'Ecuador', 've': 'Venezuela',
      'au': 'Australia', 'nz': 'New Zealand', 'sa': 'Saudi Arabia', 'ir': 'Iran',
      'tr': 'Turkey', 'gr': 'Greece', 'cz': 'Czech Republic', 'at': 'Austria',
      'ro': 'Romania', 'hu': 'Hungary', 'bg': 'Bulgaria', 'rs': 'Serbia'
    };

    final t1Name = teamCodeToName[t1.toLowerCase()] ?? 'Team ($t1)';
    final t2Name = teamCodeToName[t2.toLowerCase()] ?? 'Team ($t2)';

    final List<String> t1Pool = PlayerDatabaseService.getPlayersForTeam(t1Name);
    final List<String> t2Pool = PlayerDatabaseService.getPlayersForTeam(t2Name);
        
    // Simulate for Team 1
    for (int i = 0; i < score1; i++) {
      String scorer;
      String? assistant;
      
      if (t1Pool.isNotEmpty) {
        scorer = t1Pool[rand.nextInt(t1Pool.length)];
        if (rand.nextBool() && t1Pool.length > 1) {
          final candidates = t1Pool.where((p) => p != scorer).toList();
          if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
        }
      } else {
        scorer = t1Name; // Fallback to team name if no players found
      }
      
      goalsList.add(GoalEvent(
        team: 't1', 
        scorer: scorer, 
        assistant: assistant, 
        minute: rand.nextInt(90) + 1
      ));
    }

    // Simulate for Team 2
    for (int i = 0; i < score2; i++) {
      String scorer;
      String? assistant;

      if (t2Pool.isNotEmpty) {
        scorer = t2Pool[rand.nextInt(t2Pool.length)];
        if (rand.nextBool() && t2Pool.length > 1) {
          final candidates = t2Pool.where((p) => p != scorer).toList();
          if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
        }
      } else {
        scorer = t2Name; // Fallback to team name if no players found
      }

      goalsList.add(GoalEvent(
        team: 't2', 
        scorer: scorer, 
        assistant: assistant, 
        minute: rand.nextInt(90) + 1
      ));
    }

    goalsList.sort((a, b) => a.minute.compareTo(b.minute));
    return goalsList;
  }

  MatchStats _simulateStats(int score1, int score2, Random rand) {
    final possessionT1 = 35 + rand.nextInt(31); 
    final shotsT1 = score1 + rand.nextInt(15);
    final shotsT2 = score2 + rand.nextInt(15);
    return MatchStats(
      possessionT1: possessionT1,
      shotsT1: shotsT1,
      shotsT2: shotsT2,
      shotsOnTargetT1: score1 + rand.nextInt(max(1, shotsT1 - score1 + 1)),
      shotsOnTargetT2: score2 + rand.nextInt(max(1, shotsT2 - score2 + 1)),
      foulsT1: 5 + rand.nextInt(15),
      foulsT2: 5 + rand.nextInt(15),
      yellowCardsT1: rand.nextInt(5),
      yellowCardsT2: rand.nextInt(5),
      redCardsT1: rand.nextInt(20) == 0 ? 1 : 0,
      redCardsT2: rand.nextInt(20) == 0 ? 1 : 0,
    );
  }

  // ─── ACTION: Match Simulations ────────────────────────────────────────────────

  WorldCupMatch _simulateSingleMatch(WorldCupMatch match, Random random) {
    int score1 = random.nextInt(4);
    int score2 = random.nextInt(4);
    
    bool wentToET = false;
    bool wentToPK = false;
    String? etWinner;
    String? pkWinner;

    if (match.isKnockout && score1 == score2) {
      wentToET = true;
      if (random.nextBool()) {
        // Extra time goal
        if (random.nextBool()) {
          score1++;
          etWinner = match.t1;
        } else {
          score2++;
          etWinner = match.t2;
        }
      } else {
        // Penalties
        wentToPK = true;
        pkWinner = random.nextBool() ? match.t1 : match.t2;
      }
    }

    final goals = _simulateGoals(match.t1, match.t2, score1, score2, random);
    final stats = _simulateStats(score1, score2, random);

    return match.copyWith(
      t1Score: score1,
      t2Score: score2,
      goals: goals,
      stats: stats,
      wentToET: wentToET,
      wentToPK: wentToPK,
      etWinner: etWinner,
      pkWinner: pkWinner,
      status: 'FINISHED',
    );
  }

  void _updateSimEntry(SimTeamEntry e1, SimTeamEntry e2, int s1, int s2) {
    e1.played++; e2.played++;
    e1.goalsFor += s1; e1.goalsAgainst += s2;
    e2.goalsFor += s2; e2.goalsAgainst += s1;
    if (s1 > s2) { e1.wins++; e2.losses++; }
    else if (s1 < s2) { e2.wins++; e1.losses++; }
    else { e1.draws++; e2.draws++; }
  }

  String _resolvePlaceholder(String placeholder, Map<String, List<SimTeamEntry>> standings, List<SimTeamEntry> thirdPlaces) {
    if (placeholder.startsWith('1')) {
      final key = placeholder.substring(1);
      final group = standings[key];
      if (group != null && group.isNotEmpty) return group[0].code;
    }
    if (placeholder.startsWith('2')) {
      final key = placeholder.substring(1);
      final group = standings[key];
      if (group != null && group.length > 1) return group[1].code;
    }
    if (placeholder.startsWith('3rd')) {
      final idxStr = placeholder.substring(3);
      final idx = int.tryParse(idxStr);
      if (idx != null && idx > 0 && idx <= thirdPlaces.length) {
        return thirdPlaces[idx - 1].code;
      }
    }
    return 'TBD';
  }

  String _getMatchWinner(WorldCupMatch m) {
    if (m.wentToPK == true) return m.pkWinner!;
    return (m.t1Score! > m.t2Score!) ? m.t1 : m.t2;
  }

  Future<void> _simulateMatches({required bool allMatches, bool stopAtQF = false}) async {
    setState(() => _isLoading = true);
    debugPrint("StagingPanel: Starting simulation... stopAtQF: $stopAtQF");
    await PlayerDatabaseService.loadPlayers(); 
    debugPrint("StagingPanel: PlayerDatabaseService loaded.");
    try {
      final List<WorldCupMatch> matches = await ApiService.loadMatches(forceRefresh: false);
      debugPrint("StagingPanel: Loaded ${matches.length} matches.");
      final random = Random();

      if (!allMatches) {
        // Just group stage
        for (int i = 0; i < matches.length; i++) {
          final m = matches[i];
          if (!m.isKnockout && m.t1 != 'TBD' && m.t2 != 'TBD') {
            matches[i] = _simulateSingleMatch(m, random);
          }
        }
      } else {
        // FULL OR PARTIAL COMPETITION PROGRESSION
        // 1. Group Stage
        final Map<String, List<SimTeamEntry>> standings = {};
        
        // Build standings entries dynamically from matches to be robust
        for (final m in matches) {
          if (!m.isKnockout && m.group != null && m.group!.isNotEmpty) {
            standings.putIfAbsent(m.group!, () => []);
            if (!standings[m.group!]!.any((e) => e.code == m.t1)) {
              standings[m.group!]!.add(SimTeamEntry(m.t1));
            }
            if (!standings[m.group!]!.any((e) => e.code == m.t2)) {
              standings[m.group!]!.add(SimTeamEntry(m.t2));
            }
          }
        }

        for (int i = 0; i < matches.length; i++) {
          final m = matches[i];
          if (!m.isKnockout) {
            final updated = _simulateSingleMatch(m, random);
            matches[i] = updated;
            
            // Update standings safely
            final group = standings[m.group];
            if (group != null) {
              final e1 = group.where((e) => e.code == updated.t1).firstOrNull;
              final e2 = group.where((e) => e.code == updated.t2).firstOrNull;
              if (e1 != null && e2 != null) {
                _updateSimEntry(e1, e2, updated.t1Score ?? 0, updated.t2Score ?? 0);
              }
            }
          }
        }
        debugPrint("StagingPanel: Group stage simulation complete.");

        // Sort groups
        standings.forEach((g, list) {
          list.sort((a, b) {
            if (b.points != a.points) return b.points.compareTo(a.points);
            if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
            return b.goalsFor.compareTo(a.goalsFor);
          });
        });

        // Best 3rd places (safe access)
        final thirdPlaces = standings.values
            .where((list) => list.length >= 3)
            .map((list) => list[2])
            .toList();
        thirdPlaces.sort((a, b) {
          if (b.points != a.points) return b.points.compareTo(a.points);
          if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
          return b.goalsFor.compareTo(a.goalsFor);
        });

        // 2. Round of 32
        final Map<String, String> winners = {};
        for (final pair in r32Pairings) {
          final mIdx = matches.indexWhere((m) => m.id == pair['id']);
          if (mIdx != -1) {
            final t1 = _resolvePlaceholder(pair['t1']!, standings, thirdPlaces);
            final t2 = _resolvePlaceholder(pair['t2']!, standings, thirdPlaces);
            final updated = _simulateSingleMatch(matches[mIdx].copyWith(t1: t1, t2: t2), random);
            matches[mIdx] = updated;
            winners[updated.id] = _getMatchWinner(updated);
          }
        }

        // 3. Round of 16
        final List<List<String>> r16Pairs = [
          ['m49', 'm50'], ['m51', 'm52'], ['m53', 'm54'], ['m55', 'm56'],
          ['m57', 'm58'], ['m59', 'm60'], ['m61', 'm62'], ['m63', 'm64']
        ];
        for (int i = 0; i < r16Pairs.length; i++) {
          final id = 'm${65 + i}';
          final mIdx = matches.indexWhere((m) => m.id == id);
          if (mIdx != -1) {
            final t1 = winners[r16Pairs[i][0]] ?? 'TBD';
            final t2 = winners[r16Pairs[i][1]] ?? 'TBD';
            final updated = _simulateSingleMatch(matches[mIdx].copyWith(t1: t1, t2: t2), random);
            matches[mIdx] = updated;
            winners[updated.id] = _getMatchWinner(updated);
          }
        }

        // 4. Quarter-Finals
        final List<List<String>> qfPairs = [
          ['m65', 'm66'], ['m67', 'm68'], ['m69', 'm70'], ['m71', 'm72']
        ];
        for (int i = 0; i < qfPairs.length; i++) {
          final id = 'm${73 + i}';
          final mIdx = matches.indexWhere((m) => m.id == id);
          if (mIdx != -1) {
            final t1 = winners[qfPairs[i][0]] ?? 'TBD';
            final t2 = winners[qfPairs[i][1]] ?? 'TBD';
            final updated = _simulateSingleMatch(matches[mIdx].copyWith(t1: t1, t2: t2), random);
            matches[mIdx] = updated;
            winners[updated.id] = _getMatchWinner(updated);
          }
        }

        // Stop here if requested
        if (!stopAtQF) {
          // 5. Semi-Finals
          final List<List<String>> sfPairs = [
            ['m73', 'm74'], ['m75', 'm76']
          ];
          for (int i = 0; i < sfPairs.length; i++) {
            final id = 'm${77 + i}';
            final mIdx = matches.indexWhere((m) => m.id == id);
            if (mIdx != -1) {
              final t1 = winners[sfPairs[i][0]] ?? 'TBD';
              final t2 = winners[sfPairs[i][1]] ?? 'TBD';
              final updated = _simulateSingleMatch(matches[mIdx].copyWith(t1: t1, t2: t2), random);
              matches[mIdx] = updated;
              winners[updated.id] = _getMatchWinner(updated);
            }
          }

          // 6. 3rd Place & Final
          final m79Idx = matches.indexWhere((m) => m.id == 'm79');
          final m80Idx = matches.indexWhere((m) => m.id == 'm80');
          
          if (m79Idx != -1 && m80Idx != -1) {
             final sf1Idx = matches.indexWhere((m) => m.id == 'm77');
             final sf2Idx = matches.indexWhere((m) => m.id == 'm78');
             
             if (sf1Idx != -1 && sf2Idx != -1) {
               final sf1 = matches[sf1Idx];
               final sf2 = matches[sf2Idx];
               
               final w1 = winners['m77'] ?? 'TBD';
               final l1 = sf1.t1 == w1 ? sf1.t2 : sf1.t1;
               
               final w2 = winners['m78'] ?? 'TBD';
               final l2 = sf2.t1 == w2 ? sf2.t2 : sf2.t1;
               
               matches[m79Idx] = _simulateSingleMatch(matches[m79Idx].copyWith(t1: l1, t2: l2), random);
               matches[m80Idx] = _simulateSingleMatch(matches[m80Idx].copyWith(t1: w1, t2: w2), random);
             }
          }
        }
      }

      await ApiService.saveMatchesToCache(matches);
      _showSnackBar(stopAtQF ? 'Simulé jusqu\'aux quarts !' : 'Tournoi complet simulé !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetMatches() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.resetCache();
      _showSnackBar('Simulations effacées !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── ACTION: User Predictions Mock ──────────────────────────────────────────

  Future<void> _mockMyPredictions() async {
    setState(() => _isLoading = true);
    try {
      final preds = await PredictionService.loadPredictionData();
      final List<WorldCupMatch> matches = await ApiService.loadMatches(forceRefresh: false);
      final random = Random();

      for (final match in matches) {
        if (match.t1.isEmpty || match.t2.isEmpty || match.t1 == 'TBD' || match.t2 == 'TBD') continue;
        
        preds.matchPredictions[match.id] = MatchPrediction(
          matchId: match.id,
          t1Score: random.nextInt(4),
          t2Score: random.nextInt(4),
        );
      }

      // Identify winners from simulated matches (if played)
      final stats = TournamentStats.compute(matches);
      final String actualScorer = stats.scorers.isNotEmpty ? stats.scorers.first.name : 'Kylian Mbappé';
      final String actualAssister = stats.assists.isNotEmpty ? stats.assists.first.name : 'Lionel Messi';
      
      final finalMatch = matches.firstWhere((m) => m.id == 'm80', orElse: () => matches[0]);
      String actualChampion = 'fr';
      if (finalMatch.isPlayed) {
        actualChampion = finalMatch.wentToPK == true ? finalMatch.pkWinner! : 
                        (finalMatch.t1Score! > finalMatch.t2Score! ? finalMatch.t1 : finalMatch.t2);
      }

      preds.championCode = actualChampion;
      preds.championPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      preds.goldenBootWinner = actualScorer;
      // preds.goldenBootPlayer = actualScorer; // REMOVED: Do not overwrite user's prediction
      preds.goldenBootPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      preds.topAssisterWinner = actualAssister;
      // preds.topAssisterPlayer = actualAssister; // REMOVED
      preds.topAssisterPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      await PredictionService.savePredictionData(preds);
      
      final totalPoints = PredictionService.calculateTotalPoints(preds, matches);
      final streak = PredictionService.calculateActiveStreak(preds, matches);
      final guruCount = PredictionService.calculateExactGuessesCount(preds, matches);
      
      await WCFirebaseService.syncUserProfile(
        username: preds.username,
        supportedTeam: preds.supportedTeam,
        points: totalPoints,
        streak: streak,
        guruCount: guruCount,
        avatar: preds.avatar,
      );

      _showSnackBar('Vos pronostics ont été générés et synchronisés !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetMyPredictions() async {
    setState(() => _isLoading = true);
    try {
      final preds = await PredictionService.loadPredictionData();
      preds.matchPredictions.clear();
      preds.championCode = null;
      preds.goldenBootPlayer = null;
      preds.topAssisterPlayer = null;
      
      await PredictionService.savePredictionData(preds);
      
      await WCFirebaseService.syncUserProfile(
        username: preds.username,
        supportedTeam: preds.supportedTeam,
        points: 0,
        streak: 0,
        guruCount: 0,
        avatar: preds.avatar,
      );

      _showSnackBar('Vos pronostics ont été réinitialisés !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── ACTION: User & Group Mocks ────────────────────────────────────────────

  Future<void> _generateMockUsers() async {
    setState(() => _isLoading = true);
    try {
      final int count = int.tryParse(_usersController.text) ?? 50;
      final int level = int.tryParse(_levelController.text) ?? 1;
      final firestore = FirebaseFirestore.instance;
      final random = Random();
      
      int basePoints = 10;
      if (level == 2) basePoints = 150;
      if (level == 3) basePoints = 400;
      if (level == 4) basePoints = 800;

      final List<String> mockPseudos = [
        'DarkNinja', 'SoccerFan', 'ElFideo', 'Capitan', 'GoalMachine', 
        'PronoKing', 'D10S_Messi', 'CR7_GOAT', 'Mbappe_Speed', 'BleuEtFier', 
        'Zizou10', 'TikiTaka', 'LaPulga', 'Maestro', 'GoldenBoot'
      ];

      for (int i = 0; i < count; i++) {
        final pseudo = '${mockPseudos[random.nextInt(mockPseudos.length)]}${random.nextInt(999)}';
        final avatarId = random.nextInt(32) + 1;
        
        await firestore.collection('users').add({
          'username': pseudo,
          'points': basePoints + random.nextInt(100),
          'streak': random.nextInt(5),
          'guruCount': random.nextInt(3),
          'avatar': 'assets/avatars/$avatarId.png',
          'isHidden': false,
          'isMock': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar('$count joueurs générés !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _showSnackBar('Tous les joueurs supprimés.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateMockGroups() async {
    setState(() => _isLoading = true);
    try {
      final int count = int.tryParse(_groupsController.text) ?? 10;
      final uid = await WCFirebaseService.getOrCreateUserId();
      debugPrint("StagingPanel: Generating groups for UID: $uid");
      final firestore = FirebaseFirestore.instance;
      final random = Random();

      final mockUsersSnap = await firestore.collection('users').where('isMock', isEqualTo: true).limit(20).get();
      final List<String> availableMockUids = mockUsersSnap.docs.map((d) => d.id).toList();

      for (int i = 0; i < count; i++) {
        final List<String> members = [uid];
        if (availableMockUids.isNotEmpty) {
          final int membersToAdd = random.nextInt(min(8, availableMockUids.length)) + 3;
          final shuffled = List<String>.from(availableMockUids)..shuffle(random);
          members.addAll(shuffled.take(membersToAdd));
        }

        await firestore.collection('groups').add({
          'name': 'Groupe Mock $i',
          'creatorId': uid,
          'members': members,
          'inviteToken': 'mock_${random.nextInt(9999)}',
          'isMock': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar('$count groupes générés !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllGroups() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('groups').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _showSnackBar('Tous les groupes supprimés.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🛠️ Panneau de Staging',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _mockMyPredictions,
              icon: const Icon(Icons.edit_note),
              label: const Text('Générer MES propres pronostics'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _resetMyPredictions,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('RÉINITIALISER mes pronostics'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            ),
            const Divider(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _simulateMatches(allMatches: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('Simuler TOUTE la Compétition'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _simulateMatches(allMatches: true, stopAtQF: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
              child: const Text('Simuler jusqu\'aux Quarts'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetMatches,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Réinitialiser les Matchs (0-0)'),
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(child: TextField(controller: _usersController, decoration: const InputDecoration(labelText: 'Nbr Joueurs', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _levelController, decoration: const InputDecoration(labelText: 'Niveau (1-4)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _generateMockUsers, child: const Text('Générer Joueurs'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _deleteAllUsers, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('TOUT Purger'))),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _generateMockGroups, child: const Text('Générer Groupes'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _deleteAllGroups, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('TOUT Purger'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SimTeamEntry {
  final String code;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;

  SimTeamEntry(this.code);
}
