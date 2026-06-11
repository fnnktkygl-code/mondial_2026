import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mondial_2026/widgets/wc2026_players.dart';
import '../models/match.dart';
import '../services/prediction_service.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../l10n/translations.dart';
import '../services/team_profile_service.dart';
import '../app_colors.dart';
import '../app_constants.dart';
import 'team_flag.dart';
import 'team_selector.dart';
import 'wc_tooltip.dart';

// ─── Avatar options ──────────────────────────────────────────────────────────

final List<String> kAvatarOptions = List.generate(
  32,
  (index) => 'assets/avatars/${index + 1}.png',
);

// ─── Badge definitions ───────────────────────────────────────────────────────

class BadgeDef {
  final String id;
  final String icon;
  final String labelKey;
  final bool isRare;
  const BadgeDef({
    required this.id,
    required this.icon,
    required this.labelKey,
    this.isRare = false,
  });
}

const List<BadgeDef> kUserBadgeDefs = [
  BadgeDef(id: 'first_pred',  icon: '🎯', labelKey: 'badgeFirstPred'),
  BadgeDef(id: 'streak_3',    icon: '🔥', labelKey: 'badgeStreak3'),
  BadgeDef(id: 'streak_7',    icon: '🔥', labelKey: 'badgeStreak7',  isRare: true),
  BadgeDef(id: 'guru_5',      icon: '🔮', labelKey: 'badgeGuru5',    isRare: true),
  BadgeDef(id: 'exact_score', icon: '⚡', labelKey: 'badgeExact'),
  BadgeDef(id: 'champion_ok', icon: '🏆', labelKey: 'badgeChampion', isRare: true),
  BadgeDef(id: 'top_10',      icon: '📈', labelKey: 'badgeTop10',    isRare: true),
  BadgeDef(id: 'finalist_ok', icon: '🌍', labelKey: 'badgeFinalist'),
];

Set<String> computeEarnedBadges({
  required PredictionData userPreds,
  required List<WorldCupMatch> matches,
}) {
  final earned = <String>{};
  if (userPreds.matchPredictions.isNotEmpty) earned.add('first_pred');
  final streak = PredictionService.calculateActiveStreak(userPreds, matches);
  if (streak >= 3) earned.add('streak_3');
  if (streak >= 7) earned.add('streak_7');
  final guruCount = PredictionService.calculateExactGuessesCount(userPreds, matches);
  if (guruCount >= 5) earned.add('guru_5');
  if (guruCount >= 1) earned.add('exact_score');
  if (userPreds.championCode != null) {
    final finalMatch = matches.where((m) => m.id == kFinalMatchId && m.isPlayed).firstOrNull;
    if (finalMatch != null) {
      final winner = (finalMatch.t1Score ?? 0) > (finalMatch.t2Score ?? 0) ? finalMatch.t1 : finalMatch.t2;
      if (userPreds.championCode!.toLowerCase() == winner.toLowerCase()) earned.add('champion_ok');
    }
  }
  if (userPreds.supportedTeam != null) {
    final finalMatch = matches.where((m) => m.id == kFinalMatchId).firstOrNull;
    if (finalMatch != null) {
      final code = userPreds.supportedTeam!.toLowerCase();
      if (finalMatch.t1.toLowerCase() == code || finalMatch.t2.toLowerCase() == code) earned.add('finalist_ok');
    }
  }
  return earned;
}

// ─────────────────────────────────────────────────────────────────────────────

class UserProfileDialog extends StatefulWidget {
  final String lang;
  final List<WorldCupMatch> matches;
  final PredictionData userPreds;
  final Function(String msg) showSnackBar;
  final Function(String? teamCode) onSupportedTeamChanged;
  final Function() onSaved;

  const UserProfileDialog({
    super.key,
    required this.lang,
    required this.matches,
    required this.userPreds,
    required this.showSnackBar,
    required this.onSupportedTeamChanged,
    required this.onSaved,
  });

  static void show(
    BuildContext context, {
    required String lang,
    required List<WorldCupMatch> matches,
    required PredictionData userPreds,
    required Function(String msg) showSnackBar,
    required Function(String? teamCode) onSupportedTeamChanged,
    required Function() onSaved,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim, secondaryAnim) => UserProfileDialog(
        lang: lang,
        matches: matches,
        userPreds: userPreds,
        showSnackBar: showSnackBar,
        onSupportedTeamChanged: onSupportedTeamChanged,
        onSaved: onSaved,
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: curved, child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ));
      },
    );
  }

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _scorerController;
  late TextEditingController _assisterController;
  String? _supportedTeam;
  String? _championCode;
  String _avatar = '';
  bool _isSaving = false;
  bool _isHidden = false;
  bool _trophiesExpanded = false;

  final FocusNode _scorerFocusNode = FocusNode();
  final FocusNode _assisterFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userPreds.username);
    _scorerController = TextEditingController(text: widget.userPreds.goldenBootPlayer);
    _assisterController = TextEditingController(text: widget.userPreds.topAssisterPlayer);
    _supportedTeam = widget.userPreds.supportedTeam;
    _championCode = widget.userPreds.championCode;
    _avatar = widget.userPreds.avatar;
    _loadVisibility();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scorerController.dispose();
    _assisterController.dispose();
    _scorerFocusNode.dispose();
    _assisterFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVisibility() async {
    final hidden = await WCFirebaseService.getProfileVisibility();
    if (mounted) setState(() => _isHidden = hidden);
  }

  List<String> _getSortedTeams() {
    final Set<String> qualifiedCodes = {};
    bool isValidCode(String code) {
      final c = code.toLowerCase();
      return c != 'tbd' && !c.contains(RegExp(r'[0-9]')) && !(c.startsWith('w') && c.length > 3);
    }
    for (final m in widget.matches) {
      if (isValidCode(m.t1)) qualifiedCodes.add(m.t1.toLowerCase());
      if (isValidCode(m.t2)) qualifiedCodes.add(m.t2.toLowerCase());
    }
    return qualifiedCodes.toList()..sort((a, b) => AppTranslations.getTeam(widget.lang, a).compareTo(AppTranslations.getTeam(widget.lang, b)));
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = AppColors.accent,
    Color confirmTextColor = Colors.black,
    Widget? extraContent,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            if (extraContent != null) ...[const SizedBox(height: 16), extraContent],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor, foregroundColor: confirmTextColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
          ), child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmChampionSelection(String selectedCode) async {
    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'confirmWinnerTitle'),
      message: AppTranslations.get(widget.lang, 'confirmWinnerMsg'),
      confirmLabel: AppTranslations.get(widget.lang, 'confirm'),
      extraContent: Row(children: [_buildFlag(selectedCode), const SizedBox(width: 10), Text(AppTranslations.getTeam(widget.lang, selectedCode), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
    );
    if (mounted && confirmed) setState(() => _championCode = selectedCode);
  }

  Future<void> _resetProfile() async {
    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'resetProfile'),
      message: AppTranslations.get(widget.lang, 'resetProfileConfirm'),
      confirmLabel: AppTranslations.get(widget.lang, 'reset'),
      confirmColor: AppColors.danger, confirmTextColor: Colors.white,
    );
    if (!confirmed) return;
    widget.userPreds.matchPredictions.clear();
    widget.userPreds.championCode = null;
    widget.userPreds.goldenBootPlayer = null;
    widget.userPreds.goldenBootWinner = null;
    widget.userPreds.topAssisterPlayer = null;
    widget.userPreds.boosterMatchId = null;
    widget.userPreds.supportedTeam = null;
    await PredictionService.savePredictionData(widget.userPreds);
    setState(() { _championCode = null; _supportedTeam = null; _scorerController.clear(); _assisterController.clear(); });
    await WCFirebaseService.syncUserProfile(username: widget.userPreds.username, supportedTeam: null, points: 0, streak: 0, guruCount: 0, avatar: widget.userPreds.avatar, isHidden: _isHidden);
    if (!mounted) return;
    widget.onSupportedTeamChanged(null); widget.onSaved(); Navigator.of(context).pop();
  }

  Future<void> _deleteProfile() async {
    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'deleteProfile'),
      message: AppTranslations.get(widget.lang, 'deleteProfileConfirm'),
      confirmLabel: AppTranslations.get(widget.lang, 'delete'),
      confirmColor: AppColors.danger, confirmTextColor: Colors.white,
    );
    if (!confirmed) return;
    widget.userPreds.matchPredictions.clear();
    widget.userPreds.championCode = null;
    widget.userPreds.goldenBootPlayer = null;
    widget.userPreds.goldenBootWinner = null;
    widget.userPreds.topAssisterPlayer = null;
    widget.userPreds.boosterMatchId = null;
    widget.userPreds.username = '';
    widget.userPreds.avatar = '';
    widget.userPreds.supportedTeam = null;
    await PredictionService.savePredictionData(widget.userPreds);
    setState(() { _championCode = null; _supportedTeam = null; _nameController.clear(); _scorerController.clear(); _assisterController.clear(); });
    await WCFirebaseService.deleteUserProfile();
    if (!mounted) return;
    widget.onSupportedTeamChanged(null); widget.onSaved(); Navigator.of(context).pop();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty) { widget.showSnackBar(AppTranslations.get(widget.lang, 'nicknameEmpty')); return; }
    final scorerInput = _scorerController.text.trim();
    final bool isNewScorer = widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty;
    final assisterInput = _assisterController.text.trim();
    final bool isNewAssister = widget.userPreds.topAssisterPlayer == null && assisterInput.isNotEmpty;
    if (isNewScorer && !kWC2026Players.contains(scorerInput)) { widget.showSnackBar(AppTranslations.get(widget.lang, 'scorerNotFound')); return; }
    if (isNewAssister && !kWC2026Players.contains(assisterInput)) { widget.showSnackBar(AppTranslations.get(widget.lang, 'assisterNotFound')); return; }
    if (isNewScorer || isNewAssister) {
      final confirmed = await _showConfirmDialog(title: AppTranslations.get(widget.lang, 'confirmPredictions'), message: AppTranslations.get(widget.lang, 'confirmPredictionsWarning'), confirmLabel: AppTranslations.get(widget.lang, 'confirm'));
      if (!confirmed) return;
    }
    setState(() => _isSaving = true);
    try {
      widget.userPreds.username = name;
      widget.userPreds.avatar = _avatar;
      widget.userPreds.supportedTeam = _supportedTeam;
      if (widget.userPreds.championCode == null && _championCode != null) { widget.userPreds.championCode = _championCode; widget.userPreds.championPredictedAt = DateTime.now(); }
      if (widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty) { widget.userPreds.goldenBootPlayer = scorerInput; widget.userPreds.goldenBootPredictedAt = DateTime.now(); }
      if (widget.userPreds.topAssisterPlayer == null && assisterInput.isNotEmpty) { widget.userPreds.topAssisterPlayer = assisterInput; widget.userPreds.topAssisterPredictedAt = DateTime.now(); }
      await PredictionService.savePredictionData(widget.userPreds);
      final totalPoints = PredictionService.calculateTotalPoints(widget.userPreds, widget.matches);
      final streak = PredictionService.calculateActiveStreak(widget.userPreds, widget.matches);
      final guruCount = PredictionService.calculateExactGuessesCount(widget.userPreds, widget.matches);
      await WCFirebaseService.syncUserProfile(username: name, supportedTeam: _supportedTeam, points: totalPoints, streak: streak, guruCount: guruCount, avatar: _avatar, isHidden: _isHidden);
      if (!mounted) return;
      widget.onSupportedTeamChanged(_supportedTeam); widget.onSaved(); widget.showSnackBar(AppTranslations.get(widget.lang, 'saveSuccess')); Navigator.of(context).pop();
    } catch (e) { widget.showSnackBar('Error saving profile: $e'); } finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalPoints = PredictionService.calculateTotalPoints(widget.userPreds, widget.matches);
    final xpInfo = PredictionService.getXpDetails(totalPoints, widget.lang);
    final potC = PredictionService.getPotentialChampionPoints(now, widget.matches);
    final potS = PredictionService.getPotentialGoldenBootPoints(now, widget.matches);
    final potA = PredictionService.getPotentialTopAssisterPoints(now, widget.matches);
    final lockC = widget.userPreds.championCode != null ? PredictionService.getPotentialChampionPoints(widget.userPreds.championPredictedAt, widget.matches) : null;
    final lockS = widget.userPreds.goldenBootPlayer != null ? PredictionService.getPotentialGoldenBootPoints(widget.userPreds.goldenBootPredictedAt, widget.matches) : null;
    final lockA = widget.userPreds.topAssisterPlayer != null ? PredictionService.getPotentialTopAssisterPoints(widget.userPreds.topAssisterPredictedAt, widget.matches) : null;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;
    final dialogWidth = isDesktop ? 700.0 : 450.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48),
        child: Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(kDialogRadius), border: Border.all(color: AppColors.border, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10))]),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(color: AppColors.cardDark, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(AppTranslations.get(widget.lang, 'profileTitle'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  _CloseButton(onTap: () => Navigator.of(context).pop(), tooltip: AppTranslations.get(widget.lang, 'close')),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + mediaQuery.padding.bottom),
                  child: isDesktop
                      ? _buildDesktopLayout(xpInfo, potC, potS, potA, lockC, lockS, lockA)
                      : _buildMobileLayout(xpInfo, potC, potS, potA, lockC, lockS, lockA),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + mediaQuery.padding.bottom),
                decoration: const BoxDecoration(color: AppColors.cardDark, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)), elevation: 0),
                  child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.0)) : Text(AppTranslations.get(widget.lang, 'save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> xpInfo, int potC, int potS, int potA, int? lockC, int? lockS, int? lockA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAvatarSection(), const SizedBox(height: 16),
        _buildXpSection(xpInfo), const SizedBox(height: 24),
        _buildLabel(AppTranslations.get(widget.lang, 'yourBadges')), const SizedBox(height: 12),
        _buildUserBadgesSection(), const SizedBox(height: 32),
        _buildLabel(AppTranslations.get(widget.lang, 'tournamentPredictions')), const SizedBox(height: 16),
        _buildWarningBanner(), _buildNameInput(), const SizedBox(height: 20),
        _buildFavoriteTeam(), const SizedBox(height: 20),
        _buildWinnerPred(potC, lockC), const SizedBox(height: 20),
        _buildScorerPred(potS, lockS), const SizedBox(height: 20),
        _buildAssisterPred(potA, lockA), const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1), const SizedBox(height: 16),
        _buildVisibilitySwitch(), const SizedBox(height: 12),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout(Map<String, dynamic> xpInfo, int potC, int potS, int potA, int? lockC, int? lockS, int? lockA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 200, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildAvatarSection(), const SizedBox(height: 16), _buildXpSection(xpInfo)])),
          const SizedBox(width: 32),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildWarningBanner(), _buildNameInput(), const SizedBox(height: 20), _buildFavoriteTeam()])),
        ]),
        const SizedBox(height: 20),
        _buildLabel(AppTranslations.get(widget.lang, 'yourBadges')), const SizedBox(height: 12),
        _buildUserBadgesSection(), const SizedBox(height: 32),
        const Divider(color: AppColors.border, height: 1), const SizedBox(height: 32),
        _buildLabel(AppTranslations.get(widget.lang, 'tournamentPredictions')), const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildWinnerPred(potC, lockC)), const SizedBox(width: 24),
          Expanded(child: _buildScorerPred(potS, lockS)), const SizedBox(width: 24),
          Expanded(child: _buildAssisterPred(potA, lockA)),
        ]),
        const SizedBox(height: 24), const Divider(color: AppColors.border, height: 1), const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: _buildVisibilitySwitch()), const SizedBox(width: 40), _buildActionButtons()]),
      ],
    );
  }

  Widget _buildXpSection(Map<String, dynamic> xpInfo) {
    final progress = (xpInfo['progress'] as double).clamp(0.0, 1.0);
    final level = xpInfo['level'] as int;
    final xp = xpInfo['xp'];
    final nextXp = xpInfo['nextLevelXp'];
    final rankName = xpInfo['rankName'] as String;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(rankName, style: const TextStyle(color: AppColors.rankGold, fontSize: 12, fontWeight: FontWeight.w700)),
        Text('Niv. $level', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
        FractionallySizedBox(widthFactor: progress, child: Container(height: 5, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(3)))),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$xp / $nextXp XP', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
        Text('Niv $level → ${level + 1}', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
      ]),
    ]);
  }

  Widget _buildUserBadgesSection() {
    final earnedBadges = computeEarnedBadges(userPreds: widget.userPreds, matches: widget.matches);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(AppTranslations.get(widget.lang, 'myBadgesLabel'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
        Text('${earnedBadges.length}/${kUserBadgeDefs.length}', style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      Row(children: kUserBadgeDefs.map((badge) {
        final isEarned = earnedBadges.contains(badge.id);
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2.5), child: _buildBadgeChip(badge, isEarned)));
      }).toList()),
    ]);
  }

  Widget _buildBadgeChip(BadgeDef badge, bool isEarned) {
    final Color borderColor = isEarned ? (badge.isRare ? AppColors.purple : AppColors.warning) : AppColors.border;
    final Color bgColor = isEarned ? (badge.isRare ? AppColors.purple.withValues(alpha: 0.10) : AppColors.warning.withValues(alpha: 0.08)) : AppColors.surface;
    final descKey = '${badge.labelKey}Desc';
    final title = AppTranslations.get(widget.lang, badge.labelKey);
    final description = AppTranslations.get(widget.lang, descKey);

    return WCTooltip(
      title: title,
      message: description,
      child: AnimatedOpacity(
        opacity: isEarned ? 1.0 : 0.32,
        duration: const Duration(milliseconds: 200),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(badge.icon, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(AppTranslations.get(widget.lang, 'avatar'), style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Container(width: 96, height: 96, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(kDialogRadius), border: Border.all(color: AppColors.accent, width: 2)), clipBehavior: Clip.antiAlias, child: _avatar.isEmpty || !_avatar.contains('.png') ? const Icon(Icons.person, color: AppColors.textDim, size: 48) : Image.asset(_avatar, width: 96, height: 96, fit: BoxFit.cover)),
      const SizedBox(height: 14),
      Stack(children: [
        SizedBox(height: 56, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: kAvatarOptions.length, separatorBuilder: (context, index) => const SizedBox(width: 8), itemBuilder: (context, index) {
          final path = kAvatarOptions[index];
          final isSel = _avatar == path;
          return GestureDetector(onTap: () => setState(() => _avatar = path), child: AnimatedContainer(duration: const Duration(milliseconds: 140), width: 48, height: 48, decoration: BoxDecoration(color: isSel ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface, borderRadius: BorderRadius.circular(kCardRadius), border: Border.all(color: isSel ? AppColors.accent : AppColors.border, width: isSel ? 2 : 1)), clipBehavior: Clip.antiAlias, child: Image.asset(path, fit: BoxFit.cover)));
        })),
        Positioned(top: 0, right: 0, bottom: 0, width: 32, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.card.withValues(alpha: 0.0), AppColors.card.withValues(alpha: 0.9)]))))),
      ]),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.swipe, color: AppColors.textDim, size: 11), const SizedBox(width: 4), Text('${kAvatarOptions.length} avatars', style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontStyle: FontStyle.italic))]),
    ]);
  }

  Widget _buildWarningBanner() {
    return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18), const SizedBox(width: 8), Expanded(child: Text(AppTranslations.get(widget.lang, 'winnerScorerWarningText'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4)))]));
  }

  Widget _buildNameInput() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(AppTranslations.get(widget.lang, 'pseudoLabel')), const SizedBox(height: 8), TextField(controller: _nameController, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: InputDecoration(fillColor: AppColors.surface, filled: true, hintText: AppTranslations.get(widget.lang, 'enterNickname'), hintStyle: const TextStyle(color: AppColors.textDim), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.border, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.accent, width: 1.5))))]);
  }

  Widget _buildFavoriteTeam() {
    final teamCode = _supportedTeam;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(AppTranslations.get(widget.lang, 'favoriteTeamLabel')), const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _buildTeamPickerButton(selectedCode: teamCode, placeholder: AppTranslations.get(widget.lang, 'chooseTeam'), isHighlighted: false, onTap: () => TeamSelectorBottomSheet.show(context: context, lang: widget.lang, title: AppTranslations.get(widget.lang, 'chooseTeam'), selectedTeamCode: teamCode, teamCodes: _getSortedTeams(), onTeamSelected: (code) => setState(() => _supportedTeam = code)))),
        if (teamCode != null && WCAudioService.instance.isValidCountry(teamCode)) ...[const SizedBox(width: 8), _buildAnthemPlayButton(teamCode)],
      ]),
      if (teamCode != null) ...[const SizedBox(height: 10), _buildTeamTrophiesCollapsible(teamCode)],
    ]);
  }

  Widget _buildTeamTrophiesCollapsible(String teamCode) {
    final code = teamCode.toLowerCase();
    final profile = WCTeamProfileService.getProfile(code, widget.lang);
    if (profile.trophies.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _trophiesExpanded = !_trophiesExpanded), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.emoji_events_outlined, color: AppColors.textMuted, size: 13), const SizedBox(width: 6), Text(AppTranslations.get(widget.lang, 'teamAchievements'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)), child: Text('${profile.trophies.length}', style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold))), const Spacer(), AnimatedRotation(turns: _trophiesExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 180), child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDim, size: 16))]))),
      AnimatedCrossFade(firstChild: const SizedBox.shrink(), secondChild: Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 8, runSpacing: 8, children: profile.trophies.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: AppColors.border)), child: Row(mainAxisSize: MainAxisSize.min, children: [_buildTrophyBadge(t), const SizedBox(width: 8), Flexible(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))]))).toList())), crossFadeState: _trophiesExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst, duration: const Duration(milliseconds: 220)),
    ]);
  }

  Widget _buildWinnerPred(int potC, int? lockC) {
    final isLocked = widget.userPreds.championCode != null;
    final finalMatch = widget.matches.where((m) => m.id == kFinalMatchId).firstOrNull;
    bool? isCorrect;
    if (finalMatch != null && finalMatch.isPlayed && isLocked) {
      final actualChamp = (finalMatch.t1Score ?? 0) > (finalMatch.t2Score ?? 0) ? finalMatch.t1 : finalMatch.t2;
      isCorrect = widget.userPreds.championCode!.toLowerCase() == actualChamp.toLowerCase();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(AppTranslations.get(widget.lang, 'winnerPredLabel')), const SizedBox(height: 8),
      isLocked ? _buildLockedPredRow(widget.userPreds.championCode!, lockC!, isCorrect) : _buildTeamPickerButton(selectedCode: _championCode, placeholder: AppTranslations.get(widget.lang, 'selectWinner'), isHighlighted: _championCode != null, onTap: () => TeamSelectorBottomSheet.show(context: context, lang: widget.lang, title: AppTranslations.get(widget.lang, 'selectWinner'), selectedTeamCode: _championCode, teamCodes: _getSortedTeams(), onTeamSelected: (code) => Future.delayed(const Duration(milliseconds: 300), () => _confirmChampionSelection(code)))),
    ]);
  }

  Widget _buildScorerPred(int potS, int? lockS) {
    final isLocked = widget.userPreds.goldenBootPlayer != null;
    final finalMatch = widget.matches.where((m) => m.id == kFinalMatchId).firstOrNull;
    bool? isCorrect;
    if (finalMatch != null && finalMatch.isPlayed && isLocked && widget.userPreds.goldenBootWinner != null) {
      isCorrect = PredictionService.isSamePlayer(widget.userPreds.goldenBootPlayer, widget.userPreds.goldenBootWinner);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(AppTranslations.get(widget.lang, 'goldenBootScorer')), const SizedBox(height: 8),
      isLocked ? _buildLockedPlayerRow(widget.userPreds.goldenBootPlayer!, lockS!, isCorrect) : _buildPlayerAutocomplete(_scorerController, _scorerFocusNode, AppTranslations.get(widget.lang, 'searchScorer')),
    ]);
  }

  Widget _buildAssisterPred(int potA, int? lockA) {
    final isLocked = widget.userPreds.topAssisterPlayer != null;
    final finalMatch = widget.matches.where((m) => m.id == kFinalMatchId).firstOrNull;
    bool? isCorrect;
    if (finalMatch != null && finalMatch.isPlayed && isLocked && widget.userPreds.topAssisterWinner != null) {
      isCorrect = PredictionService.isSamePlayer(widget.userPreds.topAssisterPlayer, widget.userPreds.topAssisterWinner);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(AppTranslations.get(widget.lang, 'topAssister')), const SizedBox(height: 8),
      isLocked ? _buildLockedPlayerRow(widget.userPreds.topAssisterPlayer!, lockA!, isCorrect) : _buildPlayerAutocomplete(_assisterController, _assisterFocusNode, AppTranslations.get(widget.lang, 'searchAssister')),
    ]);
  }

  Widget _buildLockedPredRow(String code, int pts, bool? isCorrect) {
    final color = isCorrect == null ? AppColors.warning : (isCorrect ? AppColors.accent : AppColors.danger);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)), child: Row(children: [_buildFlag(code), const SizedBox(width: 10), Expanded(child: Text(AppTranslations.getTeam(widget.lang, code), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))), const SizedBox(width: 8), _buildResultBadge(pts, isCorrect)]));
  }

  Widget _buildLockedPlayerRow(String name, int pts, bool? isCorrect) {
    final color = isCorrect == null ? AppColors.warning : (isCorrect ? AppColors.accent : AppColors.danger);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)), child: Row(children: [const Icon(Icons.person_outline, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), const SizedBox(width: 8), _buildResultBadge(pts, isCorrect)]));
  }

  Widget _buildResultBadge(int pts, bool? isCorrect) {
    final color = isCorrect == null ? AppColors.warning : (isCorrect ? AppColors.accent : AppColors.danger);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isCorrect == null ? Icons.lock : (isCorrect ? Icons.check_circle : Icons.cancel), color: color, size: 11), const SizedBox(width: 4), Text(isCorrect == false ? '0 pts' : '+$pts pts', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]));
  }

  Widget _buildLabel(String text) => Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold));
  Widget _buildFlag(String code) => TeamFlagWidget(code: code, width: 32, height: 22, borderRadius: 6);

  Widget _buildTeamPickerButton({required String? selectedCode, required String placeholder, required bool isHighlighted, required VoidCallback onTap}) {
    return OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), backgroundColor: AppColors.surface, side: BorderSide(color: isHighlighted ? AppColors.accent : AppColors.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius))), onPressed: onTap, child: Row(children: [if (selectedCode != null) ...[_buildFlag(selectedCode), const SizedBox(width: 12), Expanded(child: Text(AppTranslations.getTeam(widget.lang, selectedCode), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))] else Expanded(child: Text(placeholder, style: const TextStyle(color: AppColors.textDim, fontSize: 16))), const Icon(Icons.arrow_drop_down, color: AppColors.textDim)]));
  }

  Widget _buildPlayerAutocomplete(TextEditingController ctrl, FocusNode fn, String hint) {
    return Autocomplete<String>(optionsBuilder: (text) => text.text.isEmpty ? const Iterable<String>.empty() : kWC2026Players.where((p) => p.toLowerCase().contains(text.text.toLowerCase())), onSelected: (s) => ctrl.text = s, fieldViewBuilder: (ctx, fctrl, ffn, onDone) { if (ctrl.text.isNotEmpty && fctrl.text.isEmpty) fctrl.text = ctrl.text; return TextField(controller: fctrl, focusNode: ffn, onEditingComplete: onDone, onChanged: (v) => ctrl.text = v, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(fillColor: AppColors.surface, filled: true, hintText: hint, prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.border, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)))); }, optionsViewBuilder: (ctx, onSel, opts) => Align(alignment: Alignment.topLeft, child: Material(color: AppColors.card, elevation: 4, borderRadius: BorderRadius.circular(kButtonRadius), child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300), child: ListView.builder(padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length, itemBuilder: (ctx, i) => ListTile(dense: true, title: Text(opts.elementAt(i), style: const TextStyle(color: Colors.white)), onTap: () => onSel(opts.elementAt(i))))))));
  }

  Widget _buildVisibilitySwitch() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(AppTranslations.get(widget.lang, 'hideFromGlobalLeaderboard'), style: const TextStyle(color: Colors.white, fontSize: 13))), Switch(value: _isHidden, activeThumbColor: AppColors.accent, onChanged: (val) => setState(() => _isHidden = val))]);

  Widget _buildActionButtons() => Row(mainAxisSize: MainAxisSize.min, children: [TextButton.icon(onPressed: _resetProfile, icon: const Icon(Icons.refresh, color: AppColors.danger, size: 16), label: Text(AppTranslations.get(widget.lang, 'reset'), style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600))), const SizedBox(width: 8), TextButton.icon(onPressed: _deleteProfile, icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 16), label: Text(AppTranslations.get(widget.lang, 'delete'), style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)))]);

  Widget _buildTrophyBadge(String trophy) {
    final lower = trophy.toLowerCase(); String? asset; IconData icon = Icons.workspace_premium; Color color = Colors.amber;
    if (lower.contains('coupe du monde') || lower.contains('world cup')) {
      asset = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('copa américa')) {
      asset = 'assets/badges/conmebol.png';
    } else if (lower.contains('europe') || lower.contains('euro')) {
      asset = 'assets/badges/uefa.png';
    } else if (lower.contains('afrique')) {
      asset = 'assets/badges/caf.png';
    } else if (lower.contains('asie')) {
      asset = 'assets/badges/afc.png';
    }
    if (asset != null) return Image.asset(asset, width: 22, height: 22, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 18));
    return Icon(icon, color: color, size: 18);
  }

  Widget _buildAnthemPlayButton(String code) {
    final srv = WCAudioService.instance; final clean = code.toLowerCase().replaceAll('g_', '');
    return ValueListenableBuilder<String?>(valueListenable: srv.currentPlayingTeamCode, builder: (ctx, playing, _) {
      final isThis = playing == clean;
      return ValueListenableBuilder<PlayerState>(valueListenable: srv.playerState, builder: (ctx, state, _) {
        final isPlaying = isThis && state == PlayerState.playing;
        return ValueListenableBuilder<bool>(valueListenable: srv.isLoading, builder: (ctx, loading, _) {
          if (isThis && loading) return Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: AppColors.border, width: 1.5)), alignment: Alignment.center, child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent))));
          return Material(color: Colors.transparent, child: InkWell(onTap: () => srv.playAnthem(code), borderRadius: BorderRadius.circular(kButtonRadius), child: Container(width: 48, height: 48, decoration: BoxDecoration(color: isThis ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface, borderRadius: BorderRadius.circular(kButtonRadius), border: Border.all(color: isThis ? AppColors.accent : AppColors.border, width: 1.5)), child: Icon(isPlaying ? Icons.pause_rounded : Icons.music_note, color: isThis ? AppColors.accent : AppColors.textMuted, size: 26))));
        });
      });
    });
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap; final String? tooltip;
  const _CloseButton({required this.onTap, this.tooltip});
  @override
  Widget build(BuildContext context) {
    final btn = Material(color: AppColors.surface, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.close, color: AppColors.textDim, size: 20))));
    return tooltip == null ? btn : WCTooltip(message: tooltip!, child: btn);
  }
}
