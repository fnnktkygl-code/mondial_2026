import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/prediction_service.dart';

// Player pools for simulation
const Map<String, List<String>> playerPools = {
  'mx': ['H. Lozano', 'R. Jiménez', 'S. Giménez', 'U. Antuna'],
  'pl': ['R. Lewandowski', 'P. Zieliński', 'K. Świderski'],
  'ar': ['L. Messi', 'L. Martínez', 'J. Álvarez'],
  'fr': ['K. Mbappé', 'O. Giroud', 'O. Dembélé', 'A. Griezmann'],
  // ... (rest unchanged in actual execution)


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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── HELPER: Realistic Goals & Stats ──────────────────────────────────────────

  List<GoalEvent> _simulateGoals(String t1, String t2, int score1, int score2, Random rand) {
    final List<GoalEvent> goalsList = [];
    final t1Players = playerPools[t1] ?? ['Player A', 'Player B'];
    final t2Players = playerPools[t2] ?? ['Player C', 'Player D'];

    for (int i = 0; i < score1; i++) {
      final scorer = t1Players[rand.nextInt(t1Players.length)];
      String? assistant;
      if (rand.nextBool()) {
        final candidates = t1Players.where((p) => p != scorer).toList();
        if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
      }
      goalsList.add(GoalEvent(team: 't1', scorer: scorer, assistant: assistant, minute: rand.nextInt(90) + 1));
    }

    for (int i = 0; i < score2; i++) {
      final scorer = t2Players[rand.nextInt(t2Players.length)];
      String? assistant;
      if (rand.nextBool()) {
        final candidates = t2Players.where((p) => p != scorer).toList();
        if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
      }
      goalsList.add(GoalEvent(team: 't2', scorer: scorer, assistant: assistant, minute: rand.nextInt(90) + 1));
    }

    goalsList.sort((a, b) => a.minute.compareTo(b.minute));
    return goalsList;
  }

  MatchStats _simulateStats(int score1, int score2, Random rand) {
    final possessionT1 = 35 + rand.nextInt(31); 
    final shotsT1 = score1 + rand.nextInt(12);
    final shotsT2 = score2 + rand.nextInt(12);
    return MatchStats(
      possessionT1: possessionT1,
      shotsT1: shotsT1,
      shotsT2: shotsT2,
      shotsOnTargetT1: score1 + rand.nextInt(shotsT1 - score1 + 1),
      shotsOnTargetT2: score2 + rand.nextInt(shotsT2 - score2 + 1),
      foulsT1: 6 + rand.nextInt(14),
      foulsT2: 6 + rand.nextInt(14),
      yellowCardsT1: rand.nextInt(4),
      yellowCardsT2: rand.nextInt(4),
      redCardsT1: rand.nextInt(10) == 0 ? 1 : 0,
      redCardsT2: rand.nextInt(10) == 0 ? 1 : 0,
    );
  }

  // ─── ACTION: Match Simulations ────────────────────────────────────────────────

  Future<void> _simulateMatches({required bool allMatches}) async {
    setState(() => _isLoading = true);
    try {
      final List<WorldCupMatch> matches = await ApiService.loadMatches(forceRefresh: false);
      final random = Random();

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        bool shouldSimulate = allMatches ? true : !match.isKnockout;
        
        if (shouldSimulate && match.t1.isNotEmpty && match.t2.isNotEmpty && match.t1 != 'TBD' && match.t2 != 'TBD') {
          int score1 = random.nextInt(4);
          int score2 = random.nextInt(4);
          
          bool wentToET = false;
          bool wentToPK = false;
          String? etWinner;
          String? pkWinner;

          if (match.isKnockout && score1 == score2) {
            wentToET = true;
            // 50% chance of ending in extra time vs penalties
            if (random.nextBool()) {
              if (random.nextBool()) {
                score1++;
                etWinner = match.t1;
              } else {
                score2++;
                etWinner = match.t2;
              }
            } else {
              wentToPK = true;
              pkWinner = random.nextBool() ? match.t1 : match.t2;
            }
          }

          final goals = _simulateGoals(match.t1, match.t2, score1, score2, random);
          final stats = _simulateStats(score1, score2, random);

          matches[i] = match.copyWith(
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
      }

      await ApiService.saveMatchesToCache(matches);
      _showSnackBar('Matchs et Stats simulés ! Redémarrez l\'app ou changez d\'onglet.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetMatches() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.resetCache();
      _showSnackBar('Simulations effacées ! Redémarrez l\'app.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
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

      preds.championCode = 'fr';
      preds.championPredictedAt = DateTime.now().subtract(const Duration(days: 30));
      
      preds.goldenBootWinner = 'pl'; // team
      preds.goldenBootPlayer = 'Robert Lewandowski'; // Nom COMPLET (FIFA style)
      preds.goldenBootPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      preds.topAssisterWinner = 'ar'; // team
      preds.topAssisterPlayer = 'Lionel Messi'; // Nom COMPLET
      preds.topAssisterPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      await PredictionService.savePredictionData(preds);
      // Synchroniser immédiatement avec Firebase pour le classement
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
      
      int basePoints = 10; // Garantir au moins 10 points pour ne pas être caché
      if (level == 2) basePoints = 150;
      if (level == 3) basePoints = 400;
      if (level == 4) basePoints = 800;

      final List<String> mockPseudos = [
        'DarkNinja', 'SoccerFan', 'ElFideo', 'Capitan', 'GoalMachine', 
        'PronoKing', 'D10S_Messi', 'CR7_GOAT', 'Mbappe_Speed', 'BleuEtFier', 
        'Zizou10', 'TikiTaka', 'LaPulga', 'MagicFoot', 'Sniper', 
        'Goleador', 'ElMatador', 'FootAddict', 'Champion2026', 'Mondialiste',
        'Maestro', 'GoldenBoot', 'Catenaccio', 'ButeurFou', 'LeStratege'
      ];

      for (int i = 0; i < count; i++) {
        final pseudoBase = mockPseudos[random.nextInt(mockPseudos.length)];
        final pseudo = '$pseudoBase${random.nextInt(999)}';
        final avatarId = random.nextInt(32) + 1; // 1 à 32
        
        final docRef = firestore.collection('users').doc('mock_user_${i}_${random.nextInt(10000)}');
        await docRef.set({
          'username': pseudo,
          'points': basePoints + random.nextInt(100),
          'streak': random.nextInt(5),
          'guruCount': random.nextInt(3),
          'avatar': 'assets/avatars/$avatarId.png', // Assignation d'un vrai avatar
          'isHidden': false,
          'isMock': true, // Identifier for deletion
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar('$count joueurs (Niveau $level) générés !');
    } catch (e) {
      _showSnackBar('Erreur (Vérifiez Firestore Rules) : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      // Supprime TOUT le monde, y compris le compte de test actuel
      final snapshot = await firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _showSnackBar('${snapshot.docs.length} joueurs (TOUS) ont été supprimés.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateMockGroups() async {
    setState(() => _isLoading = true);
    try {
      final int count = int.tryParse(_groupsController.text) ?? 10;
      final uid = await WCFirebaseService.getOrCreateUserId();
      final firestore = FirebaseFirestore.instance;
      final random = Random();

      // Récupérer quelques utilisateurs mock pour les ajouter aux groupes
      final mockUsersSnap = await firestore.collection('users').where('isMock', isEqualTo: true).limit(20).get();
      final List<String> availableMockUids = mockUsersSnap.docs.map((d) => d.id).toList();

      for (int i = 0; i < count; i++) {
        final List<String> members = [uid];
        
        // Ajouter 3 à 8 membres aléatoires par groupe
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
      _showSnackBar('$count groupes générés avec des membres !');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllGroups() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      // Supprime TOUS les groupes
      final snapshot = await firestore.collection('groups').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _showSnackBar('${snapshot.docs.length} groupes (TOUS) ont été supprimés.');
    } catch (e) {
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => _isLoading = false);
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
              '🛠️ Panneau de Staging - Deep Mock',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Génère de vraies données (Buteurs, stats, pronostics) pour tester toutes les fonctionnalités.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ─── Mes Pronostics ───
            const Text('ÉTAPE 1 : Moi-même (Le Joueur Actuel)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _mockMyPredictions,
              icon: const Icon(Icons.edit_note),
              label: const Text('Générer MES propres pronostics'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 10),
            const Text('💡 Astuce: Pour que vous ayez des points et des badges quand les matchs se simulent, il faut d\'abord remplir vos pronostics ici !', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            const Divider(height: 30),

            // ─── Matchs ───
            const Text('ÉTAPE 2 : Simulations des Matchs (Buteurs, Stats, Prols)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _simulateMatches(allMatches: false),
              child: const Text('Simuler Seulement Poules'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _simulateMatches(allMatches: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('Simuler TOUTE la Compétition'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetMatches,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Réinitialiser les Matchs (0-0)'),
            ),
            const Divider(height: 30),

            // ─── Utilisateurs ───
            const Text('Joueurs Fictifs (Pour le Leaderboard)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Niveau d\'XP : 1=Rookie, 2=Tactician, 3=Master, 4=Special One', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _usersController, decoration: const InputDecoration(labelText: 'Nbr Joueurs', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _levelController, decoration: const InputDecoration(labelText: 'Rang XP (1-4)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
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

            // ─── Groupes ───
            const Text('Groupes Privés', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _groupsController, decoration: const InputDecoration(labelText: 'Nbr Groupes', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _generateMockGroups, child: const Text('Générer Groupes'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _deleteAllGroups, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('TOUT Purger'))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
