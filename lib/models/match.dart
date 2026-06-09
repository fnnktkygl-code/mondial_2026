import 'package:intl/intl.dart';

class GoalEvent {
  final String team; // "t1" or "t2"
  final String scorer;
  final String? assistant;
  final int minute;

  GoalEvent({
    required this.team,
    required this.scorer,
    this.assistant,
    required this.minute,
  });

  factory GoalEvent.fromJson(Map<String, dynamic> json) {
    return GoalEvent(
      team: json['team'] as String,
      scorer: json['scorer'] as String,
      assistant: json['assistant'] as String?,
      minute: json['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'scorer': scorer,
      if (assistant != null) 'assistant': assistant,
      'minute': minute,
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

class WorldCupMatch {
  final String id;
  final DateTime date;
  final String t1;
  final String t2;
  final int? t1Score;
  final int? t2Score;
  final String? venue; // null for live API data (not in free tier)
  final String? group;
  final String? stage;
  final List<GoalEvent> goals;
  final MatchStats? stats;
  final String? status; // TIMED / SCHEDULED / IN_PLAY / FINISHED / POSTPONED
  final DateTime? lastUpdated;
  final bool? _isKnockoutOverride; // explicit override from JSON

  // ── Extra-time / Penalty shootout result (knockout matches only) ──────────
  /// True if the match was decided in extra time (regardless of penalties).
  final bool? wentToET;

  /// True if the match was decided by a penalty shootout.
  final bool? wentToPK;

  /// Team code of the extra-time winner (also set when PK follows ET).
  final String? etWinner;

  /// Team code of the penalty-shootout winner.
  final String? pkWinner;

  WorldCupMatch({
    required this.id,
    required this.date,
    required this.t1,
    required this.t2,
    this.t1Score,
    this.t2Score,
    this.venue,
    this.group,
    this.stage,
    this.goals = const [],
    this.stats,
    this.status,
    this.lastUpdated,
    bool? isKnockoutOverride,
    this.wentToET,
    this.wentToPK,
    this.etWinner,
    this.pkWinner,
  }) : _isKnockoutOverride = isKnockoutOverride;

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
      lastUpdated: lastUpd,
      isKnockoutOverride: json['isKnockout'] as bool?,
      wentToET: json['wentToET'] as bool?,
      wentToPK: json['wentToPK'] as bool?,
      etWinner: json['etWinner'] as String?,
      pkWinner: json['pkWinner'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toUtc().toIso8601String(),
      't1': t1,
      't2': t2,
      't1Score': t1Score,
      't2Score': t2Score,
      'venue': venue,
      'group': group,
      'stage': stage,
      'isKnockout': isKnockout,
      'status': status,
      'goals': goals.map((g) => g.toJson()).toList(),
      if (stats != null) 'stats': stats!.toJson(),
    };
  }

  // FIX: Only consider a match played if the scores are actually loaded and present!
  // Previously, this evaluated to true on `status == 'FINISHED'` alone, causing a
  // null assertion crash (`t1Score!`) in your standings loops.
  bool get isPlayed => t1Score != null && t2Score != null;

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';

  bool get isKnockout {
    if (_isKnockoutOverride != null) return _isKnockoutOverride;
    return stage != null && stage!.isNotEmpty;
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
    DateTime? lastUpdated,
    bool? isKnockoutOverride,
    bool? wentToET,
    bool? wentToPK,
    String? etWinner,
    String? pkWinner,
  }) {
    return WorldCupMatch(
      id: id ?? this.id,
      date: date ?? this.date,
      t1: t1 ?? this.t1,
      t2: t2 ?? this.t2,
      t1Score: t1Score ?? this.t1Score,
      t2Score: t2Score ?? this.t2Score,
      venue: venue ?? this.venue,
      group: group ?? this.group,
      stage: stage ?? this.stage,
      goals: goals ?? this.goals,
      stats: stats ?? this.stats,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isKnockoutOverride: isKnockoutOverride ?? _isKnockoutOverride,
      wentToET: wentToET ?? this.wentToET,
      wentToPK: wentToPK ?? this.wentToPK,
      etWinner: etWinner ?? this.etWinner,
      pkWinner: pkWinner ?? this.pkWinner,
    );
  }
}
