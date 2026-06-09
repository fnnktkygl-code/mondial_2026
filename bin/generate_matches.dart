import 'dart:convert';
import 'dart:io';
import 'dart:math';

// 48 teams mapped to their group
const Map<String, List<String>> groupsMap = {
  'A': ['mx', 'co', 'cm', 'kr'],
  'B': ['us', 'en', 'ng', 'jp'],
  'C': ['ca', 'fr', 'sn', 'de'],
  'D': ['br', 'ar', 'ma', 'es'],
  'E': ['it', 'pt', 'nl', 'be'],
  'F': ['hr', 'uy', 'se', 'ch'],
  'G': ['dk', 'pl', 'ua', 'dz'],
  'H': ['eg', 'tn', 'gh', 'ci'],
  'I': ['cl', 'pe', 'ec', 've'],
  'J': ['au', 'nz', 'sa', 'ir'],
  'K': ['tr', 'gr', 'cz', 'at'],
  'L': ['ro', 'hu', 'bg', 'rs']
};

// Player pools for simulation
const Map<String, List<String>> playerPools = {
  'mx': ['H. Lozano', 'R. Jiménez', 'S. Giménez', 'U. Antuna', 'E. Álvarez'],
  'co': ['L. Díaz', 'J. Rodríguez', 'R. Borré', 'J. Arias', 'M. Uribe'],
  'cm': ['V. Aboubakar', 'K. Toko Ekambi', 'E. Choupo-Moting', 'B. Mbeumo'],
  'kr': ['H. Son', 'G. Cho', 'H. Hwang', 'J. Lee', 'I. Hwang'],
  'us': ['C. Pulisic', 'T. Weah', 'F. Balogun', 'G. Reyna', 'W. McKennie'],
  'en': ['H. Kane', 'B. Saka', 'P. Foden', 'J. Bellingham', 'M. Rashford'],
  'ng': ['V. Osimhen', 'A. Lookman', 'M. Simon', 'K. Iheanacho', 'A. Iwobi'],
  'jp': ['K. Mitoma', 'K. Furuhashi', 'T. Kubo', 'J. Ito', 'W. Endo'],
  'ca': ['J. David', 'C. Larin', 'T. Buchanan', 'A. Davies', 'S. Eustáquio'],
  'fr': ['K. Mbappé', 'O. Giroud', 'O. Dembélé', 'A. Griezmann', 'K. Coman'],
  'sn': ['S. Mané', 'I. Sarr', 'B. Dia', 'N. Jackson', 'I. Gueye'],
  'de': ['L. Sané', 'S. Gnabry', 'K. Havertz', 'T. Müller', 'J. Musiala'],
  'br': ['Neymar Jr.', 'Vinícius Jr.', 'Rodrygo', 'Richarlison', 'Raphinha'],
  'ar': ['L. Messi', 'L. Martínez', 'J. Álvarez', 'A. Di María', 'E. Fernández'],
  'ma': ['Y. En-Nesyri', 'H. Ziyech', 'S. Boufal', 'A. Ounahi', 'A. Harit'],
  'es': ['A. Morata', 'Ferran', 'Dani Olmo', 'Gavi', 'Pedri'],
  'it': ['G. Scamacca', 'F. Chiesa', 'D. Berardi', 'N. Barella', 'L. Pellegrini'],
  'pt': ['C. Ronaldo', 'B. Fernandes', 'R. Leão', 'J. Félix', 'G. Ramos'],
  'nl': ['M. Depay', 'C. Gakpo', 'W. Weghorst', 'X. Simons', 'D. Dumfries'],
  'be': ['R. Lukaku', 'L. Trossard', 'J. Doku', 'K. De Bruyne', 'Y. Tielemans'],
  'hr': ['A. Kramarić', 'I. Perišić', 'M. Pašalić', 'L. Modrić', 'M. Kovačić'],
  'uy': ['D. Núñez', 'L. Suárez', 'F. Pellistri', 'F. Valverde', 'N. de la Cruz'],
  'se': ['A. Isak', 'V. Gyökeres', 'D. Kulusevski', 'E. Forsberg'],
  'ch': ['B. Embolo', 'X. Shaqiri', 'Z. Amdouni', 'G. Xhaka'],
  'dk': ['R. Højlund', 'J. Wind', 'C. Eriksen', 'P. Højbjerg'],
  'pl': ['R. Lewandowski', 'K. Świderski', 'P. Zieliński', 'S. Szymański'],
  'ua': ['A. Dovbyk', 'M. Mudryk', 'V. Tsygankov', 'O. Zinchenko'],
  'dz': ['R. Mahrez', 'B. Bounedjah', 'Y. Belaïli', 'S. Feghouli'],
  'eg': ['M. Salah', 'M. Mostafa', 'O. Marmoush', 'M. Elneny'],
  'tn': ['Y. Msakni', 'N. Sliti', 'E. Skhiri', 'A. Laidouni'],
  'gh': ['I. Williams', 'M. Kudus', 'J. Ayew', 'T. Partey'],
  'ci': ['S. Haller', 'S. Adingra', 'F. Kessié', 'I. Sangaré'],
  'cl': ['A. Sánchez', 'E. Vargas', 'D. Valdés', 'A. Vidal'],
  'pe': ['G. Lapadula', 'A. Carrillo', 'C. Cueva', 'R. Tapia'],
  'ec': ['E. Valencia', 'J. Caicedo', 'K. Rodríguez', 'M. Caicedo'],
  've': ['S. Rondón', 'D. Machís', 'Y. Soteldo', 'T. Rincón'],
  'au': ['M. Duke', 'C. Goodwin', 'J. Bos', 'M. Luongo'],
  'nz': ['C. Wood', 'B. Waine', 'K. Barbarouses', 'M. Garbett'],
  'sa': ['S. Al-Dawsari', 'S. Al-Shehri', 'F. Al-Buraikan', 'M. Kanno'],
  'ir': ['M. Taremi', 'S. Azmoun', 'A. Jahanbakhsh', 'S. Ghoddos'],
  'tr': ['C. Tosun', 'B. Yılmaz', 'H. Çalhanoğlu', 'A. Güler'],
  'gr': ['V. Pavlidis', 'G. Masouras', 'T. Bakasetas', 'P. Mantalos'],
  'cz': ['P. Schick', 'J. Kuchta', 'T. Souček', 'A. Barák'],
  'at': ['M. Arnautović', 'M. Sabitzer', 'C. Baumgartner', 'K. Laimer'],
  'ro': ['D. Alibec', 'V. Mihăilă', 'N. Stanciu', 'R. Marin'],
  'hu': ['B. Varga', 'R. Sallai', 'D. Szoboszlai', 'A. Nagy'],
  'bg': ['K. Despodov', 'G. Minchev', 'I. Gruev', 'F. Krastev'],
  'rs': ['A. Mitrović', 'D. Vlahović', 'D. Tadić', 'S. Milinković-Savić']
};

// Tournament Venues
const List<String> venues = [
  'Estadio Azteca, Mexico City',
  'SoFi Stadium, Los Angeles',
  'MetLife Stadium, New York/New Jersey',
  'BMO Field, Toronto',
  'AT&T Stadium, Dallas',
  'Hard Rock Stadium, Miami',
  'Mercedes-Benz Stadium, Atlanta',
  'Gillette Stadium, Boston',
  'NRG Stadium, Houston',
  'Arrowhead Stadium, Kansas City',
  'Lincoln Financial Field, Philadelphia',
  'Levi\'s Stadium, San Francisco',
  'Lumen Field, Seattle',
  'BC Place, Vancouver',
  'Estadio BBVA, Monterrey',
  'Estadio Akron, Guadalajara'
];

final Random rand = Random(42); // Seeded for reproducibility

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

void main() {
  final List<Map<String, dynamic>> allMatchesJson = [];
  int matchIdCounter = 1;

  // 1. Generate 72 Group Matches
  final Map<String, List<SimTeamEntry>> groupStandings = {};
  final DateTime startDate = DateTime.parse('2026-06-11T16:00:00Z');

  groupsMap.forEach((group, teams) {
    groupStandings[group] = teams.map((t) => SimTeamEntry(t)).toList();

    // Round Robin schedule (6 matches per group)
    final List<List<int>> pairings = [
      [0, 1], [2, 3], // Round 1
      [0, 2], [1, 3], // Round 2
      [0, 3], [1, 2]  // Round 3
    ];

    for (int r = 0; r < pairings.length; r++) {
      final p = pairings[r];
      final t1 = teams[p[0]];
      final t2 = teams[p[1]];

      // Stagger dates slightly
      final dateOffset = (matchIdCounter - 1) * 4; // every 4 hours
      final date = startDate.add(Duration(hours: dateOffset));
      final venue = venues[matchIdCounter % venues.length];

      // Simulate match played (group stage has results)
      final score1 = rand.nextInt(3); // 0 to 2
      final score2 = rand.nextInt(3); // 0 to 2

      final goals = _simulateGoals(t1, t2, score1, score2);
      final stats = _simulateStats(score1, score2);

      // Save match
      allMatchesJson.add({
        'id': 'm$matchIdCounter',
        'date': date.toUtc().toIso8601String(),
        't1': t1,
        't2': t2,
        't1Score': score1,
        't2Score': score2,
        'venue': venue,
        'group': group,
        'stage': null,
        'goals': goals,
        'stats': stats
      });

      // Update standings
      final entry1 = groupStandings[group]!.firstWhere((e) => e.code == t1);
      final entry2 = groupStandings[group]!.firstWhere((e) => e.code == t2);

      entry1.played++;
      entry2.played++;
      entry1.goalsFor += score1;
      entry1.goalsAgainst += score2;
      entry2.goalsFor += score2;
      entry2.goalsAgainst += score1;

      if (score1 > score2) {
        entry1.wins++;
        entry2.losses++;
      } else if (score1 < score2) {
        entry2.wins++;
        entry1.losses++;
      } else {
        entry1.draws++;
        entry2.draws++;
      }

      matchIdCounter++;
    }
  });

  // Sort groups
  groupStandings.forEach((g, list) {
    list.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
      return a.code.compareTo(b.code);
    });
  });

  // Ranks 3rd place teams
  final List<SimTeamEntry> thirdPlaces = [];
  groupStandings.forEach((g, list) {
    if (list.length >= 3) {
      thirdPlaces.add(list[2]);
    }
  });
  thirdPlaces.sort((a, b) {
    if (b.points != a.points) return b.points.compareTo(a.points);
    if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
    return b.goalsFor.compareTo(a.goalsFor);
  });

  // 2. Generate 32-team Knockout Matches (32 matches total)
  // Let's create the 16 matches of the Round of 32 (m49 to m64)
  final DateTime knockoutStartDate = DateTime.parse('2026-06-28T16:00:00Z');

  // Make sure pairing placeholders are unique and cover all 32 spots!
  final List<Map<String, String>> finalR32Pairings = [
    // LEFT HALF
    {'id': 'm49', 't1': '1A', 't2': '3rd1'},
    {'id': 'm50', 't1': '2B', 't2': '2C'},
    {'id': 'm51', 't1': '1C', 't2': '3rd2'},
    {'id': 'm52', 't1': '2A', 't2': '2D'},
    {'id': 'm53', 't1': '1E', 't2': '3rd3'},
    {'id': 'm54', 't1': '2F', 't2': '2G'},
    {'id': 'm55', 't1': '1G', 't2': '3rd4'},
    {'id': 'm56', 't1': '2H', 't2': '2I'},

    // RIGHT HALF
    {'id': 'm57', 't1': '1B', 't2': '3rd5'},
    {'id': 'm58', 't1': '2E', 't2': '2J'},
    {'id': 'm59', 't1': '1D', 't2': '3rd6'},
    {'id': 'm60', 't1': '2K', 't2': '2L'},
    {'id': 'm61', 't1': '1F', 't2': '3rd7'},
    {'id': 'm62', 't1': '1H', 't2': '3rd8'},
    {'id': 'm63', 't1': '1I', 't2': '1J'},
    {'id': 'm64', 't1': '1K', 't2': '1L'}
  ];

  // Helper map of winners
  final Map<String, String> simWinners = {};

  // Resolve placeholders for R32
  for (final pair in finalR32Pairings) {
    final String matchId = pair['id']!;
    String p1 = pair['t1']!;
    String p2 = pair['t2']!;

    // Resolve p1
    if (p1.length == 2) {
      final idx = int.parse(p1[0]) - 1;
      p1 = groupStandings[p1[1]]![idx].code;
    } else if (p1.startsWith('3rd')) {
      final idx = int.parse(p1.substring(3)) - 1;
      p1 = thirdPlaces[idx].code;
    }

    // Resolve p2
    if (p2.length == 2) {
      final idx = int.parse(p2[0]) - 1;
      p2 = groupStandings[p2[1]]![idx].code;
    } else if (p2.startsWith('3rd')) {
      final idx = int.parse(p2.substring(3)) - 1;
      p2 = thirdPlaces[idx].code;
    }

    final dateOffset = matchIdCounter * 6; // every 6 hours
    final date = knockoutStartDate.add(Duration(hours: dateOffset));
    final venue = venues[matchIdCounter % venues.length];

    // Knockout match simulation (cannot end in a draw, so if draw, we add 1 goal to a team)
    int score1 = rand.nextInt(4);
    int score2 = rand.nextInt(4);
    if (score1 == score2) {
      if (rand.nextBool()) {
        score1++;
      } else {
        score2++;
      }
    }

    final goals = _simulateGoals(p1, p2, score1, score2);
    final stats = _simulateStats(score1, score2);

    simWinners[matchId] = score1 > score2 ? p1 : p2;

    allMatchesJson.add({
      'id': matchId,
      'date': date.toUtc().toIso8601String(),
      't1': p1,
      't2': p2,
      't1Score': score1,
      't2Score': score2,
      'venue': venue,
      'group': null,
      'stage': 'Round of 32',
      'goals': goals,
      'stats': stats
    });

    matchIdCounter++;
  }

  // 3. Generate Round of 16 (8 matches: m65 to m72)
  // Left side: m65 to m68
  // Right side: m69 to m72
  final List<Map<String, String>> r16Pairings = [
    // LEFT SIDE
    {'id': 'm65', 't1': 'w49', 't2': 'w50'},
    {'id': 'm66', 't1': 'w51', 't2': 'w52'},
    {'id': 'm67', 't1': 'w53', 't2': 'w54'},
    {'id': 'm68', 't1': 'w55', 't2': 'w56'},
    // RIGHT SIDE
    {'id': 'm69', 't1': 'w57', 't2': 'w58'},
    {'id': 'm70', 't1': 'w59', 't2': 'w60'},
    {'id': 'm71', 't1': 'w61', 't2': 'w62'},
    {'id': 'm72', 't1': 'w63', 't2': 'w64'}
  ];

  for (final pair in r16Pairings) {
    final String matchId = pair['id']!;
    final String p1Ref = pair['t1']!;
    final String p2Ref = pair['t2']!;

    final p1 = simWinners['m${p1Ref.substring(1)}']!;
    final p2 = simWinners['m${p2Ref.substring(1)}']!;

    final dateOffset = matchIdCounter * 6;
    final date = knockoutStartDate.add(Duration(hours: dateOffset));
    final venue = venues[matchIdCounter % venues.length];

    int score1 = rand.nextInt(4);
    int score2 = rand.nextInt(4);
    if (score1 == score2) {
      if (rand.nextBool()) {
        score1++;
      } else {
        score2++;
      }
    }

    final goals = _simulateGoals(p1, p2, score1, score2);
    final stats = _simulateStats(score1, score2);

    simWinners[matchId] = score1 > score2 ? p1 : p2;

    allMatchesJson.add({
      'id': matchId,
      'date': date.toUtc().toIso8601String(),
      't1': p1,
      't2': p2,
      't1Score': score1,
      't2Score': score2,
      'venue': venue,
      'group': null,
      'stage': 'Round of 16',
      'goals': goals,
      'stats': stats
    });

    matchIdCounter++;
  }

  // 4. Generate Quarter-Finals (4 matches: m73 to m76)
  // Left side: m73, m74
  // Right side: m75, m76
  final List<Map<String, String>> qfPairings = [
    {'id': 'm73', 't1': 'w65', 't2': 'w66'},
    {'id': 'm74', 't1': 'w67', 't2': 'w68'},
    {'id': 'm75', 't1': 'w69', 't2': 'w70'},
    {'id': 'm76', 't1': 'w71', 't2': 'w72'}
  ];

  for (final pair in qfPairings) {
    final String matchId = pair['id']!;
    final String p1 = simWinners['m${pair['t1']!.substring(1)}']!;
    final String p2 = simWinners['m${pair['t2']!.substring(1)}']!;

    final dateOffset = matchIdCounter * 8;
    final date = knockoutStartDate.add(Duration(hours: dateOffset));
    final venue = venues[matchIdCounter % venues.length];

    int score1 = rand.nextInt(4);
    int score2 = rand.nextInt(4);
    if (score1 == score2) {
      if (rand.nextBool()) {
        score1++;
      } else {
        score2++;
      }
    }

    final goals = _simulateGoals(p1, p2, score1, score2);
    final stats = _simulateStats(score1, score2);

    simWinners[matchId] = score1 > score2 ? p1 : p2;

    allMatchesJson.add({
      'id': matchId,
      'date': date.toUtc().toIso8601String(),
      't1': p1,
      't2': p2,
      't1Score': score1,
      't2Score': score2,
      'venue': venue,
      'group': null,
      'stage': 'Quarter-Final',
      'goals': goals,
      'stats': stats
    });

    matchIdCounter++;
  }

  // 5. Generate Semi-Finals (2 matches: m77 left, m78 right)
  final List<Map<String, String>> sfPairings = [
    {'id': 'm77', 't1': 'w73', 't2': 'w74'},
    {'id': 'm78', 't1': 'w75', 't2': 'w76'}
  ];

  for (final pair in sfPairings) {
    final String matchId = pair['id']!;
    final String p1 = simWinners['m${pair['t1']!.substring(1)}']!;
    final String p2 = simWinners['m${pair['t2']!.substring(1)}']!;

    final dateOffset = matchIdCounter * 12;
    final date = knockoutStartDate.add(Duration(hours: dateOffset));
    final venue = venues[matchIdCounter % venues.length];

    int score1 = rand.nextInt(4);
    int score2 = rand.nextInt(4);
    if (score1 == score2) {
      if (rand.nextBool()) {
        score1++;
      } else {
        score2++;
      }
    }

    final goals = _simulateGoals(p1, p2, score1, score2);
    final stats = _simulateStats(score1, score2);

    simWinners[matchId] = score1 > score2 ? p1 : p2;

    allMatchesJson.add({
      'id': matchId,
      'date': date.toUtc().toIso8601String(),
      't1': p1,
      't2': p2,
      't1Score': score1,
      't2Score': score2,
      'venue': venue,
      'group': null,
      'stage': 'Semi-Final',
      'goals': goals,
      'stats': stats
    });

    matchIdCounter++;
  }

  // 6. Generate Play-off for third place (m79)
  final String sf1T1 = allMatchesJson.firstWhere((m) => m['id'] == 'm77')['t1'] as String;
  final String sf1T2 = allMatchesJson.firstWhere((m) => m['id'] == 'm77')['t2'] as String;
  final String sf1Winner = simWinners['m77']!;
  final String sf1Loser = sf1Winner == sf1T1 ? sf1T2 : sf1T1;

  final String sf2T1 = allMatchesJson.firstWhere((m) => m['id'] == 'm78')['t1'] as String;
  final String sf2T2 = allMatchesJson.firstWhere((m) => m['id'] == 'm78')['t2'] as String;
  final String sf2Winner = simWinners['m78']!;
  final String sf2Loser = sf2Winner == sf2T1 ? sf2T2 : sf2T1;

  final date = knockoutStartDate.add(const Duration(days: 20));
  final thirdPlaceDate = date.subtract(const Duration(days: 1));
  final thirdPlaceVenue = venues[4]; // AT&T Stadium

  int tpScore1 = rand.nextInt(4);
  int tpScore2 = rand.nextInt(4);
  if (tpScore1 == tpScore2) {
    if (rand.nextBool()) {
      tpScore1++;
    } else {
      tpScore2++;
    }
  }
  final tpGoals = _simulateGoals(sf1Loser, sf2Loser, tpScore1, tpScore2);
  final tpStats = _simulateStats(tpScore1, tpScore2);

  allMatchesJson.add({
    'id': 'm79',
    'date': thirdPlaceDate.toUtc().toIso8601String(),
    't1': sf1Loser,
    't2': sf2Loser,
    't1Score': tpScore1,
    't2Score': tpScore2,
    'venue': thirdPlaceVenue,
    'group': null,
    'stage': 'Play-off for third place',
    'goals': tpGoals,
    'stats': tpStats
  });

  // 7. Generate Final (m80)
  final String finalP1 = simWinners['m77']!;
  final String finalP2 = simWinners['m78']!;
  final finalVenue = venues[2]; // MetLife Stadium

  int score1 = rand.nextInt(4);
  int score2 = rand.nextInt(4);
  if (score1 == score2) {
    if (rand.nextBool()) {
      score1++;
    } else {
      score2++;
    }
  }

  final goals = _simulateGoals(finalP1, finalP2, score1, score2);
  final stats = _simulateStats(score1, score2);

  allMatchesJson.add({
    'id': 'm80',
    'date': date.toUtc().toIso8601String(),
    't1': finalP1,
    't2': finalP2,
    't1Score': score1,
    't2Score': score2,
    'venue': finalVenue,
    'group': null,
    'stage': 'Final',
    'goals': goals,
    'stats': stats
  });

  // Write all matches to assets/initial_matches.json
  final file = File('assets/initial_matches.json');
  file.writeAsStringSync(jsonEncode(allMatchesJson));

  print('Successfully simulated all 104 matches of Mondial 2026!');
  print('Total generated matches in file: ${allMatchesJson.length}');
}

List<Map<String, dynamic>> _simulateGoals(String t1, String t2, int score1, int score2) {
  final List<Map<String, dynamic>> goalsList = [];

  final t1Players = playerPools[t1] ?? ['Player A', 'Player B'];
  final t2Players = playerPools[t2] ?? ['Player C', 'Player D'];

  // Add goals for Team 1
  for (int i = 0; i < score1; i++) {
    final scorer = t1Players[rand.nextInt(t1Players.length)];
    String? assistant;
    if (rand.nextBool()) {
      final candidates = t1Players.where((p) => p != scorer).toList();
      if (candidates.isNotEmpty) {
        assistant = candidates[rand.nextInt(candidates.length)];
      }
    }
    goalsList.add({
      'team': 't1',
      'scorer': scorer,
      'assistant': assistant,
      'minute': rand.nextInt(90) + 1
    });
  }

  // Add goals for Team 2
  for (int i = 0; i < score2; i++) {
    final scorer = t2Players[rand.nextInt(t2Players.length)];
    String? assistant;
    if (rand.nextBool()) {
      final candidates = t2Players.where((p) => p != scorer).toList();
      if (candidates.isNotEmpty) {
        assistant = candidates[rand.nextInt(candidates.length)];
      }
    }
    goalsList.add({
      'team': 't2',
      'scorer': scorer,
      'assistant': assistant,
      'minute': rand.nextInt(90) + 1
    });
  }

  // Sort goals by minute
  goalsList.sort((a, b) => (a['minute'] as int).compareTo(b['minute'] as int));
  return goalsList;
}

Map<String, int> _simulateStats(int score1, int score2) {
  final possessionT1 = 35 + rand.nextInt(31); // 35% to 65%
  final shotsT1 = score1 + rand.nextInt(12);
  final shotsT2 = score2 + rand.nextInt(12);
  final shotsOnTargetT1 = score1 + rand.nextInt(shotsT1 - score1 + 1);
  final shotsOnTargetT2 = score2 + rand.nextInt(shotsT2 - score2 + 1);

  return {
    'possessionT1': possessionT1,
    'shotsT1': shotsT1,
    'shotsT2': shotsT2,
    'shotsOnTargetT1': shotsOnTargetT1,
    'shotsOnTargetT2': shotsOnTargetT2,
    'foulsT1': 6 + rand.nextInt(14),
    'foulsT2': 6 + rand.nextInt(14),
    'yellowCardsT1': rand.nextInt(4),
    'yellowCardsT2': rand.nextInt(4),
    'redCardsT1': rand.nextInt(10) == 0 ? 1 : 0,
    'redCardsT2': rand.nextInt(10) == 0 ? 1 : 0
  };
}
