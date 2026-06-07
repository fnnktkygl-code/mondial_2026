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
  String? _supportedTeam;
  String? _championCode;
  String _avatar = '';
  bool _isSaving = false;
  bool _isHidden = false;
  List<String> _scorerSuggestions = [];
  final FocusNode _scorerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userPreds.username);
    _scorerController = TextEditingController(text: widget.userPreds.goldenBootPlayer ?? '');
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
            widget.lang == 'fr'
            ? 'Êtes-vous sûr de vouloir réinitialiser toutes vos prédictions ? Les matchs déjà joués ne pourront pas être pronostiqués de nouveau et vous perdrez tous vos points.'
            : 'Are you sure you want to reset all your predictions? Played matches cannot be predicted again, and you will lose all points.',
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
      widget.userPreds.matchPredictions.clear();
      widget.userPreds.championCode = null;
      widget.userPreds.goldenBootPlayer = null;
      widget.userPreds.goldenBootWinner = null;
      widget.userPreds.boosterMatchId = null;
      await PredictionService.savePredictionData(widget.userPreds);

      await WCFirebaseService.syncUserProfile(
        username: widget.userPreds.username,
        supportedTeam: widget.userPreds.supportedTeam,
        points: 0,
        streak: 0,
        guruCount: 0,
        avatar: widget.userPreds.avatar,
        isHidden: _isHidden,
      );

      if (mounted) {
        widget.onSaved();
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
            widget.lang == 'fr'
            ? 'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.'
            : 'Are you sure you want to permanently delete your account? This action cannot be undone.',
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
      widget.userPreds.matchPredictions.clear();
      widget.userPreds.championCode = null;
      widget.userPreds.goldenBootPlayer = null;
      widget.userPreds.goldenBootWinner = null;
      widget.userPreds.boosterMatchId = null;
      widget.userPreds.username = '';
      widget.userPreds.avatar = '';
      await PredictionService.savePredictionData(widget.userPreds);

      await WCFirebaseService.deleteUserProfile();

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scorerController.dispose();
    _scorerFocusNode.dispose();
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
      final Widget img = Image.asset(
        assetPath,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, err, stack) => Icon(fallbackIcon, color: fallbackColor, size: 12),
      );

      return img;
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
          widget.lang == 'fr'
              ? 'Palmarès de l\'équipe :'
              : (widget.lang == 'es' ? 'Palmarés del equipo:' : 'Team Achievements:'),
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
    final teams = WCTeamProfileService.allTeams;
    return teams.toList()
      ..sort((a, b) => AppTranslations.getTeam(widget.lang, a)
          .compareTo(AppTranslations.getTeam(widget.lang, b)));
  }

  Future<void> _confirmChampionSelection(String selectedCode) async {
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
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppTranslations.get(widget.lang, 'cancel'),
                style: const TextStyle(color: AppColors.textDim),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
              ),
              child: Text(
                widget.lang == 'fr' ? 'Confirmer' : (widget.lang == 'es' ? 'Confirmar' : 'Confirm'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      setState(() {
        _championCode = selectedCode;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      widget.showSnackBar(widget.lang == 'fr' ? 'Le pseudo ne peut pas être vide' : 'Nickname cannot be empty');
      return;
    }

    final scorerInput = _scorerController.text.trim();
    final bool isNewScorer = widget.userPreds.goldenBootPlayer == null && scorerInput.isNotEmpty;

    // Validate that the player is in the official FIFA list
    if (isNewScorer && !kWC2026Players.contains(scorerInput)) {
      widget.showSnackBar(widget.lang == 'fr'
          ? 'Joueur introuvable dans la liste officielle FIFA. Veuillez en sélectionner un dans la liste.'
          : (widget.lang == 'es'
          ? 'Jugador no encontrado en la lista oficial de la FIFA. Por favor selecciona uno de la lista.'
          : 'Player not found in the official FIFA list. Please select one from the list.'));
      return;
    }

    if (isNewScorer) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDialogRadius)),
            title: Text(
              widget.lang == 'fr' ? 'Confirmer le meilleur buteur' : (widget.lang == 'es' ? 'Confirmar máximo goleador' : 'Confirm Golden Boot Scorer'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              widget.lang == 'fr'
                  ? 'Attention, votre pronostic pour le meilleur buteur ($scorerInput) ne pourra plus être modifié par la suite.'
                  : (widget.lang == 'es'
                  ? 'Atención, su pronóstico para el máximo goleador ($scorerInput) no podrá ser modificado después.'
                  : 'Attention, your prediction for the top scorer ($scorerInput) cannot be modified after this.'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                ),
                child: Text(
                  widget.lang == 'fr' ? 'Confirmer' : (widget.lang == 'es' ? 'Confirmar' : 'Confirm'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }
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

      await PredictionService.savePredictionData(widget.userPreds);

      final totalPoints = PredictionService.calculateTotalPoints(widget.userPreds, widget.matches);
      final streak = PredictionService.calculateActiveStreak(widget.userPreds, widget.matches);
      final guruCount = PredictionService.calculateExactGuessesCount(widget.userPreds, widget.matches);

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
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedTeams = _getSortedTeams();
    final potentialChampPts = PredictionService.getPotentialChampionPoints(DateTime.now(), widget.matches);
    final potentialScorerPts = PredictionService.getPotentialGoldenBootPoints(DateTime.now(), widget.matches);
    final lockedChampPts = widget.userPreds.championCode != null
        ? PredictionService.getPotentialChampionPoints(widget.userPreds.championPredictedAt, widget.matches)
        : null;
    final lockedScorerPts = widget.userPreds.goldenBootPlayer != null
        ? PredictionService.getPotentialGoldenBootPoints(widget.userPreds.goldenBootPredictedAt, widget.matches)
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                widget.lang == 'fr'
                    ? 'Avatar'
                    : (widget.lang == 'es' ? 'Avatar' : 'Avatar'),
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
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
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
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
                        widget.lang == 'fr'
                            ? '⚠️ Attention : Vainqueur et Meilleur Buteur sont définitifs après validation. Vous pouvez attendre, mais vos points potentiels diminuent avec le temps (100% avant le 1er match, puis 80% en poules, tombant à 0% en demi-finales).'
                            : (widget.lang == 'es'
                            ? '⚠️ Atención: El Ganador y el Máximo Goleador son definitivos una vez guardados. Puedes enviarlos más tarde, pero los puntos potenciales disminuyen con el tiempo (100% antes del partido 1, 80% en grupos, decayendo al 0% en semifinales).'
                            : '⚠️ Warning: Winner and Top Scorer are locked once saved. You can submit them later, but potential points decrease over time (100% before match 1, 80% in groups, decaying to 0% in semi-finals).'),
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
                  hintText: widget.lang == 'fr' ? 'Entrez votre pseudo...' : 'Enter your nickname...',
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
              const SizedBox(height: 20),

              Text(
                AppTranslations.get(widget.lang, 'favoriteTeamLabel'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        TeamSelectorBottomSheet.show(
                          context: context,
                          lang: widget.lang,
                          title: AppTranslations.get(widget.lang, 'chooseTeam'),
                          selectedTeamCode: _supportedTeam,
                          teamCodes: sortedTeams,
                          onTeamSelected: (code) {
                            setState(() {
                              _supportedTeam = code;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(kButtonRadius),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
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
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
                          ],
                        ),
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
                  : GestureDetector(
                      onTap: () {
                        TeamSelectorBottomSheet.show(
                          context: context,
                          lang: widget.lang,
                          title: AppTranslations.get(widget.lang, 'selectWinner'),
                          selectedTeamCode: _championCode,
                          teamCodes: sortedTeams,
                          onTeamSelected: (code) {
                            _confirmChampionSelection(code);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(kButtonRadius),
                          border: Border.all(
                            color: _championCode != null ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_championCode != null) ...[
                              _buildFlag(_championCode!),
                              const SizedBox(width: 12),
                              Text(
                                AppTranslations.getTeam(widget.lang, _championCode!),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Text(
                                AppTranslations.get(widget.lang, 'selectWinner'),
                                style: const TextStyle(color: AppColors.textDim, fontSize: 16),
                              ),
                            ],
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
                          ],
                        ),
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
                        widget.lang == 'fr'
                            ? 'Ce choix sera définitif après enregistrement.'
                            : (widget.lang == 'es' ? 'Esta elección será definitiva después de guardar.' : 'This choice will be final after saving.'),
                        style: const TextStyle(color: AppColors.warning, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              Text(
                (widget.lang == 'fr' ? 'Meilleur Buteur' : (widget.lang == 'es' ? 'Máximo Goleador' : 'Golden Boot Scorer')) +
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
                  // ── Autocomplete depuis la liste officielle FIFA ──
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return kWC2026Players.where(
                            (player) => player.toLowerCase().contains(query),
                      );
                    },
                    onSelected: (String selection) {
                      _scorerController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Sync our controller with the Autocomplete internal controller
                      if (_scorerController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = _scorerController.text;
                      }
                      controller.addListener(() {
                        _scorerController.text = controller.text;
                      });
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          fillColor: AppColors.surface,
                          filled: true,
                          hintText: widget.lang == 'fr'
                              ? 'Rechercher un joueur...'
                              : (widget.lang == 'es' ? 'Buscar un jugador...' : 'Search a player...'),
                          hintStyle: const TextStyle(color: AppColors.textDim),
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
                                  title: Text(
                                    option,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lang == 'fr'
                        ? '${kWC2026Players.length} joueurs officiels — liste FIFA Coupe du Monde 2026'
                        : (widget.lang == 'es'
                        ? '${kWC2026Players.length} jugadores oficiales — lista FIFA Copa del Mundo 2026'
                        : '${kWC2026Players.length} official players — FIFA World Cup 2026 list'),
                    style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.lang == 'fr'
                              ? 'Ce choix sera définitif après enregistrement.'
                              : (widget.lang == 'es' ? 'Esta elección será definitiva después de guardar.' : 'This choice will be final after saving.'),
                          style: const TextStyle(color: AppColors.warning, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.lang == 'fr' ? 'Masquer du classement global' : 'Hide from global leaderboard',
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