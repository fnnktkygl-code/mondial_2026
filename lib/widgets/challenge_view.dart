import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../l10n/translations.dart';
import '../services/prediction_service.dart';
import '../services/firebase_service.dart';
import '../app_colors.dart';
import '../app_constants.dart';

class ChallengeViewWidget extends StatefulWidget {
  final List<WorldCupMatch> matches;
  final String lang;
  final Function(String message) showSnackBar;
  final Function(Map<String, String> alerts) onAlertsChanged;
  final Function(String? teamCode) onSupportedTeamChanged;

  const ChallengeViewWidget({
    super.key,
    required this.matches,
    required this.lang,
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
    );
  }

  Future<void> _saveUsername() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      _userPreds.username = name;
      await PredictionService.savePredictionData(_userPreds);
      
      final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
      await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, name);

      await _loadData();
      widget.showSnackBar(AppTranslations.get(widget.lang, 'pseudoUpdated'));
    }
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

    _userPreds.matchPredictions[matchId] = MatchPrediction(
      matchId: matchId,
      t1Score: new1,
      t2Score: new2,
    );

    await PredictionService.savePredictionData(_userPreds);
    
    final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
    await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);

    // Reload group scores dynamically
    final groups = await PredictionService.loadChallengeGroups(_userPreds, widget.matches);
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _saveBonusChampion(String? teamCode) async {
    if (teamCode != null) {
      _userPreds.championCode = teamCode;
      await PredictionService.savePredictionData(_userPreds);
      
      final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
      await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);

      setState(() {});
      widget.showSnackBar(AppTranslations.get(widget.lang, 'championSaved'));
    }
  }

  Future<void> _saveBonusScorer(String name) async {
    if (name.trim().isNotEmpty) {
      _userPreds.goldenBootPlayer = name.trim();
      await PredictionService.savePredictionData(_userPreds);
      
      final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
      await _syncProfileWithStats(totalPoints, _userPreds.supportedTeam, _userPreds.username);

      setState(() {});
      widget.showSnackBar(AppTranslations.get(widget.lang, 'scorerSaved'));
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
    final payload = PredictionService.generateSharePayload(grp.name, _userPreds);
    final inviteMessage = widget.lang == 'fr'
        ? "🏆 Rejoins mon groupe de pronos '${grp.name}' sur Mondial 2026! Entre mon code de défi pour comparer nos scores:\n\n$payload"
        : "🏆 Join my prediction group '${grp.name}' on World Cup 2026! Paste my challenge code to compare our scores:\n\n$payload";

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          // XP badge icon
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Text(
              'L${xp['level']}',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),

          // Username & XP Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userPreds.username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.textDim, size: 16),
                      onPressed: _showUsernameEditDialog,
                    ),
                  ],
                ),
                Text(
                  '${xp['rankName']}',
                  style: const TextStyle(color: AppColors.rankGold, fontSize: 11, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: AppColors.textDim, fontSize: 9),
                    ),
                    Text(
                      '$points pts',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10),
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
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSupportedTeamDropdown(),
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

  Widget _buildSupportedTeamDropdown() {
    final Set<String> teamCodes = {};
    for (final m in widget.matches) {
      if (m.t1.length == 2) teamCodes.add(m.t1);
      if (m.t2.length == 2) teamCodes.add(m.t2);
    }
    final List<String> sortedTeams = teamCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _userPreds.supportedTeam,
        hint: Text(
          AppTranslations.get(widget.lang, 'chooseTeam'),
          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
        dropdownColor: AppColors.card,
        isDense: true,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 16),
        onChanged: (newTeamCode) async {
          if (newTeamCode != null) {
            setState(() {
              _userPreds.supportedTeam = newTeamCode;
            });
            await PredictionService.savePredictionData(_userPreds);
            
            final totalPoints = PredictionService.calculateTotalPoints(_userPreds, widget.matches);
            await _syncProfileWithStats(totalPoints, newTeamCode, _userPreds.username);
            
            // Notify parent of supported team change
            widget.onSupportedTeamChanged(newTeamCode);
            
            widget.showSnackBar(AppTranslations.get(widget.lang, 'teamUpdated'));
          }
        },
        items: sortedTeams.map((code) {
          final name = AppTranslations.getTeam(widget.lang, code);
          final emblem = AppTranslations.getTeamWithEmblem(widget.lang, code).split(' ').first;
          return DropdownMenuItem<String>(
            value: code,
            child: Text(
              '$emblem $name',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubTabSelector() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _buildSubTabButton('preds', widget.lang == 'fr' ? 'Pronos' : 'Preds', Icons.sports_soccer),
          const SizedBox(width: 4),
          _buildSubTabButton('groups', widget.lang == 'fr' ? 'Groupes' : 'Groups', Icons.groups),
          const SizedBox(width: 4),
          _buildSubTabButton('leaderboard', widget.lang == 'fr' ? 'Classement' : 'Leaderboard', Icons.emoji_events),
          const SizedBox(width: 4),
          _buildSubTabButton('bonus', widget.lang == 'fr' ? 'Bonus' : 'Bonus', Icons.star),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String tab, String label, IconData icon) {
    final isSelected = _subTab == tab;
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 14, color: isSelected ? Colors.black : AppColors.textMuted),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.black : Colors.white,
          backgroundColor: isSelected ? AppColors.accent : AppColors.card,
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

        final docs = snapshot.data?.docs ?? [];
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
            final isMe = docs[index].id == _myUserId;

            String teamDisplay = '';
            if (supportedTeam != null && supportedTeam.isNotEmpty) {
              final emblemName = AppTranslations.getTeamWithEmblem(widget.lang, supportedTeam);
              final parts = emblemName.split(' ');
              if (parts.isNotEmpty) {
                teamDisplay = parts.first;
              }
            }

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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMe ? AppColors.accent : AppColors.border,
                  width: isMe ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  rankWidget,
                  const SizedBox(width: 12),
                  if (teamDisplay.isNotEmpty) ...[
                    Text(teamDisplay, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      username + AppTranslations.get(widget.lang, isMe ? 'youSuffix' : 'pointsSuffix').replaceAll(' pts', '').replaceAll(' (Vous)', isMe ? AppTranslations.get(widget.lang, 'youSuffix') : ''),
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
                    '$points pts',
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
    } else if (_subTab == 'leaderboard') {
      return _buildLeaderboardTab();
    } else {
      return _buildBonusTab();
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
        // Sub-filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterButton('group', AppTranslations.get(widget.lang, 'predGroupStage')),
              const SizedBox(width: 12),
              _buildFilterButton('knockout', AppTranslations.get(widget.lang, 'predKnockout')),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: activeList.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (c, i) {
              final m = activeList[i];
              return _buildPredictionCard(m);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _predsFilter == filter;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(color: isSelected ? AppColors.accent : AppColors.textDim),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isPlayed ? AppColors.border : AppColors.borderMid,
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
                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  if (_userPreds.boosterMatchId == m.id) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.rocket_launch, size: 12, color: AppColors.warning),
                  ],
                ],
              ),
              Text(
                m.getFormattedDate(widget.lang),
                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Score Prediction Interface
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team 1 Logo & Name
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(
                        'https://flagcdn.com/w40/${m.t1 == 'en' ? 'gb-eng' : m.t1}.png',
                        width: 20,
                        height: 12,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 20, height: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t1EmblemName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Inputs (+ / - buttons)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIncrementButton(m.id, -1, 0, m.isPlayed),
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      hasPred ? '$p1Val' : '-',
                      style: TextStyle(
                        color: hasPred ? Colors.white : AppColors.textDim,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildIncrementButton(m.id, 1, 0, m.isPlayed),
                  const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 4),
                     child: Text(':', style: TextStyle(color: AppColors.textDim, fontSize: 16)),
                  ),
                  _buildIncrementButton(m.id, 0, -1, m.isPlayed),
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      hasPred ? '$p2Val' : '-',
                      style: TextStyle(
                        color: hasPred ? Colors.white : AppColors.textDim,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildIncrementButton(m.id, 0, 1, m.isPlayed),
                ],
              ),

              // Team 2 Name & Logo
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        t2EmblemName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(
                        'https://flagcdn.com/w40/${m.t2 == 'en' ? 'gb-eng' : m.t2}.png',
                        width: 20,
                        height: 12,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 20, height: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actual match result & Points badge
          if (m.isPlayed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppTranslations.get(widget.lang, 'stats')}: ${m.t1Score} - ${m.t2Score}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pointsEarned > 0
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pointsEarned > 0
                        ? '+ $pointsEarned PTS'
                        : AppTranslations.get(widget.lang, 'noPoints'),
                    style: TextStyle(
                      color: pointsEarned > 0 ? AppColors.accent : AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

          // Booster selector for unplayed matches
          if (!m.isPlayed) ...[
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
    if (isMatchPlayed) return const SizedBox(width: 24);

    return SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          (t1Offset > 0 || t2Offset > 0) ? Icons.add_circle : Icons.remove_circle,
          color: AppColors.accent,
          size: 20,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(16),
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
              if (grp.code != 'GLOBAL-2026')
                IconButton(
                  icon: const Icon(Icons.share, color: AppColors.accent, size: 18),
                  onPressed: () => _shareGroup(grp),
                ),
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
                  Text(
                    member.emblem,
                    style: const TextStyle(fontSize: 16),
                  ),
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

  // ================= BONUS TAB =================
  Widget _buildBonusTab() {
    // Unique list of all teams for the dropdown
    final Set<String> teamCodes = {};
    for (final m in widget.matches) {
      if (m.t1.length == 2) teamCodes.add(m.t1);
      if (m.t2.length == 2) teamCodes.add(m.t2);
    }
    final List<String> sortedTeams = teamCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Predict Champion
          Text(
            AppTranslations.get(widget.lang, 'predictChampion'),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _userPreds.championCode,
                hint: Text(
                  AppTranslations.get(widget.lang, 'selectWinner'),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
                dropdownColor: AppColors.card,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                onChanged: _saveBonusChampion,
                items: sortedTeams.map((code) {
                  final name = AppTranslations.getTeam(widget.lang, code);
                  final emblem = AppTranslations.getTeamWithEmblem(widget.lang, code).split(' ').first;
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      '$emblem $name',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Predict Top Scorer
          Text(
            AppTranslations.get(widget.lang, 'predictScorer'),
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _userPreds.goldenBootPlayer ?? 'Kylian Mbappé / Harry Kane...',
                      hintStyle: TextStyle(
                        color: _userPreds.goldenBootPlayer != null ? Colors.white : AppColors.textDim,
                        fontSize: 13,
                        fontWeight: _userPreds.goldenBootPlayer != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _saveBonusScorer(_codeController.text);
                    _codeController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: Text(AppTranslations.get(widget.lang, 'save'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS =================
  void _showUsernameEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            AppTranslations.get(widget.lang, 'enterName'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
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
              onPressed: () {
                _saveUsername();
                Navigator.of(context).pop();
              },
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
}

