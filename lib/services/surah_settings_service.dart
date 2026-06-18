import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available Arabic font families for the Quran reader.
/// Each maps to a Google Fonts entry so we don't need to bundle font files.
enum SurahFontFamily {
  amiri('Amiri', 'Amiri — classic Naskh'),
  notoNaskh('Noto Naskh Arabic', 'Noto Naskh — modern clean'),
  scheherazade('Scheherazade New', 'Scheherazade — traditional Quranic'),
  reemKufi('Reem Kufi', 'Reem Kufi — geometric');

  const SurahFontFamily(this.displayName, this.description);
  final String displayName;
  final String description;

  static SurahFontFamily fromKey(String? key) {
    return SurahFontFamily.values.firstWhere(
      (f) => f.name == key,
      orElse: () => SurahFontFamily.amiri,
    );
  }
}

/// Reader-screen display settings: Arabic font size, font family, and the
/// tajweed coloring toggle.
///
/// Backed by SharedPreferences. Notifies listeners on change so widgets can
/// rebuild instantly.
class SurahSettingsService extends ChangeNotifier {
  SurahSettingsService._();
  static final instance = SurahSettingsService._();

  static const _kFontSizeKey = 'surah_arabic_font_size';
  static const _kFontFamilyKey = 'surah_arabic_font_family';
  static const _kTajweedKey = 'surah_tajweed_enabled';

  static const double defaultFontSize = 26;
  static const double minFontSize = 18;
  static const double maxFontSize = 42;

  bool _loaded = false;
  double _arabicFontSize = defaultFontSize;
  SurahFontFamily _arabicFontFamily = SurahFontFamily.amiri;
  bool _tajweedEnabled = false;

  double get arabicFontSize => _arabicFontSize;
  SurahFontFamily get arabicFontFamily => _arabicFontFamily;
  bool get tajweedEnabled => _tajweedEnabled;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _arabicFontSize = prefs.getDouble(_kFontSizeKey) ?? defaultFontSize;
    _arabicFontFamily =
        SurahFontFamily.fromKey(prefs.getString(_kFontFamilyKey));
    _tajweedEnabled = prefs.getBool(_kTajweedKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setArabicFontSize(double size) async {
    _arabicFontSize = size.clamp(minFontSize, maxFontSize);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSizeKey, _arabicFontSize);
  }

  Future<void> setArabicFontFamily(SurahFontFamily family) async {
    _arabicFontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontFamilyKey, family.name);
  }

  Future<void> setTajweedEnabled(bool enabled) async {
    _tajweedEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTajweedKey, enabled);
  }

  Future<void> toggleTajweed() => setTajweedEnabled(!_tajweedEnabled);

  /// Build a [TextStyle] for Arabic display using the current font family
  /// and the requested [fontSize] / [color]. Goes through google_fonts so
  /// the font is fetched lazily on first use and cached.
  TextStyle arabicTextStyle({
    required Color color,
    double? fontSize,
    double? height,
  }) {
    return copyArabicWith(
      _arabicFontFamily,
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }

  /// Build a [TextStyle] for an explicit font family (used for preview chips
  /// in the settings sheet so each row can render its own font).
  TextStyle copyArabicWith(
    SurahFontFamily family, {
    Color color = const Color(0xFF1A1A1A),
    double? fontSize,
    double? height,
  }) {
    final base = TextStyle(
      fontSize: fontSize ?? _arabicFontSize,
      color: color,
      height: height ?? 2.2,
    );
    switch (family) {
      case SurahFontFamily.amiri:
        return GoogleFonts.amiri(textStyle: base);
      case SurahFontFamily.notoNaskh:
        return GoogleFonts.notoNaskhArabic(textStyle: base);
      case SurahFontFamily.scheherazade:
        return GoogleFonts.scheherazadeNew(textStyle: base);
      case SurahFontFamily.reemKufi:
        return GoogleFonts.reemKufi(textStyle: base);
    }
  }
}
