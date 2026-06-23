class PredictionTrend {
  final int t1Wins;
  final int draws;
  final int t2Wins;
  final int total;

  PredictionTrend({
    this.t1Wins = 0,
    this.draws = 0,
    this.t2Wins = 0,
    this.total = 0,
  });

  factory PredictionTrend.fromJson(Map<String, dynamic> json) {
    return PredictionTrend(
      t1Wins: json['t1'] as int? ?? 0,
      draws: json['draw'] as int? ?? 0,
      t2Wins: json['t2'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  double get t1Percentage => total == 0 ? 0 : t1Wins / total;
  double get drawPercentage => total == 0 ? 0 : draws / total;
  double get t2Percentage => total == 0 ? 0 : t2Wins / total;
}
