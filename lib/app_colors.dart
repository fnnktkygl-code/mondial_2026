import 'package:flutter/material.dart';

/// Central color palette for the entire Mondial 2026 app.
/// All UI colors must reference this class — never use raw Color(0xFF...) literals.
class AppColors {
  AppColors._();

  // ─── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0A0E1A); // Main scaffold bg
  static const Color surface        = Color(0xFF0F172A); // Elevated panels / dark wells
  static const Color card           = Color(0xFF131E35); // Standard card bg
  static const Color cardDark       = Color(0xFF0A0F1D); // Time badge / darker inset

  // ─── Borders ────────────────────────────────────────────────────────────────
  static const Color border         = Color(0xFF1E293B); // Default subtle border
  static const Color borderMid      = Color(0xFF334155); // Mid-emphasis border / divider
  static const Color borderStrong   = Color(0xFF475569); // Stronger border / inactive

  // ─── Accent – Neon Green (primary brand color) ───────────────────────────────
  static const Color accent         = Color(0xFF10B981); // Primary green accent
  static const Color accentLight    = Color(0xFFD1FAE5); // Pulse highlight / lightest green
  static const Color accentText     = Color(0xFF34D399); // Brighter green text

  // ─── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF8FAFC); // Brightest text
  static const Color textSecondary  = Color(0xFFE2E8F0); // Body text
  static const Color textBody       = Color(0xFFCBD5E1); // Secondary body
  static const Color textMuted      = Color(0xFF94A3B8); // Dimmed labels
  static const Color textDim        = Color(0xFF64748B); // Very dim / placeholder

  // ─── Semantic ───────────────────────────────────────────────────────────────
  static const Color danger         = Color(0xFFEF4444); // Errors / streak red
  static const Color warning        = Color(0xFFF59E0B); // Booster amber / rank gold
  static const Color warningYellow  = Color(0xFFEAB308); // Yellow cards
  static const Color rankGold       = Color(0xFFD97706); // Rank name / joke box
  static const Color info           = Color(0xFF3B82F6); // Away team / stats blue
  static const Color purple         = Color(0xFF8B5CF6); // Guru badge dark
  static const Color purpleLight    = Color(0xFFC084FC); // Guru badge text
}
