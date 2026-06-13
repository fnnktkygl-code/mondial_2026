import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/team_profile_service.dart';
import '../services/audio_service.dart';
import '../l10n/translations.dart';
import '../app_colors.dart';
import 'team_flag.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WCTeamProfileDialog extends StatefulWidget {
  final String teamCode;
  final String lang;

  const WCTeamProfileDialog({
    super.key,
    required this.teamCode,
    required this.lang,
  });

  static void show(BuildContext context, String teamCode, String lang) {
    final cleanCode = teamCode.toLowerCase().replaceAll('g_', '');
    final isPlaceholder = cleanCode == 'tbd' ||
        cleanCode.contains(RegExp(r'\d')) ||
        (cleanCode.length > 2 && cleanCode != 'sco' && cleanCode != 'gb-sct');

    if (isPlaceholder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This team is yet to be determined.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => WCTeamProfileDialog(
        teamCode: teamCode,
        lang: lang,
      ),
    );
  }

  @override
  State<WCTeamProfileDialog> createState() => _WCTeamProfileDialogState();
}

class _WCTeamProfileDialogState extends State<WCTeamProfileDialog> {
  @override
  Widget build(BuildContext context) {
    final cleanCode = widget.teamCode.toLowerCase().replaceAll('g_', '');
    final bool isRealCountry = WCAudioService.instance.isValidCountry(cleanCode);

    final profile = WCTeamProfileService.getProfile(cleanCode, widget.lang);
    final teamName = AppTranslations.getTeam(widget.lang, cleanCode);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final dialogWidth = isDesktop ? 900.0 : double.infinity;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 40, vertical: 40)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ──────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.cardDark,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'profile_flag_$cleanCode',
                      child: TeamFlagWidget.flag(
                        cleanCode,
                        width: isDesktop ? 90 : 64,
                        height: isDesktop ? 60 : 44,
                        borderRadius: 8,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 32 : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.nickname.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDim, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable Body ──────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: isDesktop
                      ? _buildDesktopBody(profile, isRealCountry, cleanCode)
                      : _buildMobileBody(profile, isRealCountry, cleanCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBody(TeamProfileData profile, bool isRealCountry, String cleanCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppTranslations.get(widget.lang, 'generalInformation')),
        const SizedBox(height: 16),
        _buildGeneralInfoGrid(profile),
        if (profile.worldCupRecord != null) ...[
          const SizedBox(height: 32),
          _buildSectionTitle(AppTranslations.get(widget.lang, 'worldCupRecord')),
          const SizedBox(height: 16),
          _buildWorldCupRecordCard(profile),
          if (profile.worldCupRecord!.funFacts.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(AppTranslations.get(widget.lang, 'triviaTitle')),
            const SizedBox(height: 16),
            _buildFunFactsSection(profile.worldCupRecord!.funFacts),
          ],
        ],
        if (profile.trophies.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionTitle(AppTranslations.get(widget.lang, 'majorTrophies')),
          const SizedBox(height: 16),
          _buildTrophiesList(profile),
        ],
        const SizedBox(height: 32),
        _buildSectionTitle(AppTranslations.get(widget.lang, 'mediaHistory')),
        const SizedBox(height: 16),
        _buildMediaCard(
          imageUrl: profile.imageUrl,
          title: AppTranslations.get(widget.lang, 'teamHistoryProfile'),
          description: AppTranslations.get(widget.lang, 'teamHistoryDesc'),
          onTap: () => _showWebView(profile),
        ),
        if (isRealCountry) ...[
          const SizedBox(height: 32),
          _buildSectionTitle(AppTranslations.get(widget.lang, 'nationalAnthem')),
          const SizedBox(height: 16),
          _buildAnthemPlayerSection(cleanCode),
        ],
      ],
    );
  }

  Widget _buildDesktopBody(TeamProfileData profile, bool isRealCountry, String cleanCode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: General Info & Media
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(AppTranslations.get(widget.lang, 'generalInformation')),
              const SizedBox(height: 16),
              _buildGeneralInfoGrid(profile),
              if (profile.worldCupRecord != null) ...[
                const SizedBox(height: 32),
                _buildSectionTitle(AppTranslations.get(widget.lang, 'worldCupRecord')),
                const SizedBox(height: 16),
                _buildWorldCupRecordCard(profile),
                if (profile.worldCupRecord!.funFacts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(AppTranslations.get(widget.lang, 'triviaTitle')),
                  const SizedBox(height: 16),
                  _buildFunFactsSection(profile.worldCupRecord!.funFacts),
                ],
              ],
              const SizedBox(height: 40),
              _buildSectionTitle(AppTranslations.get(widget.lang, 'mediaHistory')),
              const SizedBox(height: 16),
              _buildMediaCard(
                imageUrl: profile.imageUrl,
                title: AppTranslations.get(widget.lang, 'teamHistoryProfile'),
                description: AppTranslations.get(widget.lang, 'teamHistoryDesc'),
                onTap: () => _showWebView(profile),
                isDesktop: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right Column: Trophies & Anthem
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.trophies.isNotEmpty) ...[
                _buildSectionTitle(AppTranslations.get(widget.lang, 'majorTrophies')),
                const SizedBox(height: 16),
                _buildTrophiesList(profile),
                const SizedBox(height: 40),
              ],
              if (isRealCountry) ...[
                _buildSectionTitle(AppTranslations.get(widget.lang, 'nationalAnthem')),
                const SizedBox(height: 16),
                _buildAnthemPlayerSection(cleanCode),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showWebView(TeamProfileData profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        clipBehavior: Clip.antiAlias,
        child: WCEmbeddedWebView(
          url: profile.profileUrl,
          title: AppTranslations.get(widget.lang, 'teamHistoryInfo'),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoGrid(TeamProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.shield_rounded,
            label: AppTranslations.get(widget.lang, 'emblem'),
            value: profile.symbol,
          ),
          _buildInfoRow(
            icon: Icons.leaderboard_rounded,
            label: AppTranslations.get(widget.lang, 'fifaRanking'),
            value: profile.fifaRanking == 999
                ? (AppTranslations.get(widget.lang, 'unranked'))
                : '#${profile.fifaRanking}',
          ),
          _buildInfoRow(
            icon: Icons.sports_soccer_rounded,
            label: AppTranslations.get(widget.lang, 'appearances'),
            value: '${profile.appearances} ${AppTranslations.get(widget.lang, 'finalPhases')}',
          ),
          _buildInfoRow(
            icon: Icons.military_tech_rounded,
            label: AppTranslations.get(widget.lang, 'bestFinish'),
            value: profile.bestFinish,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWorldCupRecordCard(TeamProfileData profile) {
    final record = profile.worldCupRecord;
    if (record == null) return const SizedBox.shrink();

    final hasAppearanceInfo = record.firstWorldCup != null && record.participationRank != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAppearanceInfo) ...[
            // First WC + Appearances row
            Row(
              children: [
                Expanded(
                  child: _buildRecordHighlight(
                    label: AppTranslations.get(widget.lang, 'firstWorldCup'),
                    value: record.firstWorldCup.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildRecordHighlight(
                    label: AppTranslations.get(widget.lang, 'appearances'),
                    value: record.participations.toString(),
                    caption: record.participationRankLabel,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.border, height: 1),
            ),
          ],
          Text(
            AppTranslations.get(widget.lang, 'worldCupRecord').toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'playedShort'), record.played, Colors.white)),
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'winsShort'), record.wins, Colors.greenAccent)),
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'drawsShort'), record.draws, Colors.amberAccent)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'lossesShort'), record.losses, Colors.redAccent)),
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'goalsScoredShort'), record.goalsFor, Colors.white)),
              Expanded(child: _buildRecordStat(AppTranslations.get(widget.lang, 'goalsConcededShort'), record.goalsAgainst, AppColors.textDim)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordHighlight({required String label, required String value, String? caption}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            if (caption != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  caption,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRecordStat(String label, int value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTrophiesList(TeamProfileData profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: profile.trophies.map((trophy) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              _buildTrophyBadge(trophy),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  trophy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMediaCard({
    required String? imageUrl,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDesktop = false,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final bool isLocalAsset = hasImage && imageUrl.startsWith('assets/');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          highlightColor: AppColors.accent.withValues(alpha: 0.1),
          splashColor: AppColors.accent.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: isDesktop ? 260 : 180,
                color: AppColors.cardDark,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasImage) ...[
                      isLocalAsset
                          ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                          : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      ),
                    ] else
                      _buildImagePlaceholder(),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accent, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunFactsSection(List<String> facts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: facts.map((fact) {
          final bool isLast = facts.last == fact;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fact,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.accent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.cardDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_rounded, color: AppColors.textDim, size: 48),
            const SizedBox(height: 12),
            Text(
              AppTranslations.get(widget.lang, 'previewNotAvailable'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyBadge(String trophy) {
    final lower = trophy.toLowerCase();
    String? assetPath;
    String? fallbackAssetPath;
    IconData fallbackIcon = Icons.emoji_events_rounded;
    Color fallbackColor = Colors.amber;

    if (lower.contains('coupe du monde') || lower.contains('world cup') || lower.contains('copa mondial')) {
      if (lower.contains('u20') || lower.contains('u-20')) {
        assetPath = 'assets/badges/world_cup_u20.png';
      } else if (lower.contains('u17') || lower.contains('u-17')) {
        assetPath = 'assets/badges/world_cup_u17.png';
      } else {
        assetPath = 'assets/badges/world_cup.png';
      }
      fallbackAssetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('copa américa') || lower.contains('copa america')) {
      assetPath = 'assets/badges/copa_america.png';
      fallbackAssetPath = 'assets/badges/conmebol.png';
    } else if (lower.contains('euro espoirs') || lower.contains('under-21') || lower.contains('sub-21')) {
      assetPath = 'assets/badges/euro_u21.png';
      fallbackAssetPath = 'assets/badges/uefa.png';
    } else if (lower.contains('euro u19') || lower.contains('under-19') || lower.contains('sub-19')) {
      assetPath = 'assets/badges/euro_u19.png';
      fallbackAssetPath = 'assets/badges/uefa.png';
    } else if (lower.contains('euro u17') || lower.contains('under-17') || lower.contains('sub-17')) {
      assetPath = 'assets/badges/euro_u17.png';
      fallbackAssetPath = 'assets/badges/uefa.png';
    } else if (lower.contains('euro') || lower.contains('europeo')) {
      assetPath = 'assets/badges/euro.png';
      fallbackAssetPath = 'assets/badges/uefa.png';
    } else if (lower.contains('ligue des nations de l\'uefa') || lower.contains('liga de naciones de la uefa') || (lower.contains('nations league') && !lower.contains('concacaf'))) {
      assetPath = 'assets/badges/uefa_nations_league.png';
      fallbackAssetPath = 'assets/badges/uefa.png';
    } else if (lower.contains('afrique des nations') || lower.contains('africa cup') || lower.contains('copa africana')) {
      if (lower.contains('u20') || lower.contains('u-20')) {
        assetPath = 'assets/badges/afcon_u20.png';
      } else if (lower.contains('u17') || lower.contains('u-17')) {
        assetPath = 'assets/badges/afcon_u17.png';
      } else if (lower.contains('u23') || lower.contains('u-23')) {
        assetPath = 'assets/badges/afcon_u23.png';
      } else {
        assetPath = 'assets/badges/afcon.png';
      }
      fallbackAssetPath = 'assets/badges/caf.png';
    } else if (lower.contains('chan') || lower.contains('championnat d\'afrique des nations') || lower.contains('campeonato africano de naciones')) {
      assetPath = 'assets/badges/chan.png';
      fallbackAssetPath = 'assets/badges/caf.png';
    } else if (lower.contains('asie') || lower.contains('asian cup') || lower.contains('copa asiática') || lower.contains('champ. d\'asie') || lower.contains('championnat d\'asie')) {
      if (lower.contains('u20') || lower.contains('u-20') || lower.contains('u19') || lower.contains('u-19')) {
        assetPath = 'assets/badges/asian_cup_u20.png';
      } else if (lower.contains('u17') || lower.contains('u-17')) {
        assetPath = 'assets/badges/asian_cup_u17.png';
      } else if (lower.contains('u23') || lower.contains('u-23')) {
        assetPath = 'assets/badges/asian_cup_u23.png';
      } else {
        assetPath = 'assets/badges/asian_cup.png';
      }
      fallbackAssetPath = 'assets/badges/afc.png';
    } else if (lower.contains('confédérations') || lower.contains('confederations')) {
      assetPath = 'assets/badges/confederations.png';
    } else if (lower.contains('or de la concacaf') || lower.contains('gold cup') || lower.contains('copa de oro')) {
      assetPath = 'assets/badges/gold_cup.png';
      fallbackAssetPath = 'assets/badges/concacaf.png';
    } else if (lower.contains('nations league concacaf') || lower.contains('ligue des nations concacaf') || lower.contains('liga de naciones de la concacaf')) {
      assetPath = 'assets/badges/concacaf_nations_league.png';
      fallbackAssetPath = 'assets/badges/concacaf.png';
    } else if (lower.contains('ofc') || lower.contains('océanie') || lower.contains('oceania')) {
      assetPath = 'assets/badges/ofc_nations_cup.png';
      fallbackAssetPath = 'assets/badges/ofc.png';
    } else if (lower.contains('arabe') || lower.contains('arab cup') || lower.contains('árabe')) {
      assetPath = 'assets/badges/arab_cup.png';
      fallbackAssetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('olympique') || lower.contains('olympic') || lower.contains('olímpica')) {
      assetPath = 'assets/badges/olympics.png';
      fallbackIcon = Icons.stars_rounded;
      fallbackColor = Colors.blue;
    }

    return _buildBadgeWithFallback(assetPath, fallbackAssetPath, fallbackIcon, fallbackColor);
  }

  Widget _buildBadgeWithFallback(
    String? primaryPath,
    String? secondaryPath,
    IconData fallbackIcon,
    Color fallbackColor,
  ) {
    if (primaryPath == null) {
      return _buildSecondaryBadge(secondaryPath, fallbackIcon, fallbackColor);
    }

    return Image.asset(
      primaryPath,
      width: 36,
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildSecondaryBadge(secondaryPath, fallbackIcon, fallbackColor);
      },
    );
  }

  Widget _buildSecondaryBadge(
    String? path,
    IconData fallbackIcon,
    Color fallbackColor,
  ) {
    if (path == null) {
      return Icon(fallbackIcon, color: fallbackColor, size: 32);
    }
    return Image.asset(
      path,
      width: 36,
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: fallbackColor, size: 32);
      },
    );
  }

  Widget _buildAnthemPlayerSection(String code) {
    final audio = WCAudioService.instance;

    return ValueListenableBuilder<String?>(
      valueListenable: audio.currentPlayingTeamCode,
      builder: (context, playingCode, _) {
        final bool isCurrent = playingCode == code;

        return ValueListenableBuilder<PlayerState>(
          valueListenable: audio.playerState,
          builder: (context, state, _) {
            final bool isPlaying = isCurrent && state == PlayerState.playing;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isCurrent ? AppColors.accent : AppColors.border, width: 1.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: audio.isLoading,
                        builder: (context, loading, _) {
                          if (isCurrent && loading) {
                            return const SizedBox(
                              width: 50,
                              height: 50,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          }
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(14),
                              backgroundColor: isPlaying ? Colors.amber : AppColors.accent,
                              foregroundColor: AppColors.surface,
                              elevation: 4,
                            ),
                            onPressed: () => audio.playAnthem(code),
                            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get(widget.lang, 'nationalAnthemStream'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isCurrent
                                  ? (isPlaying
                                  ? (AppTranslations.get(widget.lang, 'nowPlaying'))
                                  : (AppTranslations.get(widget.lang, 'paused')))
                                  : (AppTranslations.get(widget.lang, 'readyToListen')),
                              style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      SoundwaveVisualizer(isPlaying: isPlaying),
                    ],
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 20),
                    ValueListenableBuilder<Duration>(
                      valueListenable: audio.duration,
                      builder: (context, dur, _) {
                        return ValueListenableBuilder<Duration>(
                          valueListenable: audio.position,
                          builder: (context, pos, _) {
                            final double maxVal = dur.inMilliseconds.toDouble();
                            final double currVal = pos.inMilliseconds.toDouble().clamp(0.0, maxVal);
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: AppColors.accent,
                                    inactiveTrackColor: AppColors.borderStrong,
                                    thumbColor: AppColors.accent,
                                  ),
                                  child: Slider(
                                    min: 0.0,
                                    max: maxVal > 0.0 ? maxVal : 1.0,
                                    value: currVal,
                                    onChanged: (val) => audio.seek(Duration(milliseconds: val.toInt())),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(pos), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text(_formatDuration(dur), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, color: AppColors.textMuted, size: 16),
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: audio.volume,
                          builder: (context, vol, _) {
                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: AppColors.textDim,
                                inactiveTrackColor: AppColors.borderStrong,
                                thumbColor: AppColors.textDim,
                              ),
                              child: Slider(
                                min: 0.0,
                                max: 1.0,
                                value: vol,
                                onChanged: (val) => audio.setVolume(val),
                              ),
                            );
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final int min = d.inMinutes;
    final int sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

// ─── Soundwave visualizer ────────────────────────────────────────────────────

class SoundwaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  const SoundwaveVisualizer({super.key, required this.isPlaying});

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [12, 22, 16, 26, 10, 20, 14, 24];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _heights.length,
              (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _heights.length,
                (i) {
              final scale = 0.3 + 0.7 * sin((_controller.value * 2 * pi) + (i * 0.4)).abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: (_heights[i] * scale).clamp(4.0, 26.0),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Embedded WebView ────────────────────────────────────────────────────────

class WCEmbeddedWebView extends StatefulWidget {
  final String url;
  final String title;

  const WCEmbeddedWebView({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WCEmbeddedWebView> createState() => _WCEmbeddedWebViewState();
}

class _WCEmbeddedWebViewState extends State<WCEmbeddedWebView> {
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.cardDark,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                onPressed: _canGoBack ? () async => _webViewController?.goBack() : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
                onPressed: _canGoForward ? () async => _webViewController?.goForward() : null,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                onPressed: () async => _webViewController?.reload(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        if (_progress < 1.0)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 4,
          ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllowFullscreen: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              supportZoom: true,
              builtInZoomControls: true,
              displayZoomControls: false,
            ),
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.CANCEL;
              final host = uri.host.toLowerCase();
              if (host == 'fifa.com' || host.endsWith('.fifa.com')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) async {
              final back = await controller.canGoBack();
              final forward = await controller.canGoForward();
              if (mounted) setState(() { _canGoBack = back; _canGoForward = forward; });
            },
            onLoadStop: (controller, url) async {
              final back = await controller.canGoBack();
              final forward = await controller.canGoForward();
              if (mounted) setState(() { _progress = 1.0; _canGoBack = back; _canGoForward = forward; });
            },
            onProgressChanged: (controller, progress) {
              if (mounted) setState(() => _progress = progress / 100.0);
            },
          ),
        ),
      ],
    );
  }
}