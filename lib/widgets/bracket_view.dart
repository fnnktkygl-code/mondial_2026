import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';

class BracketViewWidget extends StatelessWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final Function(WorldCupMatch match) onMatchTap;
  final String? supportedTeamCode;

  static final Map<String, int> _idCache = {};
  static final RegExp _digitRegex = RegExp(r'\d+');

  const BracketViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.onMatchTap,
    this.supportedTeamCode,
  });

  static int _getParsedId(String id) {
    return _idCache.putIfAbsent(id, () {
      return int.tryParse(_digitRegex.firstMatch(id)?.group(0) ?? '0') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r32Matches = _getMatchesForStage('Round of 32');
    final r16Matches = _getMatchesForStage('Round of 16');
    final qfMatches = _getMatchesForStage('Quarter-Final');
    final sfMatches = _getMatchesForStage('Semi-Final');
    final fMatches = _getMatchesForStage('Final');

    final leftR32 =
        r32Matches
            .where((m) => _getParsedId(m.id) >= 49 && _getParsedId(m.id) <= 56)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final rightR32 =
        r32Matches
            .where((m) => _getParsedId(m.id) >= 57 && _getParsedId(m.id) <= 64)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final leftR16 =
        r16Matches
            .where((m) => _getParsedId(m.id) >= 65 && _getParsedId(m.id) <= 68)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final rightR16 =
        r16Matches
            .where((m) => _getParsedId(m.id) >= 69 && _getParsedId(m.id) <= 72)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final leftQF =
        qfMatches
            .where((m) => _getParsedId(m.id) >= 73 && _getParsedId(m.id) <= 74)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final rightQF =
        qfMatches
            .where((m) => _getParsedId(m.id) >= 75 && _getParsedId(m.id) <= 76)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final leftSF = sfMatches.where((m) => m.id == 'm77').toList();
    final rightSF = sfMatches.where((m) => m.id == 'm78').toList();

    const double cardHeight = 96.0;
    const double r32BlockHeight = 120.0;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(40.0),
      minScale: 0.2,
      maxScale: 1.5,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r32'),
              matches: leftR32,
              blockHeight: r32BlockHeight,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              leftR32.length,
              r32BlockHeight,
              isLeftHandSide: true,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r16'),
              matches: leftR16,
              blockHeight: r32BlockHeight * 2,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              leftR16.length,
              r32BlockHeight * 2,
              isLeftHandSide: true,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'qf'),
              matches: leftQF,
              blockHeight: r32BlockHeight * 4,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              leftQF.length,
              r32BlockHeight * 4,
              isLeftHandSide: true,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'sf'),
              matches: leftSF,
              blockHeight: r32BlockHeight * 8,
              cardHeight: cardHeight,
            ),
            _buildStraightConnector(r32BlockHeight * 4),
            _buildCenterColumn(
              finalTitle: AppTranslations.get(lang, 'f'),
              finalMatch: fMatches.isNotEmpty ? fMatches[0] : null,
              blockHeight: r32BlockHeight * 8,
              cardHeight: cardHeight,
            ),
            _buildStraightConnector(r32BlockHeight * 4),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'sf'),
              matches: rightSF,
              blockHeight: r32BlockHeight * 8,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              rightQF.length,
              r32BlockHeight * 4,
              isLeftHandSide: false,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'qf'),
              matches: rightQF,
              blockHeight: r32BlockHeight * 4,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              rightR16.length,
              r32BlockHeight * 2,
              isLeftHandSide: false,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r16'),
              matches: rightR16,
              blockHeight: r32BlockHeight * 2,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(
              rightR32.length,
              r32BlockHeight,
              isLeftHandSide: false,
            ),
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r32'),
              matches: rightR32,
              blockHeight: r32BlockHeight,
              cardHeight: cardHeight,
            ),
          ],
        ),
      ),
    );
  }

  List<WorldCupMatch> _getMatchesForStage(String stageName) =>
      matches.where((m) => m.stage == stageName).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  Widget _buildBracketColumn({
    required String title,
    required List<WorldCupMatch> matches,
    required double blockHeight,
    required double cardHeight,
  }) {
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...matches.map(
            (m) => SizedBox(
              height: blockHeight,
              child: Center(child: _buildBracketCard(m, cardHeight)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterColumn({
    required String finalTitle,
    required WorldCupMatch? finalMatch,
    required double blockHeight,
    required double cardHeight,
  }) {
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  finalTitle.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: blockHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: (blockHeight / 2) - (cardHeight / 2) - 38,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 24)),
                  ),
                ),
                if (finalMatch != null)
                  Positioned(
                    top: (blockHeight / 2) - (cardHeight / 2),
                    left: 0,
                    right: 0,
                    child: _buildBracketCard(finalMatch, cardHeight),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketCard(WorldCupMatch m, double height) {
    final isT1Winner = m.isPlayed && (m.t1Score ?? 0) > (m.t2Score ?? 0);
    final isT2Winner = m.isPlayed && (m.t2Score ?? 0) > (m.t1Score ?? 0);
    final isUserTeam =
        supportedTeamCode != null &&
        (m.t1.toLowerCase() == supportedTeamCode!.toLowerCase() ||
            m.t2.toLowerCase() == supportedTeamCode!.toLowerCase());

    return GestureDetector(
      onTap: () => onMatchTap(m),
      child: Container(
        width: 170,
        height: height,
        decoration: BoxDecoration(
          color: isUserTeam
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserTeam
                ? AppColors.accent
                : (m.isPlayed ? AppColors.border : AppColors.borderMid),
            width: isUserTeam ? 2.2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBracketTeamRow(
              code: m.t1,
              score: m.t1Score ?? 0,
              isWinner: isT1Winner,
              isLoser: m.isPlayed && !isT1Winner,
            ),
            Container(height: 1.5, color: AppColors.border),
            _buildBracketTeamRow(
              code: m.t2,
              score: m.t2Score ?? 0,
              isWinner: isT2Winner,
              isLoser: m.isPlayed && !isT2Winner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketTeamRow({
    required String code,
    required int score,
    required bool isWinner,
    required bool isLoser,
  }) {
    final isPlaceholder = code.length > 2 || code.toLowerCase() == 'tbd';
    return Expanded(
      child: Container(
        color: isWinner
            ? AppColors.accent.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildMiniFlag(code),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppTranslations.getTeamWithEmblem(lang, code),
                      style: TextStyle(
                        color: isPlaceholder
                            ? AppColors.textDim
                            : (isWinner
                                  ? Colors.white
                                  : isLoser
                                  ? AppColors.borderStrong
                                  : AppColors.textSecondary),
                        fontWeight: isWinner
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                color: isWinner ? AppColors.accent : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFlag(String code) {
    if ((code.length > 2 && code.toLowerCase() != 'sco') ||
        code.toLowerCase() == 'tbd') {
      return Container(
        width: 18,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.borderStrong, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          '?',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return TeamFlagWidget(code: code, width: 18, height: 12, borderRadius: 2);
  }

  Widget _buildColumnConnector(
    int itemsCount,
    double blockHeight, {
    required bool isLeftHandSide,
  }) => Container(
    width: 30,
    height: itemsCount * blockHeight,
    margin: const EdgeInsets.only(top: 60),
    child: CustomPaint(
      painter: BracketConnectorPainter(
        itemsCount: itemsCount,
        blockHeight: blockHeight,
        isLeftHandSide: isLeftHandSide,
      ),
    ),
  );
  Widget _buildStraightConnector(double yPosition) => Container(
    width: 30,
    height: 960.0,
    margin: const EdgeInsets.only(top: 60),
    child: CustomPaint(painter: StraightConnectorPainter(yPosition: yPosition)),
  );
}

class BracketConnectorPainter extends CustomPainter {
  final int itemsCount;
  final double blockHeight;
  final bool isLeftHandSide;
  BracketConnectorPainter({
    required this.itemsCount,
    required this.blockHeight,
    required this.isLeftHandSide,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final double halfBlock = blockHeight / 2;
    for (int i = 0; i < itemsCount; i += 2) {
      final double y1 = (i * blockHeight) + halfBlock;
      final double y2 = ((i + 1) * blockHeight) + halfBlock;
      final double yMid = (y1 + y2) / 2;
      if (isLeftHandSide) {
        canvas.drawLine(Offset(0, y1), Offset(size.width / 2, y1), paint);
        canvas.drawLine(Offset(0, y2), Offset(size.width / 2, y2), paint);
        canvas.drawLine(
          Offset(size.width / 2, y1),
          Offset(size.width / 2, y2),
          paint,
        );
        canvas.drawLine(
          Offset(size.width / 2, yMid),
          Offset(size.width, yMid),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(size.width, y1),
          Offset(size.width / 2, y1),
          paint,
        );
        canvas.drawLine(
          Offset(size.width, y2),
          Offset(size.width / 2, y2),
          paint,
        );
        canvas.drawLine(
          Offset(size.width / 2, y1),
          Offset(size.width / 2, y2),
          paint,
        );
        canvas.drawLine(Offset(size.width / 2, yMid), Offset(0, yMid), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StraightConnectorPainter extends CustomPainter {
  final double yPosition;
  StraightConnectorPainter({required this.yPosition});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, yPosition), Offset(size.width, yPosition), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
