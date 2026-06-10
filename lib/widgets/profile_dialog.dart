import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mondial_2026/widgets/wc2028_players.dart';
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

/// Chemins vers les images locales pour l'avatar.
final List<String> kAvatarOptions = List.generate(
  32,
      (index) => 'assets/avatars/${index + 1}.png',
);

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
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
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

  // ─── Data loading ───────────────────────────────────────────────────────

  Future<void> _loadVisibility() async {
    final hidden = await WCFirebaseService.getProfileVisibility();
    if (mounted) {
      setState(() => _isHidden = hidden);
    }
  }

  List<String> _getSortedTeams() {
    final Set<String> qualifiedCodes = {};

    bool isValidCountryCode(String code) {
      final c = code.toLowerCase();
      if (c == 'tbd') return false;
      if (c.contains(RegExp(r'[0-9]'))) return false;
      if ((c.startsWith('w') || c.startsWith('l')) && c.length > 3) return false;
      return true;
    }

    for (final m in widget.matches) {
      if (isValidCountryCode(m.t1)) qualifiedCodes.add(m.t1.toLowerCase());
      if (isValidCountryCode(m.t2)) qualifiedCodes.add(m.t2.toLowerCase());
    }

    return qualifiedCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));
  }

  // ─── Confirmation dialogs ───────────────────────────────────────────────

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
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              extraContent,
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppTranslations.get(widget.lang, 'cancel'),
              style: const TextStyle(color: AppColors.textDim),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: confirmTextColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmChampionSelection(String selectedCode) async {
    final teamName = AppTranslations.getTeam(widget.lang, selectedCode);

    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'confirmWinnerTitle'),
      message: AppTranslations.get(widget.lang, 'confirmWinnerMsg'),
      confirmLabel: AppTranslations.get(widget.lang, 'confirm'),
      extraContent: Row(
        children: [
          _buildFlag(selectedCode),
          const SizedBox(width: 10),
          Text(
            teamName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed) {
      setState(() => _championCode = selectedCode);
    }
  }

  // ─── Profile actions ────────────────────────────────────────────────────

  Future<void> _resetProfile() async {
    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'resetProfile'),
      message: AppTranslations.get(widget.lang, 'resetProfileConfirm'),
      confirmLabel: AppTranslations.get(widget.lang, 'reset'),
      confirmColor: AppColors.danger,
      confirmTextColor: Colors.white,
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

    setState(() {
      _championCode = null;
      _supportedTeam = null;
      _scorerController.clear();
      _assisterController.clear();
    });

    await WCFirebaseService.syncUserProfile(
      username: widget.userPreds.username,
      supportedTeam: null,
      points: 0,
      streak: 0,
      guruCount: 0,
      avatar: widget.userPreds.avatar,
      isHidden: _isHidden,
    );

    if (!mounted) return;
    widget.onSupportedTeamChanged(null);
    widget.onSaved();
    Navigator.of(context).pop();
  }

  Future<void> _deleteProfile() async {
    final confirmed = await _showConfirmDialog(
      title: AppTranslations.get(widget.lang, 'deleteProfile'),
      message: AppTranslations.get(widget.lang, 'deleteProfileConfirm'),
      confirmLabel: AppTranslations.get(widget.lang, 'delete'),
      confirmColor: AppColors.danger,
      confirmTextColor: Colors.white,
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

    setState(() {
      _championCode = null;
      _supportedTeam = null;
      _nameController.clear();
      _scorerController.clear();
      _assisterController.clear();
    });

    await WCFirebaseService.deleteUserProfile();

    if (!mounted) return;
    widget.onSupportedTeamChanged(null);
    widget.onSaved();
    Navigator.of(context).pop();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'nicknameEmpty'));
      return;
    }

    final scorerInput = _scorerController.text.trim();
    final bool isNewScorer = widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty;

    final assisterInput = _assisterController.text.trim();
    final bool isNewAssister =
        widget.userPreds.topAssisterPlayer == null && assisterInput.isNotEmpty;

    if (isNewScorer && !kWC2026Players.contains(scorerInput)) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'scorerNotFound'));
      return;
    }
    if (isNewAssister && !kWC2026Players.contains(assisterInput)) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'assisterNotFound'));
      return;
    }

    if (isNewScorer || isNewAssister) {
      final confirmed = await _showConfirmDialog(
        title: AppTranslations.get(widget.lang, 'confirmPredictions'),
        message: AppTranslations.get(widget.lang, 'confirmPredictionsWarning'),
        confirmLabel: AppTranslations.get(widget.lang, 'confirm'),
      );
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      widget.userPreds.username = name;
      widget.userPreds.avatar = _avatar;
      widget.userPreds.supportedTeam = _supportedTeam;

      if (widget.userPreds.championCode == null && _championCode != null) {
        widget.userPreds.championCode = _championCode;
        widget.userPreds.championPredictedAt = DateTime.now();
      }

      if (widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty) {
        widget.userPreds.goldenBootPlayer = scorerInput;
        widget.userPreds.goldenBootPredictedAt = DateTime.now();
      }

      if (widget.userPreds.topAssisterPlayer == null && assisterInput.isNotEmpty) {
        widget.userPreds.topAssisterPlayer = assisterInput;
        widget.userPreds.topAssisterPredictedAt = DateTime.now();
      }

      await PredictionService.savePredictionData(widget.userPreds);

      final totalPoints = PredictionService.calculateTotalPoints(widget.userPreds, widget.matches);
      final streak = PredictionService.calculateActiveStreak(widget.userPreds, widget.matches);
      final guruCount =
      PredictionService.calculateExactGuessesCount(widget.userPreds, widget.matches);

      await WCFirebaseService.syncUserProfile(
        username: name,
        supportedTeam: _supportedTeam,
        points: totalPoints,
        streak: streak,
        guruCount: guruCount,
        avatar: _avatar,
        isHidden: _isHidden,
      );

      if (!mounted) return;

      widget.onSupportedTeamChanged(_supportedTeam);
      widget.onSaved();
      widget.showSnackBar(AppTranslations.get(widget.lang, 'saveSuccess'));
      Navigator.of(context).pop();
    } catch (e) {
      widget.showSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final potentialChampPts = PredictionService.getPotentialChampionPoints(now, widget.matches);
    final potentialScorerPts = PredictionService.getPotentialGoldenBootPoints(now, widget.matches);
    final potentialAssisterPts =
    PredictionService.getPotentialTopAssisterPoints(now, widget.matches);

    final lockedChampPts = widget.userPreds.championCode != null
        ? PredictionService.getPotentialChampionPoints(
        widget.userPreds.championPredictedAt, widget.matches)
        : null;
    final lockedScorerPts = widget.userPreds.goldenBootPlayer != null
        ? PredictionService.getPotentialGoldenBootPoints(
        widget.userPreds.goldenBootPredictedAt, widget.matches)
        : null;
    final lockedAssisterPts = widget.userPreds.topAssisterPlayer != null
        ? PredictionService.getPotentialTopAssisterPoints(
        widget.userPreds.topAssisterPredictedAt, widget.matches)
        : null;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth > 900;
    final dialogWidth = isDesktop ? 700.0 : 450.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(kDialogRadius),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Sticky header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                  color: AppColors.cardDark,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.get(widget.lang, 'profileTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _CloseButton(
                      onTap: () => Navigator.of(context).pop(),
                      tooltip: AppTranslations.get(widget.lang, 'close'),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable body ────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + mediaQuery.padding.bottom),
                  child: isDesktop
                      ? _buildDesktopLayout(
                    potentialChampPts,
                    potentialScorerPts,
                    potentialAssisterPts,
                    lockedChampPts,
                    lockedScorerPts,
                    lockedAssisterPts,
                  )
                      : _buildMobileLayout(
                    potentialChampPts,
                    potentialScorerPts,
                    potentialAssisterPts,
                    lockedChampPts,
                    lockedScorerPts,
                    lockedAssisterPts,
                  ),
                ),
              ),

              // ─── Sticky save button ──────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + mediaQuery.padding.bottom),
                decoration: const BoxDecoration(
                  color: AppColors.cardDark,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kButtonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.0),
                  )
                      : Text(
                    AppTranslations.get(widget.lang, 'save'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Layouts ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(int potC, int potS, int potA, int? lockC, int? lockS, int? lockA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 20),
        _buildWarningBanner(),
        _buildNameInput(),
        const SizedBox(height: 20),
        _buildFavoriteTeam(),
        const SizedBox(height: 20),
        _buildWinnerPred(potC, lockC),
        const SizedBox(height: 20),
        _buildScorerPred(potS, lockS),
        const SizedBox(height: 20),
        _buildAssisterPred(potA, lockA),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        _buildVisibilitySwitch(),
        const SizedBox(height: 12),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout(int potC, int potS, int potA, int? lockC, int? lockS, int? lockA) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildAvatarSection()),
            const SizedBox(width: 32),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWarningBanner(),
                  _buildNameInput(),
                  const SizedBox(height: 20),
                  _buildFavoriteTeam(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildWinnerPred(potC, lockC)),
            const SizedBox(width: 24),
            Expanded(child: _buildScorerPred(potS, lockS)),
            const SizedBox(width: 24),
            Expanded(child: _buildAssisterPred(potA, lockA)),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildVisibilitySwitch()),
            const SizedBox(width: 40),
            _buildActionButtons(),
          ],
        ),
      ],
    );
  }

  // ─── Sections ───────────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppTranslations.get(widget.lang, 'avatar'),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(kDialogRadius),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _avatar.isEmpty || !_avatar.contains('.png')
              ? const Icon(Icons.person, color: AppColors.textDim, size: 40)
              : Image.asset(_avatar, width: 80, height: 80, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: kAvatarOptions.map((avatarPath) {
            final isSelected = _avatar == avatarPath;
            return GestureDetector(
              onTap: () => setState(() => _avatar = avatarPath),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(avatarPath, fit: BoxFit.cover),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kButtonRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppTranslations.get(widget.lang, 'winnerScorerWarningText'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppTranslations.get(widget.lang, 'pseudoLabel')),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            fillColor: AppColors.surface,
            filled: true,
            hintText: AppTranslations.get(widget.lang, 'enterNickname'),
            hintStyle: const TextStyle(color: AppColors.textDim),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteTeam() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppTranslations.get(widget.lang, 'favoriteTeamLabel')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTeamPickerButton(
                selectedCode: _supportedTeam,
                placeholder: AppTranslations.get(widget.lang, 'chooseTeam'),
                isHighlighted: false,
                onTap: () => TeamSelectorBottomSheet.show(
                  context: context,
                  lang: widget.lang,
                  title: AppTranslations.get(widget.lang, 'chooseTeam'),
                  selectedTeamCode: _supportedTeam,
                  teamCodes: _getSortedTeams(),
                  onTeamSelected: (code) => setState(() => _supportedTeam = code),
                ),
              ),
            ),
            if (_supportedTeam != null &&
                WCAudioService.instance.isValidCountry(_supportedTeam!)) ...[
              const SizedBox(width: 8),
              _buildAnthemPlayButton(_supportedTeam!),
            ],
          ],
        ),
        if (_supportedTeam != null) ...[
          const SizedBox(height: 12),
          _buildAchievementsSection(_supportedTeam!),
        ],
      ],
    );
  }

  Widget _buildWinnerPred(int potC, int? lockC) {
    final isLocked = widget.userPreds.championCode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          '${AppTranslations.get(widget.lang, 'winnerPredLabel')} (+${isLocked ? lockC : potC} pts)',
        ),
        const SizedBox(height: 8),
        isLocked
            ? _buildLockedPredRow(widget.userPreds.championCode!, lockC!)
            : _buildTeamPickerButton(
          selectedCode: _championCode,
          placeholder: AppTranslations.get(widget.lang, 'selectWinner'),
          isHighlighted: _championCode != null,
          onTap: () => TeamSelectorBottomSheet.show(
            context: context,
            lang: widget.lang,
            title: AppTranslations.get(widget.lang, 'selectWinner'),
            selectedTeamCode: _championCode,
            teamCodes: _getSortedTeams(),
            onTeamSelected: (code) {
              Future.delayed(
                const Duration(milliseconds: 300),
                    () => _confirmChampionSelection(code),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScorerPred(int potS, int? lockS) {
    final isLocked = widget.userPreds.goldenBootPlayer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          '${AppTranslations.get(widget.lang, 'goldenBootScorer')} (+${isLocked ? lockS : potS} pts)',
        ),
        const SizedBox(height: 8),
        isLocked
            ? _buildLockedPlayerRow(widget.userPreds.goldenBootPlayer!, lockS!)
            : _buildPlayerAutocomplete(
          _scorerController,
          _scorerFocusNode,
          AppTranslations.get(widget.lang, 'searchScorer'),
        ),
      ],
    );
  }

  Widget _buildAssisterPred(int potA, int? lockA) {
    final isLocked = widget.userPreds.topAssisterPlayer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          '${AppTranslations.get(widget.lang, 'topAssister')} (+${isLocked ? lockA : potA} pts)',
        ),
        const SizedBox(height: 8),
        isLocked
            ? _buildLockedPlayerRow(widget.userPreds.topAssisterPlayer!, lockA!)
            : _buildPlayerAutocomplete(
          _assisterController,
          _assisterFocusNode,
          AppTranslations.get(widget.lang, 'searchAssister'),
        ),
      ],
    );
  }

  // ─── Reusable building blocks ──────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFlag(String code) {
    return TeamFlagWidget(code: code, width: 32, height: 22, borderRadius: 6);
  }

  Widget _buildTeamPickerButton({
    required String? selectedCode,
    required String placeholder,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isHighlighted ? AppColors.accent : AppColors.border,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          if (selectedCode != null) ...[
            _buildFlag(selectedCode),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppTranslations.getTeam(widget.lang, selectedCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                placeholder,
                style: const TextStyle(color: AppColors.textDim, fontSize: 16),
              ),
            ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textDim),
        ],
      ),
    );
  }

  Widget _buildLockedPredRow(String code, int pts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kButtonRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          _buildFlag(code),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppTranslations.getTeam(widget.lang, code),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildLockedBadge(pts),
        ],
      ),
    );
  }

  Widget _buildLockedPlayerRow(String name, int pts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kButtonRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          _buildLockedBadge(pts),
        ],
      ),
    );
  }

  Widget _buildLockedBadge(int pts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: AppColors.warning, size: 12),
          const SizedBox(width: 4),
          Text(
            '+$pts pts',
            style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAutocomplete(
      TextEditingController controller,
      FocusNode focusNode,
      String hint,
      ) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        final query = textEditingValue.text.toLowerCase();
        return kWC2026Players.where((p) => p.toLowerCase().contains(query));
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onEditingComplete) {
        // Sync initial value once, without attaching duplicate listeners on rebuild.
        if (controller.text.isNotEmpty && fieldController.text.isEmpty) {
          fieldController.text = controller.text;
        }
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          onEditingComplete: onEditingComplete,
          onChanged: (value) => controller.text = value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            fillColor: AppColors.surface,
            filled: true,
            hintText: hint,
            prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.card,
            elevation: 4,
            borderRadius: BorderRadius.circular(kButtonRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option, style: const TextStyle(color: Colors.white)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisibilitySwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            AppTranslations.get(widget.lang, 'hideFromGlobalLeaderboard'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Switch(
          value: _isHidden,
          activeThumbColor: AppColors.accent,
          onChanged: (val) => setState(() => _isHidden = val),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: _resetProfile,
          icon: const Icon(Icons.refresh, color: AppColors.danger, size: 16),
          label: Text(
            AppTranslations.get(widget.lang, 'reset'),
            style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _deleteProfile,
          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 16),
          label: Text(
            AppTranslations.get(widget.lang, 'delete'),
            style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(String teamCode) {
    final code = teamCode.toLowerCase();
    final profile = WCTeamProfileService.getProfile(code, widget.lang);
    if (profile.trophies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.get(widget.lang, 'teamAchievements'),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: profile.trophies.map((trophy) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(kButtonRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrophyBadge(trophy),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      trophy,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrophyBadge(String trophy) {
    final lower = trophy.toLowerCase();
    String? assetPath;
    IconData fallbackIcon = Icons.workspace_premium;
    Color fallbackColor = Colors.amber;

    if (lower.contains('coupe du monde') || lower.contains('world cup') || lower.contains('copa mondial')) {
      assetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('copa américa') || lower.contains('copa america')) {
      assetPath = 'assets/badges/conmebol.png';
    } else if (lower.contains('europe') || lower.contains('euro') || lower.contains('nations league') ||
        lower.contains('ligue des nations de l\'uefa') || lower.contains('liga de naciones de la uefa')) {
      if (lower.contains('uefa') || lower.contains('euro')) {
        assetPath = 'assets/badges/uefa.png';
      } else if (lower.contains('concacaf')) {
        assetPath = 'assets/badges/concacaf.png';
      }
    } else if (lower.contains('afrique des nations') || lower.contains('africa cup') ||
        lower.contains('copa africana') || lower.contains('chan')) {
      assetPath = 'assets/badges/caf.png';
    } else if (lower.contains('asie') || lower.contains('asian cup') || lower.contains('copa asiática')) {
      assetPath = 'assets/badges/afc.png';
    } else if (lower.contains('confédérations') || lower.contains('confederations')) {
      assetPath = 'assets/badges/coupe_des_confederations.png';
    } else if (lower.contains('or de la concacaf') || lower.contains('gold cup') ||
        lower.contains('copa de oro') || lower.contains('nations league concacaf') ||
        lower.contains('ligue des nations concacaf')) {
      assetPath = 'assets/badges/concacaf.png';
    } else if (lower.contains('ofc') || lower.contains('océanie') || lower.contains('oceania')) {
      assetPath = 'assets/badges/ofc.png';
    } else if (lower.contains('arabe') || lower.contains('arab cup') || lower.contains('árabe')) {
      assetPath = 'assets/logos/fifa_logo_light.png';
    } else if (lower.contains('olympique') || lower.contains('olympic') || lower.contains('olímpica')) {
      fallbackIcon = Icons.stars;
      fallbackColor = Colors.blue;
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, err, stack) => Icon(fallbackIcon, color: fallbackColor, size: 12),
      );
    }

    return Icon(fallbackIcon, color: fallbackColor, size: 12);
  }

  Widget _buildAnthemPlayButton(String teamCode) {
    final audioService = WCAudioService.instance;
    final cleanCode = teamCode.toLowerCase().replaceAll('g_', '');

    return ValueListenableBuilder<String?>(
      valueListenable: audioService.currentPlayingTeamCode,
      builder: (context, playingCode, _) {
        final isThis = playingCode == cleanCode;
        return ValueListenableBuilder<PlayerState>(
          valueListenable: audioService.playerState,
          builder: (context, state, _) {
            final isPlaying = isThis && state == PlayerState.playing;
            return ValueListenableBuilder<bool>(
              valueListenable: audioService.isLoading,
              builder: (context, loading, _) {
                if (isThis && loading) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(kButtonRadius),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  );
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => audioService.playAnthem(teamCode),
                    borderRadius: BorderRadius.circular(kButtonRadius),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isThis ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(kButtonRadius),
                        border: Border.all(
                          color: isThis ? AppColors.accent : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.music_note,
                        color: isThis ? AppColors.accent : AppColors.textMuted,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Close button (shared style with other dialogs) ─────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? tooltip;
  const _CloseButton({required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.close, color: AppColors.textDim, size: 20),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}