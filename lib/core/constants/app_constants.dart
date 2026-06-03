import 'package:flutter/material.dart';

/// App color palette — "Cream & Gold" light theme.
/// Names preserved for backwards compatibility; values flipped to a light
/// palette so existing screens inherit the new theme without changes.
class AppColors {
  AppColors._();

  // Backgrounds — true white. Cream is strictly an accent.
  static const richBlack = Color(0xFFFFFFFF);    // app background (pure white)
  static const deepCharcoal = Color(0xFFFFFFFF); // card / surface (pure white)

  // Gold accents (preserved)
  static const metallicGold = Color(0xFFD4AF37);
  static const softGold = Color(0xFFE8C66B);
  static const darkGold = Color(0xFFA67C00);

  // "cream" kept for compatibility but repointed to white + pale gold —
  // we no longer use a true cream anywhere in the app.
  static const cream = Color(0xFFFFFFFF);           // = white
  static const creamSoft = Color(0xFFFBF3DE);       // very faint gold wash
  static const heroBlack = Color(0xFF0A0A0A);       // hero / continue card
  static const heroBlackSoft = Color(0xFF1A1A1A);   // gradient end
  // Secondary accent — gold (replaces the old mint/green).
  static const mint = Color(0xFFFBF0CE);            // pale gold badge bg
  static const mintDeep = Color(0xFFA67C00);        // deep gold badge text

  // Borders / dividers (dark on light)
  static const glassWhite = Color.fromRGBO(0, 0, 0, 0.03);
  static const glassBorder = Color.fromRGBO(0, 0, 0, 0.08);

  // Status colors (unchanged)
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFFFB300);

  // Text (flipped — dark on cream)
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textTertiary = Color(0xFF9A9A9A);

  // Inverted text for use on dark hero cards
  static const textOnHero = Color(0xFFFFFFFF);
  static const textOnHeroMuted = Color(0xFFB0B0B0);
}

/// App spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// App border radius constants
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
}

/// App durations for animations
class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}

/// Quiz passing threshold
class AppConfig {
  AppConfig._();

  static const double quizPassThreshold = 0.8; // 80%
  static const int dailyChallengeQuestions = 7;
  static const int surahQuizQuestionsMin = 8;
  static const int surahQuizQuestionsMax = 12;
  static const int topicPracticeQuestions = 10;
}
