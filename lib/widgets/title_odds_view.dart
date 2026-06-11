import 'package:flutter/material.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'team_profile_dialog.dart';

class WCTitleOddsView extends StatefulWidget {
  final List<WorldCupMatch> resolvedMatches;
  final String lang;
  final String? supportedTeamCode;
  final Map<String, double> currentOdds;
  final Map<String, double>? previousOdds;

  const WCTitleOddsView({
    super.key,
    required this.resolvedMatches,
    required this.lang,
    this.supportedTeamCode,
    required this.currentOdds,
    this.previousOdds,
  });

  @override
  State<WCTitleOddsView> createState() => _WCTitleOddsViewState();
}

class _WCTitleOddsViewState extends State<WCTitleOddsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showExplanation = true; // Gère l'affichage du guide pour les débutants

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter and sort teams
    final List<MapEntry<String, double>> sortedTeams = widget.currentOdds.entries.toList();

    // Sort:
    // 1. Odds descending (higher odds first)
    // 2. If equal (e.g. 0.0% eliminated), sort alphabetically by localized team name
    sortedTeams.sort((a, b) {
      if (b.value != a.value) {
        return b.value.compareTo(a.value);
      }
      final nameA = AppTranslations.getTeam(widget.lang, a.key);
      final nameB = AppTranslations.getTeam(widget.lang, b.key);
      return nameA.compareTo(nameB);
    });

    // Filter by search query and eliminate teams with 0.0 odds
    final filteredTeams = sortedTeams.where((entry) {
      // Si la cote est à 0.0, l'équipe est mathématiquement éliminée de la course au titre
      if (entry.value <= 0.0) return false;

      final teamName = AppTranslations.getTeam(widget.lang, entry.key).toLowerCase();
      final teamCode = entry.key.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return teamName.contains(query) || teamCode.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppTranslations.get(widget.lang, 'searchTeams'),
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textDim, size: 18),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),

        // Info Banner pour les utilisateurs novices (méthode de contextualisation avec police adaptée)
        if (_showExplanation) _buildContextualBanner(),

        Expanded(
          child: filteredTeams.isEmpty
              ? Center(
            child: Text(
              AppTranslations.get(widget.lang, 'noTeamsFound'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
            itemCount: filteredTeams.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = filteredTeams[index];
              final code = entry.key;
              final odds = entry.value;
              final mapIndex = sortedTeams.indexWhere((e) => e.key == code);
              final prevOdds = widget.previousOdds?[code] ?? odds;

              return _buildTeamOddsCard(context, mapIndex + 1, code, odds, prevOdds);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContextualBanner() {
    final viewTitle = AppTranslations.get(widget.lang, 'oddsViewTitle');
    final viewDesc = AppTranslations.get(widget.lang, 'oddsViewExplanation');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderMid,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Augmentation du padding pour aérer
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.accent,
                  size: 24, // Augmenté de 20 à 24 pour la visibilité
                ),
              ),
              const SizedBox(width: 14), // Espacement horizontal augmenté de 12 à 14
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15, // Augmenté de 13 à 15 pour une lecture optimale
                      ),
                    ),
                    const SizedBox(height: 6), // Espacement vertical augmenté de 4 à 6
                    Text(
                      viewDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary, // Remplacement de textDim par textSecondary pour plus de contraste
                        fontSize: 13, // Augmenté de 11 à 13 pour la lisibilité sur mobile
                        height: 1.45, // Augmentation de la hauteur de ligne pour aérer le bloc
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20), // Augmenté de 16 à 20 pour faciliter la zone de clic
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _showExplanation = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamOddsCard(
      BuildContext context,
      int rank,
      String code,
      double odds,
      double prevOdds,
      ) {
    final teamName = AppTranslations.getTeam(widget.lang, code);
    final isFav = widget.supportedTeamCode?.toLowerCase() == code.toLowerCase();
    final isEliminated = odds == 0.0;

    // Calculate Trend
    Widget trendWidget;
    Color trendColor;
    final double diff = odds - prevOdds;

    if (isEliminated) {
      trendWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Text(
          AppTranslations.get(widget.lang, 'eliminated').toUpperCase(),
          style: const TextStyle(
            color: AppColors.danger,
            fontSize: 11, // Augmenté de 9 à 11 pour l'accessibilité mobile
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (diff > 0.01) {
      trendColor = AppColors.accent;
      trendWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward, color: trendColor, size: 12),
          const SizedBox(width: 2),
          Text(
            '+${diff.toStringAsFixed(1)}%',
            style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (diff < -0.01) {
      trendColor = AppColors.danger;
      trendWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_downward, color: trendColor, size: 12),
          const SizedBox(width: 2),
          Text(
            '${diff.toStringAsFixed(1)}%',
            style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      trendWidget = const Text(
        '—',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isFav ? AppColors.accent.withValues(alpha: 0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFav
              ? AppColors.accent
              : isEliminated
              ? AppColors.border.withValues(alpha: 0.4)
              : AppColors.border,
          width: isFav ? 2.0 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            WCTeamProfileDialog.show(context, code, widget.lang);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Rank indicator
                    SizedBox(
                      width: 28, // Augmenté de 26 à 28
                      child: Text(
                        isEliminated ? '—' : '#$rank',
                        style: TextStyle(
                          color: isEliminated ? AppColors.textMuted : (rank <= 3 ? AppColors.accent : Colors.white),
                          fontWeight: FontWeight.w900,
                          fontSize: 14, // Augmenté de 13 à 14
                        ),
                      ),
                    ),

                    // Flag
                    Hero(
                      tag: 'odds_flag_$code',
                      child: TeamFlagWidget(
                        code: code,
                        width: 32,
                        height: 22,
                        borderRadius: 4,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Team Name
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              teamName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isFav ? AppColors.accent : Colors.white,
                                fontWeight: isFav ? FontWeight.w900 : FontWeight.bold,
                                fontSize: 15, // Augmenté de 14 à 15 pour être plus lisible
                              ),
                            ),
                          ),
                          if (isFav) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                          ],
                        ],
                      ),
                    ),

                    // Trend
                    const SizedBox(width: 8),
                    trendWidget,
                    const SizedBox(width: 12),

                    // Odds percentage
                    Text(
                      isEliminated ? '0.0%' : '${odds.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isEliminated ? AppColors.textMuted : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16, // Augmenté de 15 à 16 pour un aspect premium
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                // Linear probability bar
                if (!isEliminated) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      color: AppColors.surface,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (odds / 100.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentLight,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}