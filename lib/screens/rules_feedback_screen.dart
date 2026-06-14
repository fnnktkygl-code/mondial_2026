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
              title: widget.lang == 'fr' ? 'Système de Points (Haute Intensité)' : 'High-Stakes Scoring System',
              items: [
                _buildRuleItem('⚽', widget.lang == 'fr' ? 'Victoire ou Nul (1N2)' : 'Correct Outcome', '+50 pts'),
                _buildRuleItem('↔️', widget.lang == 'fr' ? 'Bon écart (ex: 3-0)' : 'GD Bonus (e.g. 3-0)', '+20 à +120 pts'),
                _buildRuleItem('🎯', widget.lang == 'fr' ? 'SCORE EXACT (SUMMUM)' : 'EXACT SCORE (SUMMUM)', '+150 pts'),
                _buildRuleItem('🛡️', widget.lang == 'fr' ? 'Buteur Défenseur' : 'Defender Scorer', '+120 pts'),
                _buildRuleItem('👟', widget.lang == 'fr' ? 'Buteur Attaquant' : 'Forward Scorer', '+30 pts'),
                _buildRuleItem('🔢', widget.lang == 'fr' ? 'Doublé/Triplé exact' : 'Exact Goal Tally', '+50 pts'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.lang == 'fr' ? 'Prise de risque' : 'Risk & Precision',
              items: [
                _buildRuleItem('📈', widget.lang == 'fr' ? 'Écart de 3+ buts' : '3+ Goal Difference', '+30 pts'),
                _buildRuleItem('🦁', widget.lang == 'fr' ? 'Victoire Outsider' : 'Outsider Victory', '+15 pts'),
                _buildRuleItem('🔥', 'Knockout Stage', 'x1.25 Multiplier'),
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

  Widget _buildRuleItem(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
