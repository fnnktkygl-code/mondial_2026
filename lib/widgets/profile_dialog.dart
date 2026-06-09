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

/// Chemins vers les images locales pour l avatar.
final List<String> kAvatarOptions = List.generate(32, (index) => 'assets/avatars/${index + 1}.png');

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
    _scorerController = TextEditingController(text: widget.userPreds.goldenBootPlayer ?? '');
    _assisterController = TextEditingController(text: widget.userPreds.topAssisterPlayer ?? '');
    _supportedTeam = widget.userPreds.supportedTeam;
    _championCode = widget.userPreds.championCode;
    _avatar = widget.userPreds.avatar;
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final hidden = await WCFirebaseService.getProfileVisibility();
    if (mounted) {
      setState(() {
        _isHidden = hidden;
      });
    }
  }

  Future<void> _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppTranslations.get(widget.lang, 'resetProfile') ?? 'Reset Profile', style: const TextStyle(color: Colors.white)),
          content: Text(
            AppTranslations.get(widget.lang, 'resetProfileConfirm'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppTranslations.get(widget.lang, 'reset') ?? 'Reset', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      print("[DEBUG RESET] Début du nettoyage du profil...");
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

      if (mounted) {
        widget.onSupportedTeamChanged(null);
        widget.onSaved();
        print("[DEBUG RESET] Profil réinitialisé localement et synchronisé sur Firebase.");
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppTranslations.get(widget.lang, 'deleteProfile') ?? 'Delete Profile', style: const TextStyle(color: Colors.white)),
          content: Text(
            AppTranslations.get(widget.lang, 'deleteProfileConfirm'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppTranslations.get(widget.lang, 'delete') ?? 'Delete', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      print("[DEBUG DELETE] Début de suppression du compte...");
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

      if (mounted) {
        widget.onSupportedTeamChanged(null);
        widget.onSaved();
        print("[DEBUG DELETE] Compte supprimé et nettoyé.");
        Navigator.of(context).pop();
      }
    }
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

  Widget _buildFlag(String code) {
    return TeamFlagWidget(
      code: code,
      width: 32,
      height: 22,
      borderRadius: 6,
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
    } else if (lower.contains('europe') || lower.contains('euro') || lower.contains('nations league') || lower.contains('ligue des nations de l\'uefa') || lower.contains('liga de naciones de la uefa')) {
      if (lower.contains('uefa') || lower.contains('euro')) {
        assetPath = 'assets/badges/uefa.png';
      } else if (lower.contains('concacaf')) {
        assetPath = 'assets/badges/concacaf.png';
      }
    } else if (lower.contains('afrique des nations') || lower.contains('africa cup') || lower.contains('copa africana') || lower.contains('chan')) {
      assetPath = 'assets/badges/caf.png';
    } else if (lower.contains('asie') || lower.contains('asian cup') || lower.contains('copa asiática')) {
      assetPath = 'assets/badges/afc.png';
    } else if (lower.contains('confédérations') || lower.contains('confederations')) {
      assetPath = 'assets/badges/coupe_des_confederations.png';
    } else if (lower.contains('or de la concacaf') || lower.contains('gold cup') || lower.contains('copa de oro') || lower.contains('nations league concacaf') || lower.contains('ligue des nations concacaf')) {
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

  Widget _buildAchievementsSection(String teamCode) {
    final code = teamCode.toLowerCase();
    final profile = WCTeamProfileService.getProfile(code, widget.lang);
    if (profile.trophies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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

  List<String> _getSortedTeams() {
    final Set<String> qualifiedCodes = {};
    for (final m in widget.matches) {
      bool isValidCountryCode(String code) {
        final c = code.toLowerCase();
        if (c == 'tbd') return false;
        if (c.contains(RegExp(r'[0-9]'))) return false;
        if ((c.startsWith('w') || c.startsWith('l')) && c.length > 3) return false;
        return true;
      }

      if (isValidCountryCode(m.t1)) qualifiedCodes.add(m.t1.toLowerCase());
      if (isValidCountryCode(m.t2)) qualifiedCodes.add(m.t2.toLowerCase());
    }

    final resultList = qualifiedCodes.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));

    print("[DEBUG TEAMS] _getSortedTeams généré avec succès. Nombre de pays qualifiés détectés : ${resultList.length}");
    return resultList;
  }

  Future<void> _confirmChampionSelection(String selectedCode) async {
    print("[DEBUG CONFIRM] Ouverture du dialogue de confirmation pour le code pays : $selectedCode");
    final teamName = AppTranslations.getTeam(widget.lang, selectedCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
          title: Text(
            AppTranslations.get(widget.lang, 'confirmWinnerTitle'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.get(widget.lang, 'confirmWinnerMsg'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFlag(selectedCode),
                  const SizedBox(width: 10),
                  Text(
                    teamName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print("[DEBUG CONFIRM] Clic sur Annuler.");
                Navigator.of(context).pop(false);
              },
              child: Text(
                AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print("[DEBUG CONFIRM] Clic sur Confirmer.");
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
              ),
              child: Text(
                AppTranslations.get(widget.lang, 'confirm'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    print("[DEBUG CONFIRM] Fenêtre fermée. Résultat de la confirmation (confirmed) : $confirmed");

    if (!mounted) return;

    if (confirmed == true) {
      setState(() {
        _championCode = selectedCode;
        print("[DEBUG STATE] _championCode mis à jour localement avec succès : $_championCode");
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    print("[DEBUG SAVE] Bouton global Enregistrer cliqué.");

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'nicknameEmpty'));
      return;
    }

    final scorerInput = _scorerController.text.trim();
    final bool isNewScorer = widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty;

    final assisterInput = _assisterController.text.trim();
    final bool isNewAssister = widget.userPreds.topAssisterPlayer == null && assisterInput.isNotEmpty;

    if (isNewScorer && !kWC2026Players.contains(scorerInput)) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'scorerNotFound'));
      return;
    }
    if (isNewAssister && !kWC2026Players.contains(assisterInput)) {
      widget.showSnackBar(AppTranslations.get(widget.lang, 'assisterNotFound'));
      return;
    }

    if (isNewScorer || isNewAssister) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
            title: Text(
              AppTranslations.get(widget.lang, 'confirmPredictions'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              AppTranslations.get(widget.lang, 'confirmPredictionsWarning'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppTranslations.get(widget.lang, 'cancel'), style: const TextStyle(color: AppColors.textDim)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                ),
                child: Text(
                  AppTranslations.get(widget.lang, 'confirm'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isSaving = true;
    });

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

      print("[DEBUG SAVE] Sauvegarde locale JSON via PredictionService...");
      await PredictionService.savePredictionData(widget.userPreds);

      final totalPoints = PredictionService.calculateTotalPoints(widget.userPreds, widget.matches);
      final streak = PredictionService.calculateActiveStreak(widget.userPreds, widget.matches);
      final guruCount = PredictionService.calculateExactGuessesCount(widget.userPreds, widget.matches);

      print("[DEBUG SAVE] Envoi et synchronisation Firestore en cours...");
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
      print("[DEBUG SAVE] Sauvegarde terminée avec succès, fermeture de la boîte de dialogue.");
      Navigator.of(context).pop();
    } catch (e) {
      print("[DEBUG SAVE ERROR] Échec lors de la sauvegarde : $e");
      widget.showSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final potentialChampPts = PredictionService.getPotentialChampionPoints(DateTime.now(), widget.matches);
    final potentialScorerPts = PredictionService.getPotentialGoldenBootPoints(DateTime.now(), widget.matches);
    final potentialAssisterPts = PredictionService.getPotentialTopAssisterPoints(DateTime.now(), widget.matches);
    final lockedChampPts = widget.userPreds.championCode != null
        ? PredictionService.getPotentialChampionPoints(widget.userPreds.championPredictedAt, widget.matches)
        : null;
    final lockedScorerPts = widget.userPreds.goldenBootPlayer != null
        ? PredictionService.getPotentialGoldenBootPoints(widget.userPreds.goldenBootPredictedAt, widget.matches)
        : null;
    final lockedAssisterPts = widget.userPreds.topAssisterPlayer != null
        ? PredictionService.getPotentialTopAssisterPoints(widget.userPreds.topAssisterPredictedAt, widget.matches)
        : null;

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.get(widget.lang, 'profileTitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textDim),
                    tooltip: AppTranslations.get(widget.lang, 'close'),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),

              Text(
                AppTranslations.get(widget.lang, 'avatar'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kDialogRadius),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _avatar.isEmpty || !_avatar.contains('.png')
                      ? const Icon(Icons.person, color: AppColors.textDim, size: 32)
                      : Image.asset(
                    _avatar,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textDim, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: kAvatarOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final avatarPath = entry.value;
                  final isSelected = _avatar == avatarPath;
                  return Semantics(
                    label: '${AppTranslations.get(widget.lang, 'avatar')} ${index + 1}',
                    selected: isSelected,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _avatar = avatarPath),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: isSelected ? 2 : 1),
                        ),
                        alignment: Alignment.center,
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          avatarPath,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 24, color: AppColors.textDim),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Container(
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
              ),

              Text(
                AppTranslations.get(widget.lang, 'pseudoLabel'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
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
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                AppTranslations.get(widget.lang, 'favoriteTeamLabel'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                      ),
                      onPressed: () {
                        print("[DEBUG BUTTON] Clic sur le bouton de sélection de l'Équipe Favorite.");
                        TeamSelectorBottomSheet.show(
                          context: context,
                          lang: widget.lang,
                          title: AppTranslations.get(widget.lang, 'chooseTeam'),
                          selectedTeamCode: _supportedTeam,
                          teamCodes: _getSortedTeams(),
                          onTeamSelected: (code) {
                            print("[DEBUG BOTTOMSHEET] Équipe Favorite choisie dans le menu déroulant : $code");
                            setState(() {
                              _supportedTeam = code;
                            });
                          },
                        );
                      },
                      child: Row(
                        children: [
                          if (_supportedTeam != null) ...[
                            _buildFlag(_supportedTeam!),
                            const SizedBox(width: 12),
                            Text(
                              AppTranslations.getTeam(widget.lang, _supportedTeam!),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ] else ...[
                            Text(
                              AppTranslations.get(widget.lang, 'chooseTeam'),
                              style: const TextStyle(color: AppColors.textDim, fontSize: 16),
                            ),
                          ],
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textDim),
                        ],
                      ),
                    ),
                  ),
                  if (_supportedTeam != null && WCAudioService.instance.isValidCountry(_supportedTeam!)) ...[
                    const SizedBox(width: 8),
                    _buildAnthemPlayButton(_supportedTeam!),
                  ],
                ],
              ),
              if (_supportedTeam != null) ...[
                const SizedBox(height: 12),
                _buildAchievementsSection(_supportedTeam!),
              ],
              const SizedBox(height: 20),

              Text(
                AppTranslations.get(widget.lang, 'winnerPredLabel') +
                    (widget.userPreds.championCode != null
                        ? ' (+$lockedChampPts pts max)'
                        : ' (Actuel : +$potentialChampPts pts max)'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              widget.userPreds.championCode != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(kButtonRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    _buildFlag(widget.userPreds.championCode!),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppTranslations.getTeam(widget.lang, widget.userPreds.championCode!),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
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
                            '+$lockedChampPts pts',
                            style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: _championCode != null ? AppColors.accent : AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                ),
                onPressed: () {
                  print("[DEBUG BUTTON] Clic détecté sur le bouton du Vainqueur du tournoi.");
                  TeamSelectorBottomSheet.show(
                    context: context,
                    lang: widget.lang,
                    title: AppTranslations.get(widget.lang, 'selectWinner'),
                    selectedTeamCode: _championCode,
                    teamCodes: _getSortedTeams(),
                    onTeamSelected: (code) {
                      print("[DEBUG BOTTOMSHEET] Équipe gagnante sélectionnée dans la liste : $code");
                      // Introduction d'un délai pour laisser le menu se fermer proprement
                      Future.delayed(const Duration(milliseconds: 300), () {
                        print("[DEBUG DELAY] Fin du délai d'attente de fermeture, appel du dialogue de confirmation.");
                        _confirmChampionSelection(code);
                      });
                    },
                  );
                },
                child: Row(
                  children: [
                    if (_championCode != null) ...[
                      _buildFlag(_championCode!),
                      const SizedBox(width: 12),
                      Text(AppTranslations.getTeam(widget.lang, _championCode!),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ] else ...[
                      Text(AppTranslations.get(widget.lang, 'selectWinner'),
                          style: const TextStyle(color: AppColors.textDim, fontSize: 16)),
                    ],
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textDim),
                  ],
                ),
              ),

              if (_championCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppTranslations.get(widget.lang, 'choiceFinalWarning'),
                        style: const TextStyle(color: AppColors.warning, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Text(
                (AppTranslations.get(widget.lang, 'goldenBootScorer')) +
                    (widget.userPreds.goldenBootPlayer != null
                        ? ' (+$lockedScorerPts pts max)'
                        : ' (Actuel : +$potentialScorerPts pts max)'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              widget.userPreds.goldenBootPlayer != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(kButtonRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.userPreds.goldenBootPlayer!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
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
                            '+$lockedScorerPts pts',
                            style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return kWC2026Players.where((p) => p.toLowerCase().contains(query));
                    },
                    onSelected: (selection) => _scorerController.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      if (_scorerController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = _scorerController.text;
                      }
                      controller.addListener(() => _scorerController.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          fillColor: AppColors.surface,
                          filled: true,
                          hintText: AppTranslations.get(widget.lang, 'searchScorer'),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.sports_soccer, color: AppColors.accent, size: 16),
                                  title: Text(option, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                (AppTranslations.get(widget.lang, 'topAssister')) +
                    (widget.userPreds.topAssisterPlayer != null
                        ? ' (+$lockedAssisterPts pts max)'
                        : ' (Actuel : +$potentialAssisterPts pts max)'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              widget.userPreds.topAssisterPlayer != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.userPreds.topAssisterPlayer!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
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
                            '+$lockedAssisterPts pts',
                            style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return kWC2026Players.where((p) => p.toLowerCase().contains(query));
                    },
                    onSelected: (selection) => _assisterController.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      if (_assisterController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = _assisterController.text;
                      }
                      controller.addListener(() => _assisterController.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          fillColor: AppColors.surface,
                          filled: true,
                          hintText: AppTranslations.get(widget.lang, 'searchAssister'),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.get(widget.lang, 'hideFromGlobalLeaderboard'),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Switch(
                    value: _isHidden,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() {
                        _isHidden = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _resetProfile,
                    icon: const Icon(Icons.refresh, color: AppColors.danger, size: 16),
                    label: Text(
                      AppTranslations.get(widget.lang, 'reset') ?? 'Reset',
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _deleteProfile,
                    icon: const Icon(Icons.delete, color: AppColors.danger, size: 16),
                    label: Text(
                      AppTranslations.get(widget.lang, 'delete') ?? 'Delete',
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.0))
                    : Text(AppTranslations.get(widget.lang, 'save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnthemPlayButton(String teamCode) {
    final audioService = WCAudioService.instance;
    return ValueListenableBuilder<String?>(
      valueListenable: audioService.currentPlayingTeamCode,
      builder: (context, playingCode, _) {
        final isThis = playingCode == teamCode.toLowerCase().replaceAll('g_', '');
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
                        border: Border.all(color: isThis ? AppColors.accent : AppColors.border, width: 1.5),
                      ),
                      child: Icon(isPlaying ? Icons.pause_rounded : Icons.music_note, color: isThis ? AppColors.accent : AppColors.textMuted, size: 26),
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