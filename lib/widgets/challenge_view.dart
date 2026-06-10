import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../services/prediction_service.dart';
import '../services/firebase_service.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import 'team_flag.dart';

class ChallengeViewWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final bool isLiveMode;
  final Function(String message) showSnackBar;
  final Function(Map<String, String> alerts) onAlertsChanged;
  final Function(String? teamCode) onSupportedTeamChanged;

  const ChallengeViewWidget({
    super.key,
    required this.matches,
    required this.lang,
    this.isLiveMode = true,
    required this.showSnackBar,
    required this.onAlertsChanged,
    required this.onSupportedTeamChanged,
  });

  @override
  State<ChallengeViewWidget> createState() => _ChallengeViewWidgetState();
}

class _ChallengeViewWidgetState extends State<ChallengeViewWidget> {
  // ── État ──────────────────────────────────────────────────────────────────
  PredictionData _userPreds = PredictionData();
  List<FriendGroup> _groups = [];
  bool _isLoading = true;
  String _subTab = 'preds'; // 'preds' | 'groups' | 'leaderboard'
  String _predsFilter = 'group'; // 'group' | 'knockout'
  String? _myUserId;

  // ── Contrôleurs ───────────────────────────────────────────────────────────
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();

  // ── Cycle de vie ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  // ── Données ───────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final preds = await PredictionService.loadPredictionData();
    final groups = await PredictionService.loadChallengeGroups(preds, widget.matches);
    final uid = await WCFirebaseService.getOrCreateUserId();
    setState(() {
      _userPreds = preds;
      _groups = groups;
      _myUserId = uid;
      _isLoading = false;
    });
  }

  Future<void> _syncProfileWithStats(int totalPoints, String? teamCode, String username) async {
    final streak = PredictionService.calculateActiveStreak(_userPreds, widget.matches);
    final guruCount = PredictionService.calculateExactGuessesCount(_userPreds, widget.matches);
    await WCFirebaseService.syncUserProfile(
      username: username,
      supportedTeam: teamCode,
      points: totalPoints,
      streak: streak,
      guruCount: guruCount,
      avatar: _userPreds.avatar,
    );
  }

  Future<void> _updateMatchPred(String matchId, int t1Offset, int t2Offset) async {
    final existing = _userPreds.matchPredictions[matchId];
    int new1 = 0, new2 = 0;
    if (existing != null) {
      new1 = (existing.t1Score + t1Offset).clamp(0, 9);
      new2 = (existing.t2Score + t2Offset).clamp(0, 9);
    } else {
      new1 = t1Offset.clamp(0, 9);
      new2 = t2Offset.clamp(0, 9);
    }
    String? etWinner = existing?.extraTimeWinner;
    bool? pkWinner = existing?.penaltyWinner;
    if (new1 != new2) {
      etWinner = null;
      pkWinner = null;
    }
    setState(() {
      _userPreds.matchPredictions[matchId] = MatchPrediction(
        matchId: matchId, t1Score: new1, t2Score: new2,
        extraTimeWinner: etWinner, penaltyWinner: pkWinner,
      );
    });
    await PredictionService.savePredictionData(_userPreds);
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);
    final groups = await PredictionService.loadChallengeGroups(_userPreds, widget.matches);
    if (mounted) setState(() => _groups = groups);
  }

  Future<void> _updateKnockoutExtras(String matchId, String? etWinner, bool? pkWinner) async {
    final existing = _userPreds.matchPredictions[matchId];
    if (existing == null) return;
    setState(() {
      _userPreds.matchPredictions[matchId] = MatchPrediction(
        matchId: matchId, t1Score: existing.t1Score, t2Score: existing.t2Score,
        extraTimeWinner: etWinner, penaltyWinner: pkWinner,
      );
    });
    await PredictionService.savePredictionData(_userPreds);
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);
    final groups = await PredictionService.loadChallengeGroups(_userPreds, widget.matches);
    if (mounted) setState(() => _groups = groups);
  }

  Future<void> _createNewGroup() async {
    final name = _newGroupController.text.trim();
    if (name.isNotEmpty) {
      await PredictionService.createCustomGroup(name);
      if (!mounted) return;
      _newGroupController.clear();
      Navigator.of(context).pop();
      await _loadData();
      if (!mounted) return;
      widget.showSnackBar(AppTranslations.get(widget.lang, 'groupCreated'));
    }
  }

  Future<void> _joinSharedGroup() async {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      final success = await PredictionService.joinCustomGroup(code);
      if (!mounted) return;
      _codeController.clear();
      Navigator.of(context).pop();
      if (success) {
        await _loadData();
        if (!mounted) return;
        widget.showSnackBar(AppTranslations.get(widget.lang, 'groupJoined'));
      } else {
        widget.showSnackBar(AppTranslations.get(widget.lang, 'groupJoinFailed'));
      }
    }
  }

  Future<void> _shareGroup(FriendGroup grp) async {
    final payload = await PredictionService.getShareLink(grp.code);
    final inviteMessage = AppTranslations.get(widget.lang, 'inviteMessageFull')
        .replaceAll('{groupName}', grp.name)
        .replaceAll('{payload}', payload);
    Clipboard.setData(ClipboardData(text: inviteMessage));
    widget.showSnackBar(AppTranslations.get(widget.lang, 'copied'));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTION DE L'UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    final xpInfo = PredictionService.getXpDetails(totalPoints, widget.lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildProfileStrip(totalPoints, xpInfo),
          _buildTabNav(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ── Profil ────────────────────────────────────────────────────────────────
  Widget _buildProfileStrip(int points, Map<String, dynamic> xp) {
    final streak = PredictionService.calculateActiveStreak(_userPreds, widget.matches);
    final guruCount = PredictionService.calculateExactGuessesCount(_userPreds, widget.matches);
    final hasAvatar = _userPreds.avatar.isNotEmpty;
    final username = _userPreds.username.isEmpty
        ? AppTranslations.get(widget.lang, 'playerDefault')
        : _userPreds.username;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasAvatar
                        ? Image.asset(_userPreds.avatar, width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textDim, size: 24))
                        : Text('L${xp['level']}',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  if (hasAvatar)
                    Positioned(
                      bottom: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Text('L${xp['level']}',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Nom + rang + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(username,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // Badge des points
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$points pts',
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text('${xp['rankName']}',
                            style: const TextStyle(color: AppColors.rankGold, fontSize: 11, fontWeight: FontWeight.w600)),
                        if (streak > 0) ...[
                          const SizedBox(width: 8),
                          _buildBadge('🔥 $streak', AppColors.danger),
                        ],
                        if (guruCount >= kGuruBadgeMinCount) ...[
                          const SizedBox(width: 6),
                          _buildBadge('🔮 Guru', AppColors.purple, textColor: AppColors.purpleLight),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barre d'expérience (XP)
          Stack(
            children: [
              Container(height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: (xp['progress'] as double).clamp(0.0, 1.0),
                child: Container(height: 4,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${xp['xp']} / ${xp['nextLevelXp']} XP',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              Text('${AppTranslations.get(widget.lang, 'levelShort')} ${xp['level']} → ${(xp['level'] as int) + 1}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: bgColor.withValues(alpha: 0.22)),
      ),
      child: Text(label,
          style: TextStyle(color: textColor ?? bgColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ── Navigation par onglets ────────────────────────────────────────────────
  Widget _buildTabNav() {
    final l = widget.lang;
    final tabs = [
      ('preds',       AppTranslations.get(l, 'predsTabShort')),
      ('groups',      AppTranslations.get(l, 'groupsTabShort')),
      ('leaderboard', AppTranslations.get(l, 'leaderboardTabShort')),
    ];
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.border))
      ),
      child: Row(
        children: tabs.map((t) {
          final active = _subTab == t.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (mounted) {
                  setState(() => _subTab = t.$1);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? AppColors.accent : AppColors.textMuted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Routeur de contenu d'onglet ───────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_subTab) {
      case 'preds':       return _buildPredictionsTab();
      case 'groups':      return _buildGroupsTab();
      default:            return _buildLeaderboardTab();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONGLET PRONOSTICS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPredictionsTab() {
    final groupStageMatches = widget.matches.where((m) => !m.isKnockout).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final knockoutMatches = widget.matches.where((m) => m.isKnockout).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final activeList = _predsFilter == 'group' ? groupStageMatches : knockoutMatches;

    return Column(
      children: [
        _buildBoosterPanel(),
        _buildPointsInfoPanel(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _buildFilterButton('group',    AppTranslations.get(widget.lang, 'predGroupStage')),
              const SizedBox(width: 12),
              _buildFilterButton('knockout', AppTranslations.get(widget.lang, 'predKnockout')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: activeList.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == activeList.length) return _buildBonusSummaryCard();
              return _buildPredictionCard(activeList[i]);
            },
          ),
        ),
      ],
    );
  }

  // ── Panneau de Booster ────────────────────────────────────────────────────
  Widget _buildBoosterPanel() {
    WorldCupMatch? boostedMatch;
    if (_userPreds.boosterMatchId != null) {
      final found = widget.matches.where((m) => m.id == _userPreds.boosterMatchId);
      if (found.isNotEmpty) boostedMatch = found.first;
    }

    final bool isLocked = boostedMatch != null &&
        widget.isLiveMode &&
        (boostedMatch.isPlayed || boostedMatch.date.isBefore(DateTime.now()));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: isLocked ? null : _showBoosterPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(
              color: boostedMatch != null ? AppColors.warning : AppColors.borderMid,
              width: boostedMatch != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.rocket_launch,
                  color: boostedMatch != null ? AppColors.warning : AppColors.borderStrong,
                  size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.get(widget.lang, 'boosterLabel'),
                      style: TextStyle(
                        color: boostedMatch != null ? AppColors.warning : AppColors.borderStrong,
                        fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      boostedMatch != null
                          ? '${AppTranslations.getTeam(widget.lang, boostedMatch.t1)} vs ${AppTranslations.getTeam(widget.lang, boostedMatch.t2)} · ${boostedMatch.getFormattedDate(widget.lang)}'
                          : AppTranslations.get(widget.lang, 'noMatchSelected'),
                      style: TextStyle(
                        color: boostedMatch != null ? AppColors.textBody : AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock, color: AppColors.warning, size: 14)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    boostedMatch != null
                        ? AppTranslations.get(widget.lang, 'change')
                        : AppTranslations.get(widget.lang, 'select'),
                    style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBoosterPicker() {
    final unplayed = widget.matches
        .where((m) => !m.isPlayed && m.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.borderMid, borderRadius: BorderRadius.circular(2.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.get(widget.lang, 'chooseBoosterMatch'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (_userPreds.boosterMatchId != null)
                    TextButton(
                      onPressed: () async {
                        setState(() => _userPreds.boosterMatchId = null);
                        await PredictionService.savePredictionData(_userPreds);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: Text(AppTranslations.get(widget.lang, 'clear'),
                          style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: unplayed.length,
                itemBuilder: (_, i) {
                  final m = unplayed[i];
                  final isSelected = _userPreds.boosterMatchId == m.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.warning.withValues(alpha: 0.07) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.warning : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: TeamFlagWidget(code: m.t1, width: 28, height: 18, borderRadius: 4),
                      title: Text(
                        '${AppTranslations.getTeam(widget.lang, m.t1)} vs ${AppTranslations.getTeam(widget.lang, m.t2)}',
                        style: TextStyle(
                          color: isSelected ? AppColors.warning : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(m.getFormattedDate(widget.lang),
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                      trailing: isSelected
                          ? const Icon(Icons.rocket_launch, color: AppColors.warning, size: 18)
                          : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () async {
                        setState(() => _userPreds.boosterMatchId = m.id);
                        await PredictionService.savePredictionData(_userPreds);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _predsFilter == filter;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(color: isSelected ? AppColors.accent : AppColors.textDim),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonRadius),
        side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
      ),
      onSelected: (val) {
        if (val && mounted) {
          setState(() => _predsFilter = filter);
        }
      },
    );
  }

  // ── Carte de pronostic ────────────────────────────────────────────────────
  Widget _buildPredictionCard(WorldCupMatch m) {
    final pred = _userPreds.matchPredictions[m.id];
    final hasPred = pred != null;
    final p1Val = pred?.t1Score ?? 0;
    final p2Val = pred?.t2Score ?? 0;
    final isMatchStarted = m.date.isBefore(DateTime.now());
    final bool isLocked = widget.isLiveMode && (m.isPlayed || isMatchStarted);
    final isBooster = _userPreds.boosterMatchId == m.id;

    int pointsEarned = 0;
    if (m.isPlayed && hasPred) {
      pointsEarned = PredictionService.evaluatePoints(m, pred);
      if (isBooster) pointsEarned *= 2;
    }

    final stageLabel = m.isKnockout
        ? AppTranslations.get(widget.lang, m.stage ?? '')
        : '${AppTranslations.get(widget.lang, 'group')} ${m.group}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
          color: isBooster
              ? AppColors.warning.withValues(alpha: 0.55)
              : (isLocked ? AppColors.border : AppColors.borderMid),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // ── En-tête ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(stageLabel,
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                if (isBooster) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.rocket_launch, size: 13, color: AppColors.warning),
                ],
              ]),
              if (m.isPlayed && hasPred)
                _buildPointsBadge(pointsEarned)
              else
                Text(m.getFormattedDate(widget.lang),
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),

          // ── Zone de score ─────────────────────────────────────────────────
          if (!m.isPlayed) ...[
            GestureDetector(
              onTap: isLocked ? null : () => _updateMatchPred(m.id, p1Val < 9 ? 1 : 0, 0),
              child: _buildTeamInputRow(m.t1, p1Val, hasPred, isLocked,
                  onMinus: () => _updateMatchPred(m.id, -1, 0),
                  onPlus:  () => _updateMatchPred(m.id,  1, 0)),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isLocked ? null : () => _updateMatchPred(m.id, 0, p2Val < 9 ? 1 : 0),
              child: _buildTeamInputRow(m.t2, p2Val, hasPred, isLocked,
                  onMinus: () => _updateMatchPred(m.id, 0, -1),
                  onPlus:  () => _updateMatchPred(m.id, 0,  1)),
            ),
          ] else ...[
            _buildPlayedResultRows(m, pred, hasPred),
          ],

          // ── Sections Prolongations/Tirs au but ────────────────────────────
          if (m.isKnockout && hasPred && !m.isPlayed && pred.t1Score == pred.t2Score)
            _buildETPKPicker(m, pred, isLocked),
          if (m.isKnockout && m.isPlayed && (m.wentToET ?? false))
            _buildETPKResultRow(m, pred),
        ],
      ),
    );
  }

  Widget _buildTeamInputRow(String teamCode, int score, bool hasPred, bool isLocked,
      {required VoidCallback onMinus, required VoidCallback onPlus}) {
    return Row(
      children: [
        TeamFlagWidget(code: teamCode, width: 32, height: 22, borderRadius: 6),
        const SizedBox(width: 12),
        Expanded(
          child: Text(AppTranslations.getTeam(widget.lang, teamCode),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        _buildIncrementButton(onMinus, Icons.remove_circle, isLocked),
        SizedBox(
          width: 36,
          child: Center(
            child: Text(hasPred ? '$score' : '-',
                style: TextStyle(
                  color: hasPred ? Colors.white : AppColors.textDim,
                  fontSize: 20, fontWeight: FontWeight.bold,
                )),
          ),
        ),
        _buildIncrementButton(onPlus, Icons.add_circle, isLocked),
      ],
    );
  }

  Widget _buildIncrementButton(VoidCallback onTap, IconData icon, bool isLocked) {
    if (isLocked) return const SizedBox(width: 36);
    return SizedBox(
      width: 36, height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.accent, size: 28),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildPlayedResultRows(WorldCupMatch m, MatchPrediction? pred, bool hasPred) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(children: [
                TeamFlagWidget(code: m.t1, width: 32, height: 22, borderRadius: 6),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(AppTranslations.getTeam(widget.lang, m.t1),
                      style: const TextStyle(color: AppColors.textBody, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${m.t1Score ?? 0} — ${m.t2Score ?? 0}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Expanded(
                  child: Text(AppTranslations.getTeam(widget.lang, m.t2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.textBody, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 10),
                TeamFlagWidget(code: m.t2, width: 32, height: 22, borderRadius: 6),
              ]),
            ),
          ],
        ),
        if (hasPred) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${AppTranslations.get(widget.lang, 'predictionShort')}: ${pred!.t1Score} — ${pred.t2Score}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPointsBadge(int points) {
    final positive = points > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (positive ? AppColors.accent : AppColors.danger).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(kButtonRadius),
      ),
      child: Text(
        positive ? '+ $points pts' : AppTranslations.get(widget.lang, 'noPoints'),
        style: TextStyle(
          color: positive ? AppColors.accent : AppColors.danger,
          fontWeight: FontWeight.bold, fontSize: 12,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONGLET GROUPES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGroupsTab() {
    FriendGroup? globalGroup;
    final privateGroups = <FriendGroup>[];
    for (final g in _groups) {
      if (g.code == kGlobalGroupCode) {
        globalGroup = g;
      } else {
        privateGroups.add(g);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionLabel(AppTranslations.get(widget.lang, 'globalCup')),
        const SizedBox(height: 8),
        globalGroup != null ? _buildGlobalGroupCard(globalGroup) : _buildGlobalGroupPlaceholder(),
        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(child: _buildSectionLabel(AppTranslations.get(widget.lang, 'myGroups'))),
            _buildActionChip(
              label: AppTranslations.get(widget.lang, 'createShort'),
              color: AppColors.accent, onTap: _showCreateGroupDialog,
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              label: AppTranslations.get(widget.lang, 'joinShort'),
              color: AppColors.textMuted, onTap: _showJoinGroupDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (privateGroups.isEmpty)
          _buildEmptyGroupsState()
        else
          ...privateGroups.map((grp) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPrivateGroupCard(grp),
          )),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: AppColors.borderStrong, fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 0.8,
    ),
  );

  Widget _buildActionChip({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderMid),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildGlobalGroupCard(FriendGroup grp) {
    final myIdx = grp.members.indexWhere((m) => m.isUser);
    final myRank = myIdx >= 0 ? myIdx + 1 : null;
    final topMembers = grp.members.take(3).toList();
    final showUserSeparate = myRank != null && myRank > 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.get(widget.lang, 'globalCupHeader'),
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${grp.members.length} ${AppTranslations.get(widget.lang, 'playersLabel')}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (myRank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('#$myRank',
                          style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                      Text(
                        AppTranslations.get(widget.lang, 'yourRank'),
                        style: const TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...topMembers.asMap().entries.map((e) => _buildMemberRow(e.value, e.key + 1, isGlobal: true)),
          if (showUserSeparate && myIdx < grp.members.length) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text('···', style: TextStyle(color: AppColors.borderStrong, fontSize: 14)),
            ),
            _buildMemberRow(grp.members[myIdx], myRank, isGlobal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalGroupPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_top_rounded, color: AppColors.textDim, size: 16),
        const SizedBox(width: 10),
        Text(
          AppTranslations.get(widget.lang, 'loadingGlobalLeaderboard'),
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
      ]),
    );
  }

  // ── Carte de groupe privé ─────────────────────────────────────────────────
  Widget _buildPrivateGroupCard(FriendGroup grp) {
    final uid = _myUserId;
    final isCreator = uid != null && uid.isNotEmpty && grp.creatorId == uid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(grp.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      '${grp.members.length} ${AppTranslations.get(widget.lang, 'members')}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _shareGroup(grp),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.share_outlined, color: AppColors.accent, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      AppTranslations.get(widget.lang, 'invite'),
                      style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textDim, size: 18),
                color: AppColors.card,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'edit')   _showEditGroupDialog(grp);
                  if (val == 'delete') _showDeleteGroupDialog(grp);
                  if (val == 'leave')  _showLeaveGroupDialog(grp);
                },
                itemBuilder: (_) => [
                  if (isCreator) ...[
                    PopupMenuItem(value: 'edit',
                        child: Text(AppTranslations.get(widget.lang, 'edit'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    PopupMenuItem(value: 'delete',
                        child: Text(AppTranslations.get(widget.lang, 'delete'),
                            style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                  ] else
                    PopupMenuItem(value: 'leave',
                        child: Text(AppTranslations.get(widget.lang, 'leave'),
                            style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...grp.members.asMap().entries.map((e) => _buildMemberRow(e.value, e.key + 1, isGlobal: false)),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsState() {
    return Column(
      children: [
        const SizedBox(height: 4),
        _buildEmptyAction(
          icon: Icons.add,
          iconColor: AppColors.accent,
          title: AppTranslations.get(widget.lang, 'createGroup'),
          subtitle: AppTranslations.get(widget.lang, 'createGroupSubtitle'),
          onTap: _showCreateGroupDialog,
        ),
        const SizedBox(height: 10),
        _buildEmptyAction(
          icon: Icons.group_add_outlined,
          iconColor: AppColors.info,
          title: AppTranslations.get(widget.lang, 'joinGroup'),
          subtitle: AppTranslations.get(widget.lang, 'joinGroupSubtitle'),
          onTap: _showJoinGroupDialog,
        ),
      ],
    );
  }

  Widget _buildEmptyAction({
    required IconData icon, required Color iconColor,
    required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: AppColors.borderMid, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ],
          )),
          const Icon(Icons.chevron_right, color: AppColors.borderStrong, size: 18),
        ]),
      ),
    );
  }

  Widget _buildMemberRow(FriendScore member, int rank, {bool isGlobal = false}) {
    final isUser = member.isUser;
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 15));
    } else if (rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 15));
    } else if (rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 15));
    } else {
      rankWidget = SizedBox(
          width: 22,
          child: Text('#$rank', textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          rankWidget,
          if (isGlobal && isUser) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(AppTranslations.get(widget.lang, 'globalBadge'),
                  style: const TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
          if (!isGlobal && isUser) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(AppTranslations.get(widget.lang, 'groupBadge'),
                  style: const TextStyle(color: AppColors.info, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(width: 10),
          _buildEmblemWidget(member.emblem, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isUser
                  ? '${member.name}${AppTranslations.get(widget.lang, 'meSuffix')}'
                  : member.name,
              style: TextStyle(
                color: isUser ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${member.points} ${AppTranslations.get(widget.lang, 'pointsSuffix')}',
            style: TextStyle(
              color: isUser ? AppColors.accent : AppColors.textMuted,
              fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONGLET CLASSEMENT GENERAL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: WCFirebaseService.getLeaderboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(child: Text(AppTranslations.get(widget.lang, 'leaderboardError'),
              style: const TextStyle(color: AppColors.danger, fontSize: 13)));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final isHidden = data['isHidden'] as bool? ?? false;
          return !isHidden || doc.id == _myUserId;
        }).take(50).toList();

        if (docs.isEmpty) {
          return Center(child: Text(AppTranslations.get(widget.lang, 'noUsers'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 13)));
        }

        final myIdx  = docs.indexWhere((d) => d.id == _myUserId);
        final myRank = myIdx >= 0 ? myIdx + 1 : null;
        final myData = myIdx >= 0 ? docs[myIdx].data() : null;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            if (i == 0) {
              if (myRank == null || myData == null) return const SizedBox.shrink();
              final pts = myData['points'] as int? ?? 0;
              final pct = docs.isNotEmpty ? ((1 - (myRank - 1) / docs.length) * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.22), width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('#$myRank',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16, height: 1)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        AppTranslations.get(widget.lang, 'globalRank'),
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text('$pts pts · top $pct%',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ]),
                  ]),
                ),
              );
            }

            final idx  = i - 1;
            final data = docs[idx].data();
            final username    = data['username'] as String? ?? AppTranslations.get(widget.lang, 'playerDefault');
            final points      = data['points']   as int?    ?? 0;
            final storedAvatar = data['avatar']  as String? ?? '';
            final isMe = docs[idx].id == _myUserId;
            final rank = idx + 1;

            Widget rankWidget;
            if (rank == 1) {
              rankWidget = const Text('🥇', style: TextStyle(fontSize: 16));
            } else if (rank == 2) {
              rankWidget = const Text('🥈', style: TextStyle(fontSize: 16));
            } else if (rank == 3) {
              rankWidget = const Text('🥉', style: TextStyle(fontSize: 16));
            } else {
              rankWidget = SizedBox(
                  width: 22, child: Text('$rank', textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.bold)));
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.accent.withValues(alpha: 0.05) : AppColors.card,
                borderRadius: BorderRadius.circular(kButtonRadius),
                border: Border.all(
                  color: isMe ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
                  width: isMe ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                rankWidget,
                const SizedBox(width: 12),
                if (storedAvatar.isNotEmpty) ...[
                  _buildEmblemWidget(storedAvatar, size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    isMe ? '$username ${AppTranslations.get(widget.lang, 'youSuffix')}' : username,
                    style: TextStyle(
                      color: isMe ? AppColors.accent : Colors.white,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$points ${AppTranslations.get(widget.lang, 'pointsSuffix')}',
                  style: TextStyle(
                    color: isMe ? AppColors.accent : AppColors.textMuted,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSISTANTS / HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPointsInfoPanel() {
    final lang = widget.lang;
    final rows = [
      ('🎯', AppTranslations.get(lang, 'exactGroupPts')),
      ('✅', AppTranslations.get(lang, 'outcomeGroupPts')),
      ('⚽', AppTranslations.get(lang, 'exactKnockoutPts')),
      ('✅', AppTranslations.get(lang, 'outcomeKnockoutPts')),
      ('⚡', AppTranslations.get(lang, 'etBonusPts')),
      ('🥅', AppTranslations.get(lang, 'pkBonusPts')),
      ('🏆', AppTranslations.get(lang, 'championBonusLabel')),
      ('👟', AppTranslations.get(lang, 'goldenBootBonusLabel')),
      ('🚀', AppTranslations.get(lang, 'jokerBonusLabel')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
            title: Text(
              AppTranslations.get(lang, 'pointsInfoTitle'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            iconColor: AppColors.accent,
            collapsedIconColor: AppColors.textDim,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Divider(color: AppColors.border, height: 1, thickness: 1),
              const SizedBox(height: 12),
              ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusSummaryCard() {
    final lang = widget.lang;
    final champion = _userPreds.championCode;
    final scorer   = _userPreds.goldenBootPlayer;

    if (champion == null && scorer == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.account_circle, color: AppColors.textDim, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            AppTranslations.get(lang, 'profileLockPrompt'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          )),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock, color: AppColors.warning, size: 13),
            const SizedBox(width: 6),
            Text(
              AppTranslations.get(lang, 'lockedPredictions'),
              style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ]),
          if (champion != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              TeamFlagWidget(code: champion, width: 20, height: 13, borderRadius: 2),
              const SizedBox(width: 8),
              Expanded(child: Text(AppTranslations.getTeam(lang, champion),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+100 pts',
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
          if (scorer != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Text('👟', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.sports_soccer, color: AppColors.textDim, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(scorer,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+50 pts',
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildETPKPicker(WorldCupMatch m, MatchPrediction pred, bool isLocked) {
    final etWinner  = pred.extraTimeWinner;
    final goesToPK  = pred.penaltyWinner != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 20),
        Row(children: [
          const Icon(Icons.access_time, size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(AppTranslations.get(widget.lang, 'whoWinsET'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('+20 pts', style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _buildETTeamChip(m, m.t1, etWinner, isLocked),
          const SizedBox(width: 8),
          _buildETTeamChip(m, m.t2, etWinner, isLocked),
        ]),
        if (etWinner != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.sports_score, size: 12,
                    color: goesToPK ? AppColors.warning : AppColors.borderStrong),
                const SizedBox(width: 6),
                Text(AppTranslations.get(widget.lang, 'penaltiesLabel'),
                    style: TextStyle(
                      color: goesToPK ? AppColors.warning : AppColors.borderStrong,
                      fontSize: 11, fontWeight: FontWeight.bold,
                    )),
                const SizedBox(width: 6),
                Text('+25 pts', style: TextStyle(color: AppColors.borderStrong, fontSize: 9)),
              ]),
              Switch(
                value: goesToPK,
                activeThumbColor: AppColors.warning,
                activeTrackColor: AppColors.warning.withValues(alpha: 0.2),
                inactiveThumbColor: AppColors.borderStrong,
                inactiveTrackColor: AppColors.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: isLocked ? null : (val) => _updateKnockoutExtras(
                    m.id, etWinner, val ? (etWinner == m.t1) : null),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildETTeamChip(WorldCupMatch m, String teamCode, String? selected, bool isLocked) {
    final isSelected = selected == teamCode;
    return Expanded(
      child: GestureDetector(
        onTap: isLocked ? null : () => _updateKnockoutExtras(m.id, teamCode, null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(kButtonRadius),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamFlagWidget(code: teamCode, width: 16, height: 10, borderRadius: 2),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  AppTranslations.getTeam(widget.lang, teamCode),
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textDim,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildETPKResultRow(WorldCupMatch m, MatchPrediction? pred) {
    final etWinner = m.etWinner;
    if (etWinner == null) return const SizedBox.shrink();
    final predictedET = pred?.extraTimeWinner?.toLowerCase();
    final predictedPK = pred?.penaltyWinner;
    final actualET    = etWinner.toLowerCase();
    final actualPK    = m.pkWinner?.toLowerCase();
    final etCorrect   = predictedET != null && predictedET == actualET;
    final pkCorrect   = m.wentToPK == true && actualPK != null && predictedPK != null &&
        ((predictedPK == true  && actualPK == m.t1.toLowerCase()) ||
            (predictedPK == false && actualPK == m.t2.toLowerCase()));

    Widget chip(bool correct, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (correct ? AppColors.accent : AppColors.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(correct ? Icons.check : Icons.close, size: 9,
            color: correct ? AppColors.accent : AppColors.danger),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(
          color: correct ? AppColors.accent : AppColors.danger,
          fontSize: 9, fontWeight: FontWeight.bold,
        )),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(color: AppColors.border, height: 20),
      Row(children: [
        const Icon(Icons.access_time, size: 11, color: AppColors.textDim),
        const SizedBox(width: 5),
        Expanded(child: Text(
          '${AppTranslations.get(widget.lang, 'extraTimeLabel')}: ${AppTranslations.getTeam(widget.lang, etWinner)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        )),
        if (pred?.extraTimeWinner != null) chip(etCorrect, etCorrect ? '+20' : '0 pts'),
      ]),
      if (m.wentToPK == true && m.pkWinner != null) ...[
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.sports_score, size: 11, color: AppColors.textDim),
          const SizedBox(width: 5),
          Expanded(child: Text(
            '${AppTranslations.get(widget.lang, 'penaltiesLabel')}: ${AppTranslations.getTeam(widget.lang, m.pkWinner!)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          )),
          if (pred?.penaltyWinner != null) chip(pkCorrect, pkCorrect ? '+25' : '0 pts'),
        ]),
      ],
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGUES / MODALES
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditGroupDialog(FriendGroup grp) {
    final editController = TextEditingController(text: grp.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(AppTranslations.get(widget.lang, 'edit'),
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppTranslations.get(widget.lang, 'groupName'),
            hintStyle: const TextStyle(color: AppColors.textDim),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                await PredictionService.editCustomGroup(grp.code, newName);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                await _loadData();
              }
            },
            child: Text(AppTranslations.get(widget.lang, 'save'),
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(FriendGroup grp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(AppTranslations.get(widget.lang, 'delete'),
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Text(
          AppTranslations.get(widget.lang, 'deleteGroupForEveryone'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await PredictionService.deleteCustomGroup(grp.code);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              await _loadData();
            },
            child: Text(AppTranslations.get(widget.lang, 'delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(FriendGroup grp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(AppTranslations.get(widget.lang, 'leaveGroupTitle'),
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Text(
          AppTranslations.get(widget.lang, 'leaveGroupConfirm'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await PredictionService.leaveCustomGroup(grp.code);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              await _loadData();
            },
            child: Text(AppTranslations.get(widget.lang, 'leave'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(AppTranslations.get(widget.lang, 'createGroup'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _newGroupController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppTranslations.get(widget.lang, 'groupName'),
            hintStyle: const TextStyle(color: AppColors.textDim),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { _newGroupController.clear(); Navigator.of(context).pop(); },
            child: Text(AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: _createNewGroup,
            child: Text(AppTranslations.get(widget.lang, 'save'),
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(AppTranslations.get(widget.lang, 'joinGroup'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _codeController,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppTranslations.get(widget.lang, 'enterCode'),
            hintStyle: const TextStyle(color: AppColors.textDim),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { _codeController.clear(); Navigator.of(context).pop(); },
            child: Text(AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: _joinSharedGroup,
            child: Text(AppTranslations.get(widget.lang, 'joinGroup'),
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ── Assistant d'emblème ───────────────────────────────────────────────────
  Widget _buildEmblemWidget(String emblem, {double size = 24}) {
    if (emblem.startsWith('assets/avatars/') || emblem.contains('.png')) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 1)),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(emblem, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(Icons.person, size: size * 0.6, color: AppColors.textDim)),
      );
    }
    return Text(emblem, style: TextStyle(fontSize: size * 0.7));
  }
}