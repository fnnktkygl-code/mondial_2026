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
  PredictionData _userPreds = PredictionData();
  List<FriendGroup> _groups = [];
  bool _isLoading = true;
  String _subTab = 'preds'; // 'preds', 'groups', 'bonus'
  String _predsFilter = 'group'; // 'group' or 'knockout'
  String? _myUserId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newGroupController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final preds = await PredictionService.loadPredictionData();
    final groups = await PredictionService.loadChallengeGroups(preds, widget.matches);
    final uid = await WCFirebaseService.getOrCreateUserId();

    setState(() {
      _userPreds = preds;
      _groups = groups;
      _nameController.text = preds.username;
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
    int new1 = 0;
    int new2 = 0;

    if (existing != null) {
      new1 = (existing.t1Score + t1Offset).clamp(0, 9);
      new2 = (existing.t2Score + t2Offset).clamp(0, 9);
    } else {
      new1 = t1Offset.clamp(0, 9);
      new2 = t2Offset.clamp(0, 9);
    }

    // Clear ET/PK predictions if the new 90-min score is no longer a draw
    String? etWinner = existing?.extraTimeWinner;
    bool? pkWinner = existing?.penaltyWinner;
    if (new1 != new2) {
      etWinner = null;
      pkWinner = null;
    }

    setState(() {
      _userPreds.matchPredictions[matchId] = MatchPrediction(
        matchId: matchId,
        t1Score: new1,
        t2Score: new2,
        extraTimeWinner: etWinner,
        penaltyWinner: pkWinner,
      );
    });

    await PredictionService.savePredictionData(_userPreds);
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);

    // Reload group scores dynamically
    final groups = await PredictionService.loadChallengeGroups(_userPreds, widget.matches);
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }

  /// Saves the ET/PK winner prediction for a knockout match without touching the score.
  Future<void> _updateKnockoutExtras(String matchId, String? etWinner, bool? pkWinner) async {
    final existing = _userPreds.matchPredictions[matchId];
    if (existing == null) return;

    setState(() {
      _userPreds.matchPredictions[matchId] = MatchPrediction(
        matchId: matchId,
        t1Score: existing.t1Score,
        t2Score: existing.t2Score,
        extraTimeWinner: etWinner,
        penaltyWinner: pkWinner,
      );
    });

    await PredictionService.savePredictionData(_userPreds);
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);
    final groups = await PredictionService.loadChallengeGroups(_userPreds, widget.matches);
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }





  Future<void> _createNewGroup() async {
    final name = _newGroupController.text.trim();
    if (name.isNotEmpty) {
      await PredictionService.createCustomGroup(name);
      _newGroupController.clear();
      Navigator.of(context).pop();
      await _loadData();
      widget.showSnackBar(AppTranslations.get(widget.lang, 'groupCreated'));
    }
  }

  Future<void> _joinSharedGroup() async {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      final success = await PredictionService.joinCustomGroup(code);
      _codeController.clear();
      Navigator.of(context).pop();
      if (success) {
        await _loadData();
        widget.showSnackBar(AppTranslations.get(widget.lang, 'groupJoined'));
      } else {
        widget.showSnackBar(AppTranslations.get(widget.lang, 'groupJoinFailed'));
      }
    }
  }

  void _shareGroup(FriendGroup grp) {
    final token = grp.inviteToken;
    if (token == null || token.isEmpty) return; // Cannot share global group

    final payload = PredictionService.generateSharePayload(grp.code, token);
    final inviteMessage = AppTranslations.get(widget.lang, 'inviteMessageFull').replaceAll('{groupName}', grp.name).replaceAll('{payload}', payload);

    Clipboard.setData(ClipboardData(text: inviteMessage));
    widget.showSnackBar(AppTranslations.get(widget.lang, 'copied'));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    final xpInfo = PredictionService.getXpDetails(totalPoints, widget.lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Profile & XP Banner
          _buildProfileBanner(totalPoints, xpInfo),

          // 2. Navigation Segments
          _buildSubTabSelector(),

          // 3. Active Screen Content
          Expanded(
            child: _buildSubTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBanner(int points, Map<String, dynamic> xp) {
    final streak = PredictionService.calculateActiveStreak(_userPreds, widget.matches);
    final guruCount = PredictionService.calculateExactGuessesCount(_userPreds, widget.matches);
    final hasAvatar = _userPreds.avatar.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Avatar / XP badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kCardRadius),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasAvatar
                    ? Image.asset(
                        _userPreds.avatar,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textDim, size: 28),
                      )
                    : Text(
                        'L${xp['level']}',
                        style: const TextStyle(
                            color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
              ),
              if (hasAvatar)
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      'L${xp['level']}',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Username & XP Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userPreds.username.isEmpty
                      ? (AppTranslations.get(widget.lang, 'player'))
                      : _userPreds.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${xp['rankName']}',
                  style: const TextStyle(color: AppColors.rankGold, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: xp['progress'] as double,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${xp['xp']} / ${xp['nextLevelXp']} XP',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    Text(
                      '$points pts',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.danger, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      AppTranslations.get(widget.lang, 'favTeamLabel'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _userPreds.supportedTeam == null
                          ? Text(
                              AppTranslations.get(widget.lang, 'none'),
                              style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontStyle: FontStyle.italic),
                            )
                          : Row(
                              children: [
                                TeamFlagWidget(
                                  code: _userPreds.supportedTeam!,
                                  width: 24,
                                  height: 16,
                                  borderRadius: 4,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppTranslations.getTeam(widget.lang, _userPreds.supportedTeam!),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                if (streak > 0 || guruCount >= kGuruBadgeMinCount) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (streak > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '🔥 $streak',
                            style: const TextStyle(color: AppColors.danger, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (guruCount >= kGuruBadgeMinCount) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '🔮 Guru ($guruCount)',
                            style: const TextStyle(color: AppColors.purpleLight, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSubTabSelector() {
    final l = widget.lang;
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          _buildSubTabButton('preds',       AppTranslations.get(l, 'predsTabShort'),    Icons.sports_soccer),
          const SizedBox(width: 6),
          _buildSubTabButton('groups',      AppTranslations.get(l, 'groupsTabShort'),   Icons.groups),
          const SizedBox(width: 6),
          _buildSubTabButton('leaderboard', AppTranslations.get(l, 'leaderboardTabShort'), Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String tab, String label, IconData icon) {
    final isSelected = _subTab == tab;
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 14, color: isSelected ? Colors.black : AppColors.textMuted),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.black : Colors.white,
          backgroundColor: isSelected ? AppColors.accent : AppColors.card,
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
            side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
          ),
        ),
        onPressed: () {
          setState(() {
            _subTab = tab;
          });
        },
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: WCFirebaseService.getLeaderboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppTranslations.get(widget.lang, 'leaderboardError'),
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final isHidden = data['isHidden'] as bool? ?? false;
          final isMe = doc.id == _myUserId;
          return !isHidden || isMe;
        }).take(50).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              AppTranslations.get(widget.lang, 'noUsers'),
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final username = data['username'] as String? ?? 'Joueur';
            final points = data['points'] as int? ?? 0;
            final supportedTeam = data['supportedTeam'] as String?;
            final storedAvatar = data['avatar'] as String? ?? '';
            final isMe = docs[index].id == _myUserId;

            final rank = index + 1;
            Widget rankWidget;
            if (rank == 1) {
              rankWidget = const Text('🥇', style: TextStyle(fontSize: 16));
            } else if (rank == 2) {
              rankWidget = const Text('🥈', style: TextStyle(fontSize: 16));
            } else if (rank == 3) {
              rankWidget = const Text('🥉', style: TextStyle(fontSize: 16));
            } else {
              rankWidget = Container(
                width: 22,
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.border : AppColors.card,
                borderRadius: BorderRadius.circular(kButtonRadius),
                border: Border.all(
                  color: isMe ? AppColors.accent : AppColors.border,
                  width: isMe ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubTabContent() {
    if (_subTab == 'preds') {
      return _buildPredictionsTab();
    } else if (_subTab == 'groups') {
      return _buildGroupsTab();
    } else {
      return _buildLeaderboardTab();
    }
  }

  // ================= PREDICTIONS TAB =================
  Widget _buildPredictionsTab() {
    final groupStageMatches = widget.matches.where((m) => !m.isKnockout).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final knockoutMatches = widget.matches.where((m) => m.isKnockout).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final activeList = _predsFilter == 'group' ? groupStageMatches : knockoutMatches;

    return Column(
      children: [
        // Points breakdown info panel (collapsible)
        _buildPointsInfoPanel(),

        // Sub-filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterButton('group', AppTranslations.get(widget.lang, 'predGroupStage')),
              const SizedBox(width: 12),
              _buildFilterButton('knockout', AppTranslations.get(widget.lang, 'predKnockout')),
            ],
          ),
        ),

        // Match list — bonus summary card appended as last item
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: activeList.length + 1,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (c, i) {
              if (i == activeList.length) return _buildBonusSummaryCard();
              return _buildPredictionCard(activeList[i]);
            },
          ),
        ),
      ],
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
        if (val) {
          setState(() {
            _predsFilter = filter;
          });
        }
      },
    );
  }

  Widget _buildPredictionCard(WorldCupMatch m) {
    final t1EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, m.t1);
    final t2EmblemName = AppTranslations.getTeamWithEmblem(widget.lang, m.t2);

    final pred = _userPreds.matchPredictions[m.id];
    final hasPred = pred != null;

    final p1Val = pred?.t1Score ?? 0;
    final p2Val = pred?.t2Score ?? 0;

    final bool isMatchStarted = m.date.isBefore(DateTime.now());
    final bool isLocked = widget.isLiveMode && (m.isPlayed || isMatchStarted);

    int pointsEarned = 0;
    if (m.isPlayed && hasPred) {
      pointsEarned = PredictionService.evaluatePoints(m, pred);
      if (_userPreds.boosterMatchId == m.id) {
        pointsEarned *= 2;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
          color: isLocked ? AppColors.border : AppColors.borderMid,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header info (stage / group / date)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    m.isKnockout ? AppTranslations.get(widget.lang, m.stage ?? '') : '${AppTranslations.get(widget.lang, 'group')} ${m.group}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (_userPreds.boosterMatchId == m.id) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.rocket_launch, size: 14, color: AppColors.warning),
                  ],
                ],
              ),
              Text(
                m.getFormattedDate(widget.lang),
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Redesigned Stack Score Prediction Interface
          // Team 1 Row
          GestureDetector(
            onTap: isLocked ? null : () => _updateMatchPred(m.id, p1Val == 0 && p2Val == 0 ? 1 : (p1Val < 9 ? 1 : 0), 0),
            child: Row(
              children: [
                TeamFlagWidget(
                  code: m.t1,
                  width: 32,
                  height: 22,
                  borderRadius: 6,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.getTeam(widget.lang, m.t1),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIncrementButton(m.id, -1, 0, isLocked),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        hasPred ? '$p1Val' : '-',
                        style: TextStyle(
                          color: hasPred ? Colors.white : AppColors.textDim,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildIncrementButton(m.id, 1, 0, isLocked),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Team 2 Row
          GestureDetector(
            onTap: isLocked ? null : () => _updateMatchPred(m.id, 0, p1Val == 0 && p2Val == 0 ? 1 : (p2Val < 9 ? 1 : 0)),
            child: Row(
              children: [
                TeamFlagWidget(
                  code: m.t2,
                  width: 32,
                  height: 22,
                  borderRadius: 6,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.getTeam(widget.lang, m.t2),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIncrementButton(m.id, 0, -1, isLocked),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        hasPred ? '$p2Val' : '-',
                        style: TextStyle(
                          color: hasPred ? Colors.white : AppColors.textDim,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildIncrementButton(m.id, 0, 1, isLocked),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actual match result & Points badge
          if (m.isPlayed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppTranslations.get(widget.lang, 'stats')}: ${m.t1Score} - ${m.t2Score}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pointsEarned > 0
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(kButtonRadius),
                  ),
                  child: Text(
                    pointsEarned > 0
                        ? '+ $pointsEarned PTS'
                        : AppTranslations.get(widget.lang, 'noPoints'),
                    style: TextStyle(
                      color: pointsEarned > 0 ? AppColors.accent : AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

          // ── ET/PK prediction ────────────────────────────────────────────────────────────
          // Show ET/PK picker when user predicts a draw in a knockout match
          if (m.isKnockout && hasPred && !m.isPlayed && pred!.t1Score == pred.t2Score)
            _buildETPKPicker(m, pred, isLocked),

          // Show ET/PK actual result after a knockout that went to extra time
          if (m.isKnockout && m.isPlayed && (m.wentToET ?? false))
            _buildETPKResultRow(m, pred),

          // Booster selector for unplayed matches
          if (!isLocked) ...[
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      size: 14,
                      color: _userPreds.boosterMatchId == m.id ? AppColors.warning : AppColors.borderStrong,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppTranslations.get(widget.lang, 'boosterLabel'),
                      style: TextStyle(
                        color: _userPreds.boosterMatchId == m.id ? AppColors.warning : AppColors.borderStrong,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _userPreds.boosterMatchId == m.id,
                  activeThumbColor: AppColors.warning,
                  activeTrackColor: AppColors.warning.withValues(alpha: 0.2),
                  inactiveThumbColor: AppColors.borderStrong,
                  inactiveTrackColor: AppColors.border,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) async {
                    setState(() {
                      if (val) {
                        _userPreds.boosterMatchId = m.id;
                      } else {
                        if (_userPreds.boosterMatchId == m.id) {
                          _userPreds.boosterMatchId = null;
                        }
                      }
                    });

                    await PredictionService.savePredictionData(_userPreds);
                    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
                    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);
                  },
                ),
              ],
            ),
          ] else if (_userPreds.boosterMatchId == m.id) ...[
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rocket_launch, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  AppTranslations.get(widget.lang, 'boosterActive'),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncrementButton(String matchId, int t1Offset, int t2Offset, bool isMatchPlayed) {
    if (isMatchPlayed) return const SizedBox(width: 36);

    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          (t1Offset > 0 || t2Offset > 0) ? Icons.add_circle : Icons.remove_circle,
          color: AppColors.accent,
          size: 28,
        ),
        onPressed: () => _updateMatchPred(matchId, t1Offset, t2Offset),
      ),
    );
  }

  // ================= GROUPS TAB =================
  Widget _buildGroupsTab() {
    return Column(
      children: [
        // Action Buttons: Create / Join
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_box, size: 14, color: Colors.black),
                  label: Text(AppTranslations.get(widget.lang, 'createGroup'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                  ),
                  onPressed: _showCreateGroupDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_add, size: 14, color: Colors.white),
                  label: Text(AppTranslations.get(widget.lang, 'joinGroup'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kButtonRadius),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onPressed: _showJoinGroupDialog,
                ),
              ),
            ],
          ),
        ),

        // List of groups
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: _groups.length,
            separatorBuilder: (c, i) => const SizedBox(height: 20),
            itemBuilder: (c, i) {
              final grp = _groups[i];
              return _buildGroupCard(grp);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(FriendGroup grp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group title & share button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grp.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${grp.code}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (grp.code != 'GLOBAL-2026') ...[
                IconButton(
                  icon: const Icon(Icons.share, color: AppColors.accent, size: 18),
                  onPressed: () => _shareGroup(grp),
                ),
                if (grp.creatorId == _myUserId && _myUserId != null && _myUserId!.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textDim, size: 18),
                    color: AppColors.card,
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditGroupDialog(grp);
                      } else if (val == 'delete') {
                        _showDeleteGroupDialog(grp);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppTranslations.get(widget.lang, 'edit') ?? 'Edit', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppTranslations.get(widget.lang, 'delete') ?? 'Delete', style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: AppColors.danger, size: 18),
                    onPressed: () => _showLeaveGroupDialog(grp),
                  ),
              ],
            ],
          ),
          const Divider(color: AppColors.border, height: 24),

          // Leaderboard members list
          ...grp.members.map((member) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Avatar/emblem
                  _buildEmblemWidget(member.emblem, size: 24),
                  const SizedBox(width: 12),

                  // Name
                  Expanded(
                    child: Text(
                      member.name,
                      style: TextStyle(
                        color: member.isUser ? AppColors.accent : Colors.white,
                        fontWeight: member.isUser ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Points
                  Text(
                    '${member.points} ${AppTranslations.get(widget.lang, 'pointsSuffix')}',
                    style: TextStyle(
                      color: member.isUser ? AppColors.accent : AppColors.textMuted,
                      fontWeight: member.isUser ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // Helper widgets for the Pronos tab (points panel, bonus card, ET/PK)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Collapsible points breakdown panel shown at the top of the Pronos tab.
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
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
            title: Text(
              AppTranslations.get(lang, 'pointsInfoTitle'),
              style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            iconColor: AppColors.accent,
            collapsedIconColor: AppColors.textDim,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            children: rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Text(row.$1, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  /// Compact locked-predictions card appended at the end of the match list.
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
          Expanded(
            child: Text(
              AppTranslations.get(lang, 'profileLockPrompt2'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
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
              Expanded(
                child: Text(
                  AppTranslations.getTeam(lang, champion),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+100 pts', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
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
              Expanded(
                child: Text(
                  scorer,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+50 pts', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  /// ET/PK team picker shown on knockout cards when user predicts a draw.
  Widget _buildETPKPicker(WorldCupMatch m, MatchPrediction pred, bool isLocked) {
    final etWinner = pred.extraTimeWinner;
    final goesToPK = pred.penaltyWinner != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 20),
        Row(children: [
          const Icon(Icons.access_time, size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            AppTranslations.get(widget.lang, 'whoWinsET'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
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
                Text(
                  AppTranslations.get(widget.lang, 'penaltiesLabel'),
                  style: TextStyle(
                    color: goesToPK ? AppColors.warning : AppColors.borderStrong,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  m.id,
                  etWinner,
                  val ? (etWinner == m.t1) : null,
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays the actual ET/PK result and whether the user's prediction was correct.
  Widget _buildETPKResultRow(WorldCupMatch m, MatchPrediction? pred) {
    if (m.etWinner == null) return const SizedBox.shrink();

    final predictedET = pred?.extraTimeWinner?.toLowerCase();
    final predictedPK = pred?.penaltyWinner;
    final actualET    = m.etWinner!.toLowerCase();
    final actualPK    = m.pkWinner?.toLowerCase();

    final etCorrect = predictedET != null && predictedET == actualET;
    final pkCorrect = m.wentToPK == true &&
        actualPK != null &&
        predictedPK != null &&
        ((predictedPK == true  && actualPK == m.t1.toLowerCase()) ||
         (predictedPK == false && actualPK == m.t2.toLowerCase()));

    Widget chip(bool correct, String label) {
      return Container(
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
            fontSize: 9,
            fontWeight: FontWeight.bold,
          )),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(color: AppColors.border, height: 20),
      Row(children: [
        const Icon(Icons.access_time, size: 11, color: AppColors.textDim),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${AppTranslations.get(widget.lang, 'extraTimeLabel')}: '
            '${AppTranslations.getTeam(widget.lang, m.etWinner!)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ),
        if (pred?.extraTimeWinner != null) chip(etCorrect, etCorrect ? '+20' : '0 pts'),
      ]),
      if (m.wentToPK == true && m.pkWinner != null) ...[
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.sports_score, size: 11, color: AppColors.textDim),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${AppTranslations.get(widget.lang, 'penaltiesLabel')}: '
              '${AppTranslations.getTeam(widget.lang, m.pkWinner!)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ),
          if (pred?.penaltyWinner != null) chip(pkCorrect, pkCorrect ? '+25' : '0 pts'),
        ]),
      ],
    ]);
  }



  void _showEditGroupDialog(FriendGroup grp) {
    final editController = TextEditingController(text: grp.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppTranslations.get(widget.lang, 'edit') ?? 'Edit Group', style: const TextStyle(color: Colors.white, fontSize: 14)),
          content: TextField(
            controller: editController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppTranslations.get(widget.lang, 'groupName'),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  await PredictionService.editCustomGroup(grp.code, newName);
                  if (mounted) {
                    Navigator.of(context).pop();
                    await _loadData();
                  }
                }
              },
              child: Text(AppTranslations.get(widget.lang, 'save'), style: const TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(FriendGroup grp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppTranslations.get(widget.lang, 'delete') ?? 'Delete Group', style: const TextStyle(color: Colors.white, fontSize: 14)),
          content: Text(
            AppTranslations.get(widget.lang, 'deleteGroupForEveryone'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                await PredictionService.deleteCustomGroup(grp.code);
                if (mounted) {
                  Navigator.of(context).pop();
                  await _loadData();
                }
              },
              child: Text(AppTranslations.get(widget.lang, 'delete') ?? 'Delete', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveGroupDialog(FriendGroup grp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppTranslations.get(widget.lang, 'leaveGroupTitle'), style: const TextStyle(color: Colors.white, fontSize: 14)),
          content: Text(
            AppTranslations.get(widget.lang, 'leaveGroupConfirm'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                await PredictionService.leaveCustomGroup(grp.code);
                if (mounted) {
                  Navigator.of(context).pop();
                  await _loadData();
                }
              },
              child: Text(AppTranslations.get(widget.lang, 'leave'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            AppTranslations.get(widget.lang, 'createGroup'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _newGroupController,
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
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(AppTranslations.get(widget.lang, 'save'), style: const TextStyle(color: Colors.black)),
              onPressed: _createNewGroup,
            ),
          ],
        );
      },
    );
  }

  void _showJoinGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            AppTranslations.get(widget.lang, 'joinGroup'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AppTranslations.get(widget.lang, 'enterCode'),
              hintStyle: const TextStyle(color: AppColors.textDim),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
            ),
          ),
          actions: [
            TextButton(
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(AppTranslations.get(widget.lang, 'joinGroup'), style: const TextStyle(color: Colors.black)),
              onPressed: _joinSharedGroup,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmblemWidget(String emblem, {double size = 24}) {
    if (emblem.startsWith('assets/avatars/') || emblem.contains('.png')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          emblem,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: size * 0.6, color: AppColors.textDim),
        ),
      );
    } else {
      return Text(
        emblem,
        style: TextStyle(fontSize: size * 0.7),
      );
    }
  }
}