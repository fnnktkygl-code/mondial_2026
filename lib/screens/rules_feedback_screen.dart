import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../l10n/translations.dart';
import '../services/firebase_service.dart';

class RulesFeedbackPage extends StatefulWidget {
  final String lang;

  const RulesFeedbackPage({super.key, required this.lang});

  @override
  State<RulesFeedbackPage> createState() => _RulesFeedbackPageState();
}

class _RulesFeedbackPageState extends State<RulesFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final uid = await WCFirebaseService.getOrCreateUserId();
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': uid,
        'message': text,
        'lang': widget.lang,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _feedbackController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.lang == 'fr' ? 'Merci pour votre retour !' : 'Thank you for your feedback!'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending feedback'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppTranslations.get(widget.lang, 'rules')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: widget.lang == 'fr' ? 'Système de Points (Prise de Risque)' : 'Scoring System (Risk-Driven)',
              items: [
                _buildRuleItem(
                  '⚽', 
                  widget.lang == 'fr' ? 'Issue du Match (1N2)' : 'Match Outcome (1X2)', 
                  widget.lang == 'fr' ? '+50 pts × Cote' : '+50 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Points de base si vous trouvez le bon résultat final (Victoire 1, Nul ou Victoire 2).' 
                    : 'Base points for predicting the correct winner or draw.'
                ),
                _buildRuleItem(
                  '↔️', 
                  widget.lang == 'fr' ? 'Même Écart de Buts (GD)' : 'Same Goal Difference (GD)', 
                  widget.lang == 'fr' ? '+20 à +350 pts × Cote' : '+20 to +350 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Si l\'issue est correcte : Écart de 0 ou 1 but (+20 pts) | 2 buts (+100 pts) | 3 buts (+200 pts) | 4+ buts (+350 pts).' 
                    : 'If outcome is correct: GD of 0 or 1 (+20 pts) | 2 (+100 pts) | 3 (+200 pts) | 4+ (+350 pts).'
                ),
                _buildRuleItem(
                  '🎯', 
                  widget.lang == 'fr' ? 'SCORE EXACT (SUMMUM)' : 'EXACT SCORE (SUMMUM)', 
                  widget.lang == 'fr' ? '+200 pts × Cote × Risque' : '+200 pts × Odds × Risk',
                  description: widget.lang == 'fr' 
                    ? 'Trouver le score exact. Facteur Risque = 1.0 + (|Écart| × 0.40) + (Total Buts × 0.20) pour récompenser la prise de risque.' 
                    : 'Predicting correct score. Risk Factor = 1.0 + (|GD| × 0.40) + (Total Goals × 0.20) to reward daring scores.'
                ),
                _buildRuleItem(
                  '🔢', 
                  widget.lang == 'fr' ? 'Même Nombre Total de Buts' : 'Same Total Goals', 
                  widget.lang == 'fr' ? '+50 pts × Cote' : '+50 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Si l\'issue est correcte mais pas le score exact, et que le nombre total de buts est correct.' 
                    : 'Outcome is correct, wrong score but same total goal count.'
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.lang == 'fr' ? 'Buteurs (Multiplié par la cote équipe)' : 'Goalscorers (Multiplied by team odds)',
              items: [
                _buildRuleItem(
                  '🛡️', 
                  widget.lang == 'fr' ? 'Buteur Défenseur ou GK' : 'GK/Defender Goalscorer', 
                  widget.lang == 'fr' ? '+200 pts × Cote Équipe' : '+200 pts × Team Odds',
                  description: widget.lang == 'fr' 
                    ? 'Un défenseur ou gardien marque un but. Multiplié par la cote de son équipe.' 
                    : 'A defender or goalkeeper scores. Multiplied by their team\'s odds.'
                ),
                _buildRuleItem(
                  '🎩', 
                  widget.lang == 'fr' ? 'Buteur Milieu de Terrain' : 'Midfielder Goalscorer', 
                  widget.lang == 'fr' ? '+100 pts × Cote Équipe' : '+100 pts × Team Odds',
                  description: widget.lang == 'fr' 
                    ? 'Un milieu de terrain marque un but. Multiplié par la cote de son équipe.' 
                    : 'A midfielder scores. Multiplied by their team\'s odds.'
                ),
                _buildRuleItem(
                  '👟', 
                  widget.lang == 'fr' ? 'Buteur Attaquant' : 'Forward Goalscorer', 
                  widget.lang == 'fr' ? '+50 pts × Cote Équipe' : '+50 pts × Team Odds',
                  description: widget.lang == 'fr' 
                    ? 'Un attaquant marque un but. Multiplié par la cote de son équipe.' 
                    : 'A forward scores. Multiplied by their team\'s odds.'
                ),
                _buildRuleItem(
                  '⚽', 
                  widget.lang == 'fr' ? 'Doublé / Triplé Exact' : 'Exact Goal Tally per Scorer', 
                  widget.lang == 'fr' ? '+80 pts × Cote Équipe' : '+80 pts × Team Odds',
                  description: widget.lang == 'fr' 
                    ? 'Bonus si vous prédisez exactement le nombre de buts (ex. doublé) d\'un buteur.' 
                    : 'Bonus for predicting the exact goal count of a scorer.'
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.lang == 'fr' ? 'Bonus Multiplicateurs & Jokers' : 'Multipliers & Special Bonuses',
              items: [
                _buildRuleItem(
                  '🦁', 
                  widget.lang == 'fr' ? 'Victoire d\'un Outsider' : 'Underdog Win', 
                  widget.lang == 'fr' ? '+50 pts × Cote' : '+50 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Actif si vous pronostiquez la victoire d\'une équipe avec une probabilité < 30% (Cote > 3.33).' 
                    : 'Triggered when predicting a win for a team with < 30% probability (Odds > 3.33).'
                ),
                _buildRuleItem(
                  '🚀', 
                  widget.lang == 'fr' ? 'Joker (Booster)' : 'Booster (Joker) Active', 
                  widget.lang == 'fr' ? 'x2.0 Score / x1.5 Issue' : 'x2.0 Score / x1.5 Outcome',
                  description: widget.lang == 'fr' 
                    ? 'Allocation : 3 Jokers pour les Groupes, puis 1 par tour de Phase Finale. Double le score exact, x1.5 pour l\'issue.' 
                    : 'Jokers: 3 for Group Stage, 1 per Knockout stage. Doubles Exact Score points, x1.5 for outcome points.'
                ),
                _buildRuleItem(
                  '🔥', 
                  widget.lang == 'fr' ? 'Phase Éliminatoire (KO)' : 'Knockout Stage (KO)', 
                  widget.lang == 'fr' ? 'x1.5 Général' : 'Global x1.5 Multiplier',
                  description: widget.lang == 'fr' 
                    ? 'Tous les points accumulés lors des matchs de phase finale (hors pronos à long terme) sont multipliés par 1.5.' 
                    : 'All points earned during Knockout matches are multiplied by 1.5.'
                ),
                _buildRuleItem(
                  '⚡', 
                  widget.lang == 'fr' ? 'Vainqueur après Prolongations' : 'Extra-Time Winner (AET)', 
                  widget.lang == 'fr' ? '+150 pts × Cote' : '+150 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Pronostiquer le vainqueur exact pendant les prolongations (phase finale uniquement).' 
                    : 'Predict the winner during Extra Time (knockout stage only).'
                ),
                _buildRuleItem(
                  '🥅', 
                  widget.lang == 'fr' ? 'Vainqueur aux Tirs au But' : 'Penalty Shootout Winner', 
                  widget.lang == 'fr' ? '+200 pts × Cote' : '+200 pts × Odds',
                  description: widget.lang == 'fr' 
                    ? 'Pronostiquer le vainqueur de la séance de tirs au but (phase finale uniquement).' 
                    : 'Predict the winner of the penalty shootout (knockout stage only).'
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.lang == 'fr' ? 'Pronostics à Long Terme' : 'Tournament Predictions',
              items: [
                _buildRuleItem(
                  '🏆', 
                  widget.lang == 'fr' ? 'Champion Mondial' : 'Tournament Champion', 
                  widget.lang == 'fr' ? 'Jusqu\'à +1000 pts' : 'Up to +1000 pts',
                  description: widget.lang == 'fr' 
                    ? 'Deviner le Champion du Monde 2026. Soumis à une dégradation de points selon la phase (Time Decay).' 
                    : 'Predicting the World Champion. Multiplied by time decay based on when you predict.'
                ),
                _buildRuleItem(
                  '👟', 
                  widget.lang == 'fr' ? 'Meilleur Buteur' : 'Golden Boot Winner', 
                  widget.lang == 'fr' ? 'Jusqu\'à +500 pts' : 'Up to +500 pts',
                  description: widget.lang == 'fr' 
                    ? 'Deviner le meilleur buteur du tournoi. Soumis à une dégradation de points selon la phase (Time Decay).' 
                    : 'Predicting the Golden Boot winner. Multiplied by time decay based on when you predict.'
                ),
                _buildRuleItem(
                  '⏳', 
                  widget.lang == 'fr' ? 'Dégradation Temporelle' : 'Time Decay Multiplier', 
                  widget.lang == 'fr' ? 'x1.0 à x0.0' : 'x1.0 to x0.0',
                  description: widget.lang == 'fr' 
                    ? 'Avant tournoi (x1.0) | Poules (x0.8) | 16èmes (x0.6) | 8èmes (x0.4) | Quarts (x0.2) | Demi-finales/Finales (x0.0).' 
                    : 'Before tournament (x1.0) | Groups (x0.8) | R32 (x0.6) | R16 (x0.4) | Quarter-finals (x0.2) | Semi/Finals (x0.0).'
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.lang == 'fr' ? 'Verrouillages & Rangs' : 'Timing & Ranks',
              items: [
                _buildRuleItem(
                  '🔒', 
                  widget.lang == 'fr' ? 'Fermeture des Pronostics' : 'Prediction Locking', 
                  widget.lang == 'fr' ? '5 min avant coup d\'envoi' : '5 min before kickoff',
                  description: widget.lang == 'fr' 
                    ? 'Tous les pronostics de match verrouillent 5 minutes avant le début du match. Champion/Buteur verrouillent avant la phase finale.' 
                    : 'Match predictions lock 5 mins before kickoff. Tournament predictions lock before the first KO match.'
                ),
                _buildRuleItem(
                  '📈', 
                  widget.lang == 'fr' ? 'Niveaux d\'Expérience (XP)' : 'XP Levels & Ranks', 
                  widget.lang == 'fr' ? '1 point = 1 XP' : '1 point = 1 XP',
                  description: widget.lang == 'fr' 
                    ? 'Rookie (0-100 XP) | Pro Tactician (100-300 XP) | Master Analyst (300-600 XP) | Special One (600+ XP).' 
                    : 'Rookie (0-100 XP) | Pro Tactician (100-300 XP) | Master Analyst (300-600 XP) | Special One (600+ XP).'
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),
            Text(
              widget.lang == 'fr' ? 'Une suggestion ou un bug ?' : 'A suggestion or a bug?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.lang == 'fr' ? 'Dites-moi comment améliorer l\'app ou si les points devraient être différents !' : 'Tell me how to improve the app or if points should be different!',
              style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.lang == 'fr' ? 'Votre message...' : 'Your message...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.background)))
                    : Text(widget.lang == 'fr' ? 'Envoyer mon avis' : 'Send my feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String emoji, String label, String value, {String? description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label, 
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                description,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
