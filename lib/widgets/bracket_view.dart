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

  const BracketViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    required this.onMatchTap,
    this.supportedTeamCode,
  });

  List<WorldCupMatch> _getMatchesForStage(String stageName) {
    return matches.where((m) => m.stage == stageName).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Widget build(BuildContext context) {
    // Stage matches
    final r32Matches = _getMatchesForStage('Round of 32');
    final r16Matches = _getMatchesForStage('Round of 16');
    final qfMatches = _getMatchesForStage('Quarter-Final');
    final sfMatches = _getMatchesForStage('Semi-Final');
    final fMatches = _getMatchesForStage('Final');

    // Split Left and Right sides of the bracket
    // Left side: m49 to m56 (R32), m65 to m68 (R16), m73 to m74 (QF), m77 (SF)
    // Right side: m57 to m64 (R32), m69 to m72 (R16), m75 to m76 (QF), m78 (SF)
    final leftR32 = r32Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 49 && idNum <= 56;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightR32 = r32Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 57 && idNum <= 64;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftR16 = r16Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 65 && idNum <= 68;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightR16 = r16Matches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 69 && idNum <= 72;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftQF = qfMatches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 73 && idNum <= 74;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final rightQF = qfMatches.where((m) {
      final idNum = int.tryParse(m.id.substring(1)) ?? 0;
      return idNum >= 75 && idNum <= 76;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    final leftSF = sfMatches.where((m) => m.id == 'm77').toList();
    final rightSF = sfMatches.where((m) => m.id == 'm78').toList();

    WorldCupMatch? finalMatch;
    try {
      finalMatch = fMatches.firstWhere((m) => m.id == 'm80');
    } catch (_) {
      try {
        finalMatch = fMatches.firstWhere((m) => m.stage == 'Final');
      } catch (_) {
        finalMatch = fMatches.isNotEmpty ? fMatches[0] : null;
      }
    }

    WorldCupMatch? thirdPlaceMatch;
    try {
      thirdPlaceMatch = matches.firstWhere((m) => m.id == 'm79');
    } catch (_) {
      try {
        thirdPlaceMatch = matches.firstWhere((m) => m.stage == 'Play-off for third place');
      } catch (_) {
        thirdPlaceMatch = null;
      }
    }

    // Sizing tokens
    const double cardHeight = 96.0;
    const double r32BlockHeight = 120.0; // cardHeight + gap (24.0)

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
            // ================= LEFT SIDE OF BRACKET =================
            // Left Round of 32 (8 matches)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r32'),
              matches: leftR32,
              blockHeight: r32BlockHeight,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(leftR32.length, r32BlockHeight, isLeftHandSide: true),

            // Left Round of 16 (4 matches)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r16'),
              matches: leftR16,
              blockHeight: r32BlockHeight * 2,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(leftR16.length, r32BlockHeight * 2, isLeftHandSide: true),

            // Left Quarter Finals (2 matches)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'qf'),
              matches: leftQF,
              blockHeight: r32BlockHeight * 4,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(leftQF.length, r32BlockHeight * 4, isLeftHandSide: true),

            // Left Semi Finals (1 match)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'sf'),
              matches: leftSF,
              blockHeight: r32BlockHeight * 8,
              cardHeight: cardHeight,
            ),
            _buildStraightConnector(r32BlockHeight * 4), // center of the 960px block is 480.0

            // ================= CENTER FINAL =================
            _buildCenterColumn(
              finalTitle: AppTranslations.get(lang, 'f'),
              finalMatch: finalMatch,
              thirdPlaceMatch: thirdPlaceMatch,
              blockHeight: r32BlockHeight * 8, // 960.0
              cardHeight: cardHeight,
            ),

            // ================= RIGHT SIDE OF BRACKET =================
            _buildStraightConnector(r32BlockHeight * 4), // center is 480.0

            // Right Semi Finals (1 match)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'sf'),
              matches: rightSF,
              blockHeight: r32BlockHeight * 8,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(rightQF.length, r32BlockHeight * 4, isLeftHandSide: false), // connects Right QF to SF

            // Right Quarter Finals (2 matches)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'qf'),
              matches: rightQF,
              blockHeight: r32BlockHeight * 4,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(rightR16.length, r32BlockHeight * 2, isLeftHandSide: false), // connects Right R16 to QF

            // Right Round of 16 (4 matches)
            _buildBracketColumn(
              title: AppTranslations.get(lang, 'r16'),
              matches: rightR16,
              blockHeight: r32BlockHeight * 2,
              cardHeight: cardHeight,
            ),
            _buildColumnConnector(rightR32.length, r32BlockHeight, isLeftHandSide: false), // connects Right R32 to R16

            // Right Round of 32 (8 matches)
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

  Widget _buildBracketColumn({
    required String title,
    required List<WorldCupMatch> matches,
    required double blockHeight,
    required double cardHeight,
  }) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Stage Title
          SizedBox(
            height: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  title,
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

          // Matches
          ...matches.map((m) {
            return SizedBox(
              height: blockHeight,
              child: Center(
                child: _buildBracketCard(m, cardHeight),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCenterColumn({
    required String finalTitle,
    required WorldCupMatch? finalMatch,
    required WorldCupMatch? thirdPlaceMatch,
    required double blockHeight,
    required double cardHeight,
  }) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Stage Title
          SizedBox(
            height: 30,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  finalTitle,
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

          // Stack for Final Card (with trophy above) and Third Place Card below
          SizedBox(
            height: blockHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Trophy Emoji above Final card
                Positioned(
                  top: (blockHeight / 2) - (cardHeight / 2) - 38,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                // Final Match Card (Centered at y = 480)
                if (finalMatch != null)
                  Positioned(
                    top: (blockHeight / 2) - (cardHeight / 2),
                    left: 0,
                    right: 0,
                    child: _buildBracketCard(finalMatch, cardHeight),
                  ),

                // Third Place Match Card
                if (thirdPlaceMatch != null)
                  Positioned(
                    top: (blockHeight / 2) + (cardHeight / 2) + 60,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang == 'fr'
                              ? 'Match 3e place'
                              : lang == 'es'
                                  ? 'Tercer Puesto'
                                  : '3rd Place Match',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBracketCard(thirdPlaceMatch, cardHeight),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketCard(WorldCupMatch m, double height) {
    final t1EmblemName = AppTranslations.getTeamWithEmblem(lang, m.t1);
    final t2EmblemName = AppTranslations.getTeamWithEmblem(lang, m.t2);

    final isT1Winner = m.isPlayed && (m.t1Score! > m.t2Score!);
    final isT2Winner = m.isPlayed && (m.t2Score! > m.t1Score!);

    final bool isUserTeamMatch = supportedTeamCode != null &&
        (m.t1.toLowerCase() == supportedTeamCode!.toLowerCase() ||
         m.t2.toLowerCase() == supportedTeamCode!.toLowerCase());

    return GestureDetector(
      onTap: () => onMatchTap(m),
      child: Container(
        width: 170,
        height: height,
        decoration: BoxDecoration(
          color: isUserTeamMatch
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserTeamMatch
                ? AppColors.accent
                : (m.isPlayed ? AppColors.border : AppColors.borderMid),
            width: isUserTeamMatch ? 2.2 : 1.5,
          ),
          boxShadow: isUserTeamMatch
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team 1 Row
            _buildBracketTeamRow(
              code: m.t1,
              name: t1EmblemName,
              score: m.t1Score,
              isWinner: isT1Winner,
              isLoser: m.isPlayed && !isT1Winner,
            ),
            // Divider
            Container(
              height: 1.5,
              color: AppColors.border,
            ),
            // Team 2 Row
            _buildBracketTeamRow(
              code: m.t2,
              name: t2EmblemName,
              score: m.t2Score,
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
    required String name,
    required int? score,
    required bool isWinner,
    required bool isLoser,
  }) {
    final isPlaceholder = code.length > 2 || code == 'tbd';

    return Expanded(
      child: Container(
        color: isWinner ? AppColors.accent.withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flag + Name
            Expanded(
              child: Row(
                children: [
                  _buildMiniFlag(code),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isPlaceholder
                            ? AppColors.textDim
                            : isWinner
                                ? Colors.white
                                : isLoser
                                    ? AppColors.borderStrong
                                    : AppColors.textSecondary,
                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Score
            if (score != null)
              Text(
                '$score',
                style: TextStyle(
                  color: isWinner ? AppColors.accent : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            else
              const Text(
                '-',
                style: TextStyle(color: AppColors.borderStrong, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

Widget _buildMiniFlag(String code) {
    if ((code.length > 2 && code.toLowerCase() != 'sco') || code.toLowerCase() == 'tbd') {
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
          'F',
          style: TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
        ),
      );
    }
    return TeamFlagWidget(
      code: code,
      width: 18,
      height: 12,
      borderRadius: 2,
    );
  }

  Widget _buildColumnConnector(int itemsCount, double blockHeight, {required bool isLeftHandSide}) {
    return Container(
      width: 30,
      height: itemsCount * blockHeight,
      margin: const EdgeInsets.only(top: 60), // aligns with the matches
      child: CustomPaint(
        painter: BracketConnectorPainter(
          itemsCount: itemsCount,
          blockHeight: blockHeight,
          isLeftHandSide: isLeftHandSide,
        ),
      ),
    );
  }

  Widget _buildStraightConnector(double yPosition) {
    return Container(
      width: 30,
      height: 960.0,
      margin: const EdgeInsets.only(top: 60), // aligns with the matches
      child: CustomPaint(
        painter: StraightConnectorPainter(
          yPosition: yPosition,
        ),
      ),
    );
  }
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
      // Top feeder match center
      final double y1 = (i * blockHeight) + halfBlock;
      // Bottom feeder match center
      final double y2 = ((i + 1) * blockHeight) + halfBlock;
      // Midpoint recipient match center
      final double yMid = (y1 + y2) / 2;

      if (isLeftHandSide) {
        // Feeders on Left, Recipient on Right
        canvas.drawLine(Offset(0, y1), Offset(size.width / 2, y1), paint);
        canvas.drawLine(Offset(0, y2), Offset(size.width / 2, y2), paint);
        canvas.drawLine(Offset(size.width / 2, y1), Offset(size.width / 2, y2), paint);
        canvas.drawLine(Offset(size.width / 2, yMid), Offset(size.width, yMid), paint);
      } else {
        // Feeders on Right, Recipient on Left
        canvas.drawLine(Offset(size.width, y1), Offset(size.width / 2, y1), paint);
        canvas.drawLine(Offset(size.width, y2), Offset(size.width / 2, y2), paint);
        canvas.drawLine(Offset(size.width / 2, y1), Offset(size.width / 2, y2), paint);
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
