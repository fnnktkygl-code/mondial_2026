import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/prediction_service.dart';
import '../app_colors.dart';
import '../app_constants.dart';

// Player pools for simulation
const Map<String, List<String>> playerPools = {
  'mx': ['H. Lozano', 'R. Jiménez', 'S. Giménez', 'U. Antuna'],
  'co': ['L. Díaz', 'J. Rodríguez', 'R. Borré', 'J. Arias'],
  'cm': ['V. Aboubakar', 'K. Toko Ekambi', 'E. Choupo-Moting'],
  'kr': ['H. Son', 'G. Cho', 'H. Hwang'],
  'us': ['C. Pulisic', 'T. Weah', 'F. Balogun'],
  'en': ['H. Kane', 'B. Saka', 'P. Foden', 'J. Bellingham'],
  'ng': ['V. Osimhen', 'A. Lookman', 'M. Simon'],
  'jp': ['K. Mitoma', 'K. Furuhashi', 'T. Kubo'],
  'ca': ['J. David', 'C. Larin', 'A. Davies'],
  'fr': ['K. Mbappé', 'O. Giroud', 'O. Dembélé', 'A. Griezmann'],
  'sn': ['S. Mané', 'I. Sarr', 'B. Dia'],
  'de': ['L. Sané', 'K. Havertz', 'J. Musiala'],
  'br': ['Neymar Jr.', 'Vinícius Jr.', 'Rodrygo', 'Richarlison'],
  'ar': ['L. Messi', 'L. Martínez', 'J. Álvarez'],
  'ma': ['Y. En-Nesyri', 'H. Ziyech', 'S. Boufal'],
  'es': ['A. Morata', 'Ferran', 'Dani Olmo', 'Gavi'],
  'it': ['G. Scamacca', 'F. Chiesa', 'N. Barella'],
  'pt': ['C. Ronaldo', 'B. Fernandes', 'R. Leão'],
  'nl': ['M. Depay', 'C. Gakpo', 'X. Simons'],
  'be': ['R. Lukaku', 'K. De Bruyne', 'J. Doku'],
  'hr': ['A. Kramarić', 'L. Modrić', 'M. Kovačić'],
  'uy': ['D. Núñez', 'F. Valverde', 'L. Suárez'],
  'se': ['A. Isak', 'V. Gyökeres', 'D. Kulusevski'],
  'ch': ['B. Embolo', 'X. Shaqiri', 'Z. Amdouni'],
  'dk': ['R. Højlund', 'C. Eriksen', 'J. Wind'],
  'pl': ['R. Lewandowski', 'P. Zieliński', 'K. Świderski'],
  'ua': ['A. Dovbyk', 'M. Mudryk', 'V. Tsygankov'],
  'dz': ['R. Mahrez', 'B. Bounedjah', 'Y. Belaïli'],
  'eg': ['M. Salah', 'M. Mostafa', 'O. Marmoush'],
  'tn': ['Y. Msakni', 'N. Sliti', 'E. Skhiri'],
  'gh': ['I. Williams', 'M. Kudus', 'J. Ayew'],
  'ci': ['S. Haller', 'S. Adingra', 'F. Kessié'],
  'cl': ['A. Sánchez', 'E. Vargas', 'B. Brereton Díaz'],
  'pe': ['G. Lapadula', 'A. Carrillo', 'C. Cueva'],
  'ec': ['E. Valencia', 'J. Caicedo', 'K. Rodríguez'],
  've': ['S. Rondón', 'D. Machís', 'Y. Soteldo'],
  'au': ['M. Duke', 'C. Goodwin', 'J. Bos'],
  'nz': ['C. Wood', 'B. Waine', 'K. Barbarouses'],
  'sa': ['S. Al-Dawsari', 'S. Al-Shehri', 'F. Al-Buraikan'],
  'ir': ['M. Taremi', 'S. Azmoun', 'A. Jahanbakhsh'],
  'tr': ['C. Tosun', 'B. Yılmaz', 'H. Çalhanoğlu'],
  'gr': ['V. Pavlidis', 'G. Masouras', 'T. Bakasetas'],
  'cz': ['P. Schick', 'J. Kuchta', 'T. Souček'],
  'at': ['M. Arnautović', 'M. Sabitzer', 'C. Baumgartner'],
  'ro': ['D. Alibec', 'V. Mihăilă', 'N. Stanciu'],
  'hu': ['B. Varga', 'R. Sallai', 'D. Szoboszlai'],
  'bg': ['K. Despodov', 'G. Minchev', 'I. Gruev'],
  'rs': ['A. Mitrović', 'D. Vlahović', 'D. Tadić']
};

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
    
    // On récupère les joueurs réels depuis la liste officielle pour ces deux équipes
    final t1Players = kWC2026Players.where((p) => p.contains('($t1)')).toList();
    final t2Players = kWC2026Players.where((p) => p.contains('($t2)')).toList();

    // Fallback si l'équipe n'est pas dans la liste (ne devrait pas arriver)
    final List<String> p1 = t1Players.isNotEmpty ? t1Players : ['Joueur A ($t1)', 'Joueur B ($t1)'];
    final List<String> p2 = t2Players.isNotEmpty ? t2Players : ['Joueur C ($t2)', 'Joueur D ($t2)'];

    for (int i = 0; i < score1; i++) {
      // FORCE MBAPPÉ : Si c'est la France (fr) et que Mbappé est dans la liste, il marque 80% du temps
      String scorer;
      if (t1.toLowerCase() == 'fr') {
        scorer = rand.nextDouble() < 0.8 ? 'Kylian Mbappé' : p1[rand.nextInt(p1.length)];
      } else {
        scorer = p1[rand.nextInt(p1.length)];
      }
      
      String? assistant;
      if (rand.nextBool()) {
        final candidates = p1.where((p) => p != scorer).toList();
        if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
      }
      goalsList.add(GoalEvent(team: 't1', scorer: _shortenName(scorer), assistant: assistant != null ? _shortenName(assistant) : null, minute: rand.nextInt(90) + 1));
    }

    for (int i = 0; i < score2; i++) {
      String scorer;
      // On peut aussi forcer Messi pour l'Argentine pour varier les tests
      if (t2.toLowerCase() == 'ar') {
        scorer = rand.nextDouble() < 0.6 ? 'Lionel Messi' : p2[rand.nextInt(p2.length)];
      } else {
        scorer = p2[rand.nextInt(p2.length)];
      }

      String? assistant;
      if (rand.nextBool()) {
        final candidates = p2.where((p) => p != scorer).toList();
        if (candidates.isNotEmpty) assistant = candidates[rand.nextInt(candidates.length)];
      }
      goalsList.add(GoalEvent(team: 't2', scorer: _shortenName(scorer), assistant: assistant != null ? _shortenName(assistant) : null, minute: rand.nextInt(90) + 1));
    }

    goalsList.sort((a, b) => a.minute.compareTo(b.minute));
    return goalsList;
  }

  /// Transforme "Kylian Mbappé" en "K. Mbappé" (style API)
  String _shortenName(String full) {
    final parts = full.split(' ');
    if (parts.length < 2) return full;
    final firstName = parts.first;
    final lastName = parts.sublist(1).join(' ');
    // On enlève le tag (team) si présent
    final cleanLastName = lastName.split('(').first.trim();
    return '${firstName[0]}. $cleanLastName';
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
      _showSnackBar('Matchs et Stats simulés !');
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

      preds.championCode = 'fr';
      preds.championPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      preds.goldenBootWinner = 'fr'; // France
      preds.goldenBootPlayer = 'Kylian Mbappé'; // Nom COMPLET (FIFA style)
      preds.goldenBootPredictedAt = DateTime.now().subtract(const Duration(days: 30));

      preds.topAssisterWinner = 'ar'; // Argentine
      preds.topAssisterPlayer = 'Lionel Messi'; // Nom COMPLET
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
