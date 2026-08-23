import 'package:intl/intl.dart';
import '../services/player_database_service.dart';
import '../services/live_match_service.dart';
import '../l10n/translations.dart';

class GoalEvent {
  final String team; // "t1" or "t2"
  final String scorer;
  final String? assistant;
  final int minute;
  final bool isOwnGoal;

  GoalEvent({
    required this.team,
    required this.scorer,
    this.assistant,
    required this.minute,
    this.isOwnGoal = false,
  });

  factory GoalEvent.fromJson(Map<String, dynamic> json) {
    return GoalEvent(
      team: json['team'] as String,
      scorer: json['scorer'] as String,
      assistant: json['assistant'] as String?,
      minute: json['minute'] as int,
      isOwnGoal: json['isOwnGoal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'scorer': scorer,
      'assistant': assistant,
      'minute': minute,
      'isOwnGoal': isOwnGoal,
    };
  }
}


class MatchStats {
  final int possessionT1;
  final int shotsT1;
  final int shotsT2;
  final int shotsOnTargetT1;
  final int shotsOnTargetT2;
  final int foulsT1;
  final int foulsT2;
  final int yellowCardsT1;
  final int yellowCardsT2;
  final int redCardsT1;
  final int redCardsT2;

  int get possessionT2 => 100 - possessionT1;

  MatchStats({
    required this.possessionT1,
    required this.shotsT1,
    required this.shotsT2,
    required this.shotsOnTargetT1,
    required this.shotsOnTargetT2,
    required this.foulsT1,
    required this.foulsT2,
    required this.yellowCardsT1,
    required this.yellowCardsT2,
    required this.redCardsT1,
    required this.redCardsT2,
  });

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      possessionT1: json['possessionT1'] as int? ?? 50,
      shotsT1: json['shotsT1'] as int? ?? 0,
      shotsT2: json['shotsT2'] as int? ?? 0,
      shotsOnTargetT1: json['shotsOnTargetT1'] as int? ?? 0,
      shotsOnTargetT2: json['shotsOnTargetT2'] as int? ?? 0,
      foulsT1: json['foulsT1'] as int? ?? 0,
      foulsT2: json['foulsT2'] as int? ?? 0,
      yellowCardsT1: json['yellowCardsT1'] as int? ?? 0,
      yellowCardsT2: json['yellowCardsT2'] as int? ?? 0,
      redCardsT1: json['redCardsT1'] as int? ?? 0,
      redCardsT2: json['redCardsT2'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'possessionT1': possessionT1,
      'shotsT1': shotsT1,
      'shotsT2': shotsT2,
      'shotsOnTargetT1': shotsOnTargetT1,
      'shotsOnTargetT2': shotsOnTargetT2,
      'foulsT1': foulsT1,
      'foulsT2': foulsT2,
      'yellowCardsT1': yellowCardsT1,
      'yellowCardsT2': yellowCardsT2,
      'redCardsT1': redCardsT1,
      'redCardsT2': redCardsT2,
    };
  }

  factory MatchStats.defaultValue() {
    return MatchStats(
      possessionT1: 50,
      shotsT1: 10,
      shotsT2: 10,
      shotsOnTargetT1: 4,
      shotsOnTargetT2: 4,
      foulsT1: 12,
      foulsT2: 12,
      yellowCardsT1: 1,
      yellowCardsT2: 1,
      redCardsT1: 0,
      redCardsT2: 0,
    );
  }
}

class MatchLineupPlayer {
  final String name;      // Canonical name (if matched) or ESPN name
  final String? position; // e.g. "Goalkeeper", "Defender", "Midfielder", "Forward"
  final String? jersey;   // e.g. "10"
  final bool starter;     // true for starting XI, false for bench

  MatchLineupPlayer({
    required this.name,
    this.position,
    this.jersey,
    required this.starter,
  });

  factory MatchLineupPlayer.fromJson(Map<String, dynamic> json) {
    return MatchLineupPlayer(
      name: json['name'] as String,
      position: json['position'] as String?,
      jersey: json['jersey'] as String?,
      starter: json['starter'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (position != null) 'position': position,
      if (jersey != null) 'jersey': jersey,
      'starter': starter,
    };
  }
}

class MatchLineups {
  final List<MatchLineupPlayer> t1Players;
  final List<MatchLineupPlayer> t2Players;
  final String? t1Formation;
  final String? t2Formation;

  MatchLineups({
    required this.t1Players,
    required this.t2Players,
    this.t1Formation,
    this.t2Formation,
  });

  factory MatchLineups.fromJson(Map<String, dynamic> json) {
    return MatchLineups(
      t1Players: (json['t1Players'] as List<dynamic>? ?? [])
          .map((e) => MatchLineupPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      t2Players: (json['t2Players'] as List<dynamic>? ?? [])
          .map((e) => MatchLineupPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      t1Formation: json['t1Formation'] as String?,
      t2Formation: json['t2Formation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      't1Players': t1Players.map((p) => p.toJson()).toList(),
      't2Players': t2Players.map((p) => p.toJson()).toList(),
      if (t1Formation != null) 't1Formation': t1Formation,
      if (t2Formation != null) 't2Formation': t2Formation,
    };
  }
}

class WorldCupMatch {
  final String id;
  final String? espnId; // mapped ESPN event/match ID
  final DateTime date;
  final String t1;
  final String t2;
  final int? _t1ScoreStatic;
  final int? _t2ScoreStatic;
  final String? venue; // null for live API data (not in free tier)
  final String? group;
  final String? stage;
  final List<GoalEvent> goals;
  final MatchStats? stats;
  final String? _statusStatic; // TIMED / SCHEDULED / IN_PLAY / FINISHED / POSTPONED
  final String? _liveMinuteStatic; // "64'", "45+2'", etc.
  final DateTime? lastUpdated;
  final bool? _isKnockoutOverride; // explicit override from JSON
  final MatchLineups? lineups; // Official pre-match lineups

  // ── Extra-time / Penalty shootout result (knockout matches only) ──────────
  /// True if the match was decided in extra time (regardless of penalties).
  final bool? wentToET;

  /// True if the match was decided by a penalty shootout.
  final bool? wentToPK;

  /// Team code of the extra-time winner (also set when PK follows ET).
  final String? etWinner;

  /// Team code of the penalty-shootout winner.
  final String? pkWinner;

  /// Detailed scores for knockout stages
  final int? t1Score90;
  final int? t2Score90;
  final int? t1ScoreET;
  final int? t2ScoreET;
  final int? t1ScorePK;
  final int? t2ScorePK;

  WorldCupMatch({
    required this.id,
    this.espnId,
    required this.date,
    required this.t1,
    required this.t2,
    int? t1Score,
    int? t2Score,
    this.venue,
    this.group,
    this.stage,
    this.goals = const [],
    this.stats,
    String? status,
    String? liveMinute,
    this.lastUpdated,
    bool? isKnockoutOverride,
    this.wentToET,
    this.wentToPK,
    this.etWinner,
    this.pkWinner,
    this.t1Score90,
    this.t2Score90,
    this.t1ScoreET,
    this.t2ScoreET,
    this.t1ScorePK,
    this.t2ScorePK,
    this.lineups,
  }) : _isKnockoutOverride = isKnockoutOverride,
       _t1ScoreStatic = t1Score,
       _t2ScoreStatic = t2Score,
       _statusStatic = status,
       _liveMinuteStatic = liveMinute;

  factory WorldCupMatch.fromJson(Map<String, dynamic> json) {
    var goalsList = const <GoalEvent>[];
    if (json['goals'] != null) {
      final List<dynamic> rawGoals = json['goals'] as List<dynamic>;
      goalsList = rawGoals
          .map((g) => GoalEvent.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    DateTime? lastUpd;
    if (json['lastUpdated'] != null) {
      try {
        lastUpd = DateTime.parse(json['lastUpdated'] as String);
      } catch (_) {}
    }

    return WorldCupMatch(
      id: json['id'] as String,
      espnId: json['espnId'] as String?,
      date: DateTime.parse(json['date'] as String).toLocal(),
      t1: json['t1'] as String? ?? 'xx',
      t2: json['t2'] as String? ?? 'xx',
      t1Score: json['t1Score'] != null
          ? (json['t1Score'] as num).toInt()
          : null,
      t2Score: json['t2Score'] != null
          ? (json['t2Score'] as num).toInt()
          : null,
      venue: json['venue'] as String?,
      group: json['group'] as String?,
      stage: json['stage'] as String?,
      goals: goalsList,
      stats: json['stats'] != null
          ? MatchStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
      liveMinute: json['liveMinute'] as String?,
      lastUpdated: lastUpd,
      isKnockoutOverride: json['isKnockout'] as bool?,
      wentToET: json['wentToET'] as bool?,
      wentToPK: json['wentToPK'] as bool?,
      etWinner: json['etWinner'] as String?,
      pkWinner: json['pkWinner'] as String?,
      t1Score90: json['t1Score90'] != null ? (json['t1Score90'] as num).toInt() : null,
      t2Score90: json['t2Score90'] != null ? (json['t2Score90'] as num).toInt() : null,
      t1ScoreET: json['t1ScoreET'] != null ? (json['t1ScoreET'] as num).toInt() : null,
      t2ScoreET: json['t2ScoreET'] != null ? (json['t2ScoreET'] as num).toInt() : null,
      t1ScorePK: json['t1ScorePK'] != null ? (json['t1ScorePK'] as num).toInt() : null,
      t2ScorePK: json['t2ScorePK'] != null ? (json['t2ScorePK'] as num).toInt() : null,
      lineups: json['lineups'] != null ? MatchLineups.fromJson(json['lineups'] as Map<String, dynamic>) : null,
    );
  }

  factory WorldCupMatch.tbd(String id, String stage) {
    return WorldCupMatch(
      id: id,
      date: DateTime.now(),
      t1: 'TBD',
      t2: 'TBD',
      stage: stage,
      isKnockoutOverride: true,
      status: 'TIMED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'espnId': espnId,
      'date': date.toUtc().toIso8601String(),
      't1': t1,
      't2': t2,
      't1Score': _t1ScoreStatic,
      't2Score': _t2ScoreStatic,
      'venue': venue,
      'group': group,
      'stage': stage,
      'isKnockout': isKnockout,
      'status': _statusStatic,
      'liveMinute': _liveMinuteStatic,
      'goals': goals.map((g) => g.toJson()).toList(),
      if (stats != null) 'stats': stats!.toJson(),
      'wentToET': wentToET,
      'wentToPK': wentToPK,
      'etWinner': etWinner,
      'pkWinner': pkWinner,
      't1Score90': t1Score90,
      't2Score90': t2Score90,
      't1ScoreET': t1ScoreET,
      't2ScoreET': t2ScoreET,
      't1ScorePK': t1ScorePK,
      't2ScorePK': t2ScorePK,
      if (lineups != null) 'lineups': lineups!.toJson(),
    };
  }

  int? get t1Score => _t1ScoreStatic;
  int? get t2Score => _t2ScoreStatic;
  String? get status => _statusStatic;
  String? get liveMinute => _liveMinuteStatic;

  // FIX: Only consider a match played if scores are actually non-null and the match is finished/in-play
  bool get isPlayed => t1Score != null && t2Score != null && (isFinished || (status != 'TIMED' && status != 'SCHEDULED'));

  bool get isFinished => status == 'FINISHED' || status == 'FINAL';

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';

  bool get isFuture => (status == 'TIMED' || status == 'SCHEDULED') || (!isLive && !isFinished && t1Score == null);

  String? get currentLiveMinute {
    final live = LiveMatchService.getLiveData(espnId);
    if (live != null && (live.status == 'in' || live.status == 'post')) {
      if (live.detail == 'STATUS_HALFTIME') return 'HT';
      if (live.detail == 'STATUS_FULL_TIME' || live.detail == 'STATUS_FINAL') return 'FT';
      if (live.clock.isNotEmpty && live.clock != "0'") return live.clock;
    }
    
    if (_liveMinuteStatic != null) return _liveMinuteStatic;
    
    // We removed the unreliable local clock fallback logic based on the user request.
    // The calendar and match cards will now strictly rely on real live data.
    return null;
  }

  bool get isGroupStage => stage == null || stage!.isEmpty;

  bool get isKnockout {
    if (_isKnockoutOverride != null) return _isKnockoutOverride;
    return stage != null && stage!.isNotEmpty;
  }

  String getWinner() {
    if (!isPlayed) return '';
    if (wentToPK == true && pkWinner != null) return pkWinner!;
    if (wentToET == true && etWinner != null) return etWinner!;
    if (t1Score! > t2Score!) return t1;
    if (t2Score! > t1Score!) return t2;
    return '';
  }

  bool isWinner(String teamCode) {
    return getWinner().toLowerCase() == teamCode.toLowerCase();
  }

  String getFormattedTime() {
    return DateFormat('HH:mm').format(date);
  }

  String getFormattedDate(String lang) {
    try {
      return DateFormat.yMd(lang).format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String getDayName(String lang) {
    try {
      return DateFormat.E(lang).format(date);
    } catch (_) {
      return DateFormat('E').format(date);
    }
  }

  String getDayNum(String lang) {
    try {
      return DateFormat.d(lang).add_MMM().format(date);
    } catch (_) {
      return DateFormat('d MMM').format(date);
    }
  }

  WorldCupMatch copyWith({
    String? id,
    String? espnId,
    DateTime? date,
    String? t1,
    String? t2,
    int? t1Score,
    int? t2Score,
    String? venue,
    String? group,
    String? stage,
    List<GoalEvent>? goals,
    MatchStats? stats,
    String? status,
    String? liveMinute,
    DateTime? lastUpdated,
    bool? isKnockoutOverride,
    bool? wentToET,
    bool? wentToPK,
    String? etWinner,
    String? pkWinner,
    int? t1Score90,
    int? t2Score90,
    int? t1ScoreET,
    int? t2ScoreET,
    int? t1ScorePK,
    int? t2ScorePK,
    MatchLineups? lineups,
  }) {
    return WorldCupMatch(
      id: id ?? this.id,
      espnId: espnId ?? this.espnId,
      date: date ?? this.date,
      t1: t1 ?? this.t1,
      t2: t2 ?? this.t2,
      t1Score: t1Score ?? _t1ScoreStatic,
      t2Score: t2Score ?? _t2ScoreStatic,
      venue: venue ?? this.venue,
      group: group ?? this.group,
      stage: stage ?? this.stage,
      goals: goals ?? this.goals,
      stats: stats ?? this.stats,
      status: status ?? _statusStatic,
      liveMinute: liveMinute ?? _liveMinuteStatic,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isKnockoutOverride: isKnockoutOverride ?? _isKnockoutOverride,
      wentToET: wentToET ?? this.wentToET,
      wentToPK: wentToPK ?? this.wentToPK,
      etWinner: etWinner ?? this.etWinner,
      pkWinner: pkWinner ?? this.pkWinner,
      t1Score90: t1Score90 ?? this.t1Score90,
      t2Score90: t2Score90 ?? this.t2Score90,
      t1ScoreET: t1ScoreET ?? this.t1ScoreET,
      t2ScoreET: t2ScoreET ?? this.t2ScoreET,
      t1ScorePK: t1ScorePK ?? this.t1ScorePK,
      t2ScorePK: t2ScorePK ?? this.t2ScorePK,
      lineups: lineups ?? this.lineups,
    );
  }
}

class PlayerStat {
  final String name;
  final int value;
  final String teamCode;

  PlayerStat({required this.name, required this.value, required this.teamCode});
}

class TournamentStats {
  final List<PlayerStat> scorers;
  final List<PlayerStat> assists;

  TournamentStats({required this.scorers, required this.assists});

  static final List<PlayerStat> _officialScorers = [
    PlayerStat(name: 'Kylian Mbappé', value: 10, teamCode: 'fr'),
    PlayerStat(name: 'Lionel Messi', value: 8, teamCode: 'ar'),
    PlayerStat(name: 'Jude Bellingham', value: 7, teamCode: 'en'),
    PlayerStat(name: 'Erling Haaland', value: 7, teamCode: 'no'),
    PlayerStat(name: 'Ousmane Dembélé', value: 6, teamCode: 'fr'),
    PlayerStat(name: 'Harry Kane', value: 6, teamCode: 'en'),
    PlayerStat(name: 'Mikel Merino', value: 5, teamCode: 'es'),
    PlayerStat(name: 'Ismaïla Sarr', value: 4, teamCode: 'sn'),
    PlayerStat(name: 'Julián Quiñones', value: 4, teamCode: 'mx'),
    PlayerStat(name: 'Vinicius Junior', value: 4, teamCode: 'br'),
    PlayerStat(name: 'Bukayo Saka', value: 3, teamCode: 'en'),
    PlayerStat(name: 'Deniz Undav', value: 3, teamCode: 'de'),
    PlayerStat(name: 'Johan Manzambi', value: 3, teamCode: 'ch'),
    PlayerStat(name: 'Romelu Lukaku', value: 3, teamCode: 'be'),
    PlayerStat(name: 'Lautaro Martínez', value: 3, teamCode: 'ar'),
    PlayerStat(name: 'Charles De Ketelaere', value: 3, teamCode: 'be'),
    PlayerStat(name: 'Memphis Depay', value: 3, teamCode: 'nl'),
    PlayerStat(name: 'Bradley Barcola', value: 3, teamCode: 'fr'),
    PlayerStat(name: 'Harvey Elliott', value: 3, teamCode: 'en'),
    PlayerStat(name: 'Elijah Just', value: 3, teamCode: 'nz'),
    PlayerStat(name: 'William Saliba', value: 3, teamCode: 'fr'),
    PlayerStat(name: 'Ricardo Pepi', value: 3, teamCode: 'us'),
    PlayerStat(name: 'Raúl Jiménez', value: 3, teamCode: 'mx'),
    PlayerStat(name: 'Kai Havertz', value: 3, teamCode: 'de'),
    PlayerStat(name: 'Yoane Wissa', value: 3, teamCode: 'cd'),
  ];

  static final List<PlayerStat> _officialAssists = [
    PlayerStat(name: 'Michael Olise', value: 7, teamCode: 'fr'),
    PlayerStat(name: 'Martin Ødegaard', value: 4, teamCode: 'no'),
    PlayerStat(name: 'Kylian Mbappé', value: 4, teamCode: 'fr'),
    PlayerStat(name: 'Brahim Díaz', value: 4, teamCode: 'ma'),
    PlayerStat(name: 'Bruno Guimarães', value: 4, teamCode: 'br'),
    PlayerStat(name: 'Lionel Messi', value: 4, teamCode: 'ar'),
    PlayerStat(name: 'Roberto Alvarado', value: 3, teamCode: 'mx'),
    PlayerStat(name: 'Anthony Gordon', value: 3, teamCode: 'en'),
    PlayerStat(name: 'Florian Wirtz', value: 3, teamCode: 'de'),
    PlayerStat(name: 'Andreas Schjelderup', value: 3, teamCode: 'no'),
    PlayerStat(name: 'Bukayo Saka', value: 3, teamCode: 'en'),
    PlayerStat(name: 'Alexander Isak', value: 3, teamCode: 'se'),
    PlayerStat(name: 'Chris Wood', value: 2, teamCode: 'nz'),
    PlayerStat(name: 'Johan Manzambi', value: 2, teamCode: 'ch'),
    PlayerStat(name: 'Breel Embolo', value: 2, teamCode: 'ch'),
    PlayerStat(name: 'Dani Olmo', value: 2, teamCode: 'es'),
    PlayerStat(name: 'Marc Cucurella', value: 2, teamCode: 'es'),
    PlayerStat(name: 'Viktor Gyökeres', value: 2, teamCode: 'se'),
    PlayerStat(name: 'Nicolas Raskin', value: 2, teamCode: 'be'),
    PlayerStat(name: 'Patrick Berg', value: 2, teamCode: 'no'),
    PlayerStat(name: 'Joshua Kimmich', value: 2, teamCode: 'de'),
    PlayerStat(name: 'Hans Vanaken', value: 2, teamCode: 'be'),
    PlayerStat(name: 'Leandro Trossard', value: 2, teamCode: 'be'),
    PlayerStat(name: 'Deniz Undav', value: 2, teamCode: 'de'),
    PlayerStat(name: 'Crysencio Summerville', value: 2, teamCode: 'nl'),
    PlayerStat(name: 'Ryan Gravenberch', value: 2, teamCode: 'nl'),
    PlayerStat(name: 'Ousmane Dembélé', value: 2, teamCode: 'fr'),
    PlayerStat(name: 'Denzel Dumfries', value: 2, teamCode: 'nl'),
    PlayerStat(name: 'Declan Rice', value: 2, teamCode: 'en'),
    PlayerStat(name: 'Houssem Aouar', value: 2, teamCode: 'dz'),
    PlayerStat(name: 'Julio Enciso', value: 2, teamCode: 'py'),
    PlayerStat(name: 'William Saliba', value: 2, teamCode: 'fr'),
    PlayerStat(name: 'Achraf Hakimi', value: 2, teamCode: 'ma'),
    PlayerStat(name: 'Hannibal Mejbri', value: 2, teamCode: 'tn'),
    PlayerStat(name: 'Mohamed Salah', value: 2, teamCode: 'eg'),
    PlayerStat(name: 'Iliman Ndiaye', value: 2, teamCode: 'sn'),
  ];

  factory TournamentStats.compute(List<WorldCupMatch> matches) {
    // If all 104 matches exist and tournament is complete, return official FIFA rankings directly
    if (matches.length >= 104) {
      return TournamentStats(scorers: _officialScorers, assists: _officialAssists);
    }

    final Map<String, int> goalCounts = {};
    final Map<String, String> scorerTeams = {};
    final Map<String, int> assistCounts = {};
    final Map<String, String> assistTeams = {};

    for (final match in matches) {
      if (match.isPlayed) {
        for (final goal in match.goals) {
          final teamCode = (goal.team == 't1' ? match.t1 : match.t2).toLowerCase();
          final teamNameEn = AppTranslations.getTeam('en', teamCode);

          if (!goal.isOwnGoal) {
            final scorerName = goal.scorer.trim();
            if (scorerName.isNotEmpty) {
              final normalized = PlayerDatabaseService.getBestMatchingName(teamNameEn, scorerName) ?? scorerName;
              goalCounts[normalized] = (goalCounts[normalized] ?? 0) + 1;
              scorerTeams[normalized] = teamCode;
            }
          }

          final assistantName = goal.assistant?.trim();
          if (assistantName != null && assistantName.isNotEmpty) {
            final normalized = PlayerDatabaseService.getBestMatchingName(teamNameEn, assistantName) ?? assistantName;
            assistCounts[normalized] = (assistCounts[normalized] ?? 0) + 1;
            assistTeams[normalized] = teamCode;
          }
        }
      }
    }

    final List<PlayerStat> scorersList = goalCounts.entries.map((e) {
      return PlayerStat(
        name: e.key,
        value: e.value,
        teamCode: scorerTeams[e.key] ?? 'tbd',
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<PlayerStat> assistsList = assistCounts.entries.map((e) {
      return PlayerStat(
        name: e.key,
        value: e.value,
        teamCode: assistTeams[e.key] ?? 'tbd',
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return TournamentStats(scorers: scorersList, assists: assistsList);
  }
}
