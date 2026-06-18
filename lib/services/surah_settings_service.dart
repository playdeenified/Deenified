import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reader-screen display settings: Arabic font size + tajweed coloring toggle.
///
/// Backed by SharedPreferences and exposes a [ValueNotifier]-like change
/// stream so widgets can rebuild on update.
class SurahSettingsService extends ChangeNotifier {
  SurahSettingsService._();
  static final instance = SurahSettingsService._();

  static const _kFontSizeKey = 'surah_arabic_font_size';
  static const _kTajweedKey = 'surah_tajweed_enabled';

  static const double defaultFontSize = 26;
  static const double minFontSize = 18;
  static const double maxFontSize = 42;

  bool _loaded = false;
  double _arabicFontSize = defaultFontSize;
  bool _tajweedEnabled = false;

  double get arabicFontSize => _arabicFontSize;
  bool get tajweedEnabled => _tajweedEnabled;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _arabicFontSize = prefs.getDouble(_kFontSizeKey) ?? defaultFontSize;
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

  Future<void> setTajweedEnabled(bool enabled) async {
    _tajweedEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTajweedKey, enabled);
  }

  Future<void> toggleTajweed() => setTajweedEnabled(!_tajweedEnabled);
}
