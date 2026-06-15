import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';

class EspnApiService {
  static const String _baseUrl = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard';

  /// Reverse mapping from ESPN abbreviations to internal project codes.
  static const Map<String, String> _espnToInternal = {
    'MEX': 'mx', 'GER': 'de', 'USA': 'us', 'ENG': 'en', 'CAN': 'ca',
    'JPN': 'jp', 'FRA': 'fr', 'BRA': 'br', 'SEN': 'sn', 'ARG': 'ar',
    'MAR': 'ma', 'ESP': 'es', 'ITA': 'it', 'POR': 'pt', 'NED': 'nl',
    'BEL': 'be', 'CRO': 'hr', 'URU': 'uy', 'COL': 'co', 'KOR': 'kr',
    'CMR': 'cm', 'NGA': 'ng', 'SWE': 'se', 'SUI': 'ch', 'DEN': 'dk',
    'POL': 'pl', 'UKR': 'ua', 'ALG': 'dz', 'EGY': 'eg', 'TUN': 'tn',
    'GHA': 'gh', 'CIV': 'ci', 'CHI': 'cl', 'PER': 'pe', 'ECU': 'ec',
    'VEN': 've', 'AUS': 'au', 'NZL': 'nz', 'KSA': 'sa', 'IRN': 'ir',
    'TUR': 'tr', 'GRE': 'gr', 'CZE': 'cz', 'AUT': 'at', 'ROU': 'ro',
    'HUN': 'hu', 'BUL': 'bg', 'SRB': 'rs', 'RSA': 'za', 'BIH': 'ba',
    'COD': 'cd', 'CUW': 'cw', 'CPV': 'cv', 'SCO': 'sco', 'HAI': 'ht',
    'IRQ': 'iq', 'JOR': 'jo', 'NOR': 'no', 'PAN': 'pa', 'PAR': 'py',
    'QAT': 'qa', 'UZB': 'uz', 'WAL': 'wa', 'MLI': 'ml', 'BUR': 'bf',
    'JAM': 'jm', 'CRC': 'cr', 'HON': 'hn', 'SLV': 'sv', 'CUB': 'cu',
  };

  /// Fetch live matches from ESPN and map them to WorldCupMatch models.
  /// Default dates cover the entire 2026 World Cup.
  static Future<List<WorldCupMatch>> fetchLiveMatches({String dates = '20260611-20260719'}) async {
    try {
      final url = '$_baseUrl?dates=$dates';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data['events'] as List<dynamic>? ?? [];
        return events.map((e) => _mapEspnEventToMatch(e)).toList();
      }
    } catch (_) {
      // Quiet fail in production
    }
    return [];
  }

  static WorldCupMatch _mapEspnEventToMatch(Map<String, dynamic> event) {
    final competition = event['competitions'][0];
    final competitors = competition['competitors'] as List<dynamic>;
    
    final homeCompetitor = competitors.firstWhere((c) => c['homeAway'] == 'home', orElse: () => competitors[0]);
    final awayCompetitor = competitors.firstWhere((c) => c['homeAway'] == 'away', orElse: () => competitors[1]);

    final t1Code = _espnToInternal[homeCompetitor['team']['abbreviation']] ?? homeCompetitor['team']['abbreviation'].toLowerCase();
    final t2Code = _espnToInternal[awayCompetitor['team']['abbreviation']] ?? awayCompetitor['team']['abbreviation'].toLowerCase();

    final status = _mapEspnStatus(event['status']['type']['name']);
    final liveMinute = event['status']['displayValue']?.toString();
    
    final List<GoalEvent> goals = [];
    int yellowCardsT1 = 0;
    int yellowCardsT2 = 0;
    int redCardsT1 = 0;
    int redCardsT2 = 0;

    final details = competition['details'] as List<dynamic>? ?? [];
    for (var detail in details) {
      final type = detail['type']?['text'];
      final teamId = detail['team']?['id']?.toString();
      if (teamId == null) { continue; }
      final isHome = teamId == homeCompetitor['id'].toString();

      if (type == 'Goal') {
        final teamKey = isHome ? 't1' : 't2';
        final athletes = detail['athletesInvolved'] as List<dynamic>? ?? [];
        final scorer = athletes.isNotEmpty ? athletes[0]['shortName'] : 'Unknown';
        final minute = int.tryParse(detail['clock']['displayValue'].replaceAll("'", "")) ?? 0;
        
        goals.add(GoalEvent(
          team: teamKey,
          scorer: scorer ?? 'Unknown',
          minute: minute,
          isOwnGoal: detail['ownGoal'] == true,
        ));
      } else if (type == 'Yellow Card') {
        if (isHome) { yellowCardsT1++; } else { yellowCardsT2++; }
      } else if (type == 'Red Card') {
        if (isHome) { redCardsT1++; } else { redCardsT2++; }
      }
    }

    final homeStats = homeCompetitor['statistics'] as List<dynamic>? ?? [];
    final awayStats = awayCompetitor['statistics'] as List<dynamic>? ?? [];
    
    final stats = MatchStats(
      possessionT1: _getStatValue(homeStats, 'possessionPct'),
      shotsT1: _getStatValue(homeStats, 'totalShots'),
      shotsT2: _getStatValue(awayStats, 'totalShots'),
      shotsOnTargetT1: _getStatValue(homeStats, 'shotsOnTarget'),
      shotsOnTargetT2: _getStatValue(awayStats, 'shotsOnTarget'),
      foulsT1: _getStatValue(homeStats, 'foulsCommitted'),
      foulsT2: _getStatValue(awayStats, 'foulsCommitted'),
      yellowCardsT1: yellowCardsT1 > 0 ? yellowCardsT1 : _getStatValue(homeStats, 'yellowCards'),
      yellowCardsT2: yellowCardsT2 > 0 ? yellowCardsT2 : _getStatValue(awayStats, 'yellowCards'),
      redCardsT1: redCardsT1 > 0 ? redCardsT1 : _getStatValue(homeStats, 'redCards'),
      redCardsT2: redCardsT2 > 0 ? redCardsT2 : _getStatValue(awayStats, 'redCards'),
    );

    return WorldCupMatch(
      id: 'espn_${event['id']}',
      date: DateTime.parse(event['date']).toLocal(),
      t1: t1Code,
      t2: t2Code,
      t1Score: int.tryParse(homeCompetitor['score'] ?? ''),
      t2Score: int.tryParse(awayCompetitor['score'] ?? ''),
      status: status,
      liveMinute: liveMinute,
      venue: event['venue']?['displayName'],
      goals: goals,
      stats: stats,
      lastUpdated: DateTime.now(),
    );
  }

  static String _mapEspnStatus(String espnStatus) {
    switch (espnStatus) {
      case 'STATUS_SCHEDULED':
        return 'SCHEDULED';
      case 'STATUS_FIRST_HALF':
      case 'STATUS_HALFTIME':
      case 'STATUS_SECOND_HALF':
        return 'IN_PLAY';
      case 'STATUS_FULL_TIME':
      case 'STATUS_FINAL':
        return 'FINISHED';
      case 'STATUS_POSTPONED':
        return 'POSTPONED';
      default:
        if (espnStatus.contains('HALF') || espnStatus.contains('IN')) { return 'IN_PLAY'; }
        return 'TIMED';
    }
  }

  static Future<WorldCupMatch?> fetchMatchSummary(String espnEventId) async {
    try {
      final url = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/summary?event=$espnEventId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['header'] == null) { return null; }
        
        final competition = data['header']['competitions'][0];
        final competitors = competition['competitors'] as List<dynamic>;
        
        final homeCompetitor = competitors.firstWhere((c) => c['homeAway'] == 'home', orElse: () => competitors[0]);
        final awayCompetitor = competitors.firstWhere((c) => c['homeAway'] == 'away', orElse: () => competitors[1]);

        final t1Code = _espnToInternal[homeCompetitor['team']['abbreviation']] ?? homeCompetitor['team']['abbreviation'].toLowerCase();
        final t2Code = _espnToInternal[awayCompetitor['team']['abbreviation']] ?? awayCompetitor['team']['abbreviation'].toLowerCase();

        final status = _mapEspnStatus(competition['status']['type']['name']);
        final liveMinute = competition['status']['displayValue']?.toString();

        // Goals and Cards from keyEvents (more reliable than header details)
        final List<GoalEvent> goals = [];
        int yellowCardsT1 = 0;
        int yellowCardsT2 = 0;
        int redCardsT1 = 0;
        int redCardsT2 = 0;

        final keyEvents = data['keyEvents'] as List<dynamic>? ?? [];
        for (var event in keyEvents) {
          final type = event['type']?['text'];
          final teamId = event['team']?['id']?.toString();
          if (teamId == null) { continue; }
          final isHome = teamId == homeCompetitor['id'].toString();

          if (type == 'Goal' || event['scoringPlay'] == true) {
            final teamKey = isHome ? 't1' : 't2';
            final participants = event['participants'] as List<dynamic>? ?? [];
            String scorer = 'Unknown';
            if (participants.isNotEmpty) {
              scorer = participants[0]['athlete']?['shortName'] ?? participants[0]['athlete']?['displayName'] ?? 'Unknown';
            }
            final minute = _parseMinute(event['clock']?['displayValue'] ?? '0');
            
            goals.add(GoalEvent(
              team: teamKey,
              scorer: scorer,
              minute: minute,
              isOwnGoal: event['ownGoal'] == true,
            ));
          } else if (type == 'Yellow Card') {
            if (isHome) { yellowCardsT1++; } else { yellowCardsT2++; }
          } else if (type == 'Red Card') {
            if (isHome) { redCardsT1++; } else { redCardsT2++; }
          }
        }

        MatchStats? stats;
        final boxscore = data['boxscore'];
        if (boxscore != null && boxscore['teams'] != null) {
          final teamsStats = boxscore['teams'] as List<dynamic>;
          try {
            final homeBox = teamsStats.firstWhere((t) => t['team']['id'].toString() == homeCompetitor['id'].toString());
            final awayBox = teamsStats.firstWhere((t) => t['team']['id'].toString() == awayCompetitor['id'].toString());
            
            stats = MatchStats(
              possessionT1: _getBoxscoreStat(homeBox, 'possessionPct'),
              shotsT1: _getBoxscoreStat(homeBox, 'totalShots'),
              shotsT2: _getBoxscoreStat(awayBox, 'totalShots'),
              shotsOnTargetT1: _getBoxscoreStat(homeBox, 'shotsOnTarget'),
              shotsOnTargetT2: _getBoxscoreStat(awayBox, 'shotsOnTarget'),
              foulsT1: _getBoxscoreStat(homeBox, 'foulsCommitted'),
              foulsT2: _getBoxscoreStat(awayBox, 'foulsCommitted'),
              yellowCardsT1: yellowCardsT1 > 0 ? yellowCardsT1 : _getBoxscoreStat(homeBox, 'yellowCards'),
              yellowCardsT2: yellowCardsT2 > 0 ? yellowCardsT2 : _getBoxscoreStat(awayBox, 'yellowCards'),
              redCardsT1: redCardsT1 > 0 ? redCardsT1 : _getBoxscoreStat(homeBox, 'redCards'),
              redCardsT2: redCardsT2 > 0 ? redCardsT2 : _getBoxscoreStat(awayBox, 'redCards'),
            );
          } catch (_) {
            // Silently skip if stats parsing fails
          }
        }

        return WorldCupMatch(
          id: 'espn_$espnEventId',
          date: DateTime.parse(competition['date']).toLocal(),
          t1: t1Code,
          t2: t2Code,
          t1Score: int.tryParse(homeCompetitor['score'] ?? ''),
          t2Score: int.tryParse(awayCompetitor['score'] ?? ''),
          status: status,
          liveMinute: liveMinute,
          venue: data['gameInfo']?['venue']?['displayName'],
          goals: goals,
          stats: stats,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (_) {
      // Quiet fail in production
    }
    return null;
  }

  static int _parseMinute(String displayValue) {
    final clean = displayValue.replaceAll("'", "").trim();
    if (clean.contains('+')) {
      final parts = clean.split('+');
      return (int.tryParse(parts[0]) ?? 0) + (int.tryParse(parts[1]) ?? 0);
    }
    return int.tryParse(clean) ?? 0;
  }

  static int _getStatValue(List<dynamic> stats, String name) {
    try {
      final stat = stats.firstWhere((s) => s['name'] == name);
      return double.parse(stat['displayValue'].toString()).toInt();
    } catch (_) {
      return 0;
    }
  }

  static int _getBoxscoreStat(Map<String, dynamic> teamBox, String name) {
    try {
      final stats = teamBox['statistics'] as List<dynamic>;
      final stat = stats.firstWhere((s) => s['name'] == name);
      return double.parse(stat['displayValue'].toString()).toInt();
    } catch (_) {
      return 0;
    }
  }
}
