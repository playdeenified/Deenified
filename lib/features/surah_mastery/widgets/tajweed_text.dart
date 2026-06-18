import 'package:flutter/material.dart';

/// Standard color-coded Tajweed palette, matching the printed Tajweed
/// editions (Dar Al-Marifah etc.) and Quran.com's reader.
class TajweedColors {
  TajweedColors._();

  // Nasalization
  static const ghunnah = Color(0xFFFF7E1B);

  // Ikhfaa family (concealment)
  static const ikhfaa = Color(0xFF4A90E2);
  static const ikhfaaMeem = Color(0xFFE91E8E);

  // Idghaam family (merging)
  static const idghamWithGhunnah = Color(0xFF4CAF50);
  static const idghamWithoutGhunnah = Color(0xFF2E7D32);
  static const idghamMeem = Color(0xFF81C784);

  // Iqlab
  static const iqlab = Color(0xFF9C27B0);

  // Qalqalah
  static const qalqalah = Color(0xFF1565C0);

  // Madd palette
  static const maddTabeei = Color(0xFFC62828);
  static const maddMunfasil = Color(0xFFE64A19);
  static const maddMuttasil = Color(0xFFB71C1C);
  static const maddLazim = Color(0xFFD32F2F);

  // Heavy / light letter rules
  static const tafkheem = Color(0xFF6D4C41);
  static const heavyRa = Color(0xFF1A237E);

  // Silent letters
  static const silent = Color(0xFF9E9E9E);

  /// Resolve a `class=` value (e.g. from Quran.com markup) to a color.
  /// Returns null for unrecognised classes; the caller falls back to base.
  static Color? forClass(String raw) {
    final cls = raw.toLowerCase().trim();
    switch (cls) {
      case 'ghunnah':
      case 'ghunna':
        return ghunnah;

      case 'ikhafa':
      case 'ikhfa':
        return ikhfaa;
      case 'ikhafa_shafawi':
      case 'ikhfa_shafawi':
        return ikhfaaMeem;

      case 'idgham_w_ghunnah':
      case 'idgham_chunnah':
      case 'idgham_ghunnah':
      case 'idgham_mutajanisayn':
      case 'idgham_mutajanisain':
      case 'idgham_mutaqaribayn':
      case 'idgham_mutaqaribain':
        return idghamWithGhunnah;
      case 'idgham_wo_ghunnah':
      case 'idgham_no_ghunnah':
      case 'idgham_no_chunnah':
        return idghamWithoutGhunnah;
      case 'idgham_shafawi':
        return idghamMeem;

      case 'iqlab':
        return iqlab;

      case 'qalqala':
      case 'qalqalah':
      case 'qalaqah':
        return qalqalah;

      case 'madda_normal':
      case 'madd_2':
        return maddTabeei;
      case 'madda_permissible':
      case 'madd_246':
      case 'madd_munfasil':
        return maddMunfasil;
      case 'madda_obligatory':
      case 'madd_muttasil':
        return maddMuttasil;
      case 'madda_necessary':
      case 'madd_lazem':
      case 'madd_lazim':
      case 'madd_246_6':
        return maddLazim;

      case 'tafkheem':
      case 'heavy':
        return tafkheem;
      case 'ra_mufakhama':
      case 'heavy_ra':
        return heavyRa;

      case 'ham_wasl':
      case 'hamzat_wasl':
      case 'laam_shamsiyah':
      case 'slnt':
      case 'silent':
        return silent;

      default:
        return null;
    }
  }
}

/// One Arabic character with optional tag context and an assigned color.
/// The pipeline mutates [color] across multiple passes (tag colors,
/// Allah-lam rule, Ra rule, heavy letters, sun-letter fallback, then
/// diacritic propagation).
class _TToken {
  final String char;
  final String? tagClass;
  Color? color;
  _TToken(this.char, this.tagClass);
}

/// Full Tajweed coloring engine. Applies Quran.com's tag-driven rules
/// *and* character-class rules so every letter gets the right color
/// even when upstream doesn't tag it.
///
/// Pass order is important: tag colors first (most specific), then the
/// context-sensitive Allah-lam and Ra rules, then the always-on rules
/// (heavy letters, sun-letter lam fallback), then diacritic propagation.
class TajweedTextSpan {
  TajweedTextSpan._();

  // -------------------------------------------------------------------------
  // Character-class sets
  // -------------------------------------------------------------------------

  /// Qalqalah letters: قطب جد. Only these five can carry the qalqalah color.
  static const _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};

  /// Letters of isti'laa (always-heavy / tafkheem): خ ص ض غ ط ق ظ.
  /// Mnemonic: خص ضغط قظ. Brown wherever they appear.
  static const _heavyLetters = {'خ', 'ص', 'ض', 'غ', 'ط', 'ق', 'ظ'};

  /// Sun letters (14): the ل of الـ before any of these is silent.
  static const _sunLetters = {
    'ت', 'ث', 'د', 'ذ', 'ر', 'ز', 'س', 'ش',
    'ص', 'ض', 'ط', 'ظ', 'ل', 'ن',
  };

  // -------------------------------------------------------------------------
  // Unicode constants — Arabic harakah and special marks
  // -------------------------------------------------------------------------
  static const _fatha = 'َ';
  static const _damma = 'ُ';
  static const _kasra = 'ِ';
  static const _tanweenFath = 'ً';
  static const _tanweenDamm = 'ٌ';
  static const _tanweenKasr = 'ٍ';
  static const _sukun = 'ْ';
  static const _shadda = 'ّ';
  static const _alefWasla = 'ٱ'; // ٱ
  static const _alef = 'ا'; // ا

  // -------------------------------------------------------------------------
  // Patterns for the input markup
  // -------------------------------------------------------------------------

  static final RegExp _verseEndPattern = RegExp(
    r'<span\s+class\s*=\s*"?end"?\s*>[^<]*</span\s*>',
    caseSensitive: false,
  );

  static final RegExp _anyTagPattern = RegExp(r'<[^>]+>');

  /// Opening tag: `<tajweed class=foo>` or `<rule class=foo>`. Class value
  /// can be bare, single-, or double-quoted.
  static final RegExp _openTagPattern = RegExp(
    '<(tajweed|rule)\\s+class\\s*=\\s*["\']?([^"\'>\\s]+)["\']?\\s*>',
    caseSensitive: false,
  );

  static final RegExp _closeTagPattern = RegExp(
    '</(tajweed|rule)\\s*>',
    caseSensitive: false,
  );

  // -------------------------------------------------------------------------
  // Public entry point
  // -------------------------------------------------------------------------

  static List<InlineSpan> build(
    String markup, {
    required TextStyle baseStyle,
    required bool enabled,
  }) {
    if (!enabled) {
      return [TextSpan(text: _stripAllTags(markup), style: baseStyle)];
    }

    final cleaned = markup.replaceAll(_verseEndPattern, '');
    final tokens = _tokenize(cleaned);

    _applyTagColors(tokens);
    _applyAllahLamRule(tokens);
    _applyRaRule(tokens);
    _applyHeavyLetters(tokens);
    _applySunLetterFallback(tokens);
    _propagateDiacritics(tokens);

    return _buildSpans(tokens, baseStyle);
  }

  // -------------------------------------------------------------------------
  // Tokenization
  // -------------------------------------------------------------------------

  /// Walk the input character-by-character, tracking whether we're currently
  /// inside a tajweed/rule tag. Each character becomes a [_TToken] with the
  /// active tag class (if any) attached.
  static List<_TToken> _tokenize(String text) {
    final tokens = <_TToken>[];
    String? currentClass;
    int i = 0;
    while (i < text.length) {
      if (text[i] == '<') {
        final end = text.indexOf('>', i);
        if (end == -1) {
          // Malformed — bail and consume the char as data.
          tokens.add(_TToken(text[i], currentClass));
          i++;
          continue;
        }
        final tag = text.substring(i, end + 1);
        final openMatch = _openTagPattern.firstMatch(tag);
        final closeMatch = _closeTagPattern.firstMatch(tag);
        if (openMatch != null) {
          currentClass = openMatch.group(2)?.toLowerCase();
        } else if (closeMatch != null) {
          currentClass = null;
        }
        // Any other `<...>` is silently dropped.
        i = end + 1;
        continue;
      }
      tokens.add(_TToken(text[i], currentClass));
      i++;
    }
    return tokens;
  }

  // -------------------------------------------------------------------------
  // Pass 1: tag colors (with the Qalqalah letter guard)
  // -------------------------------------------------------------------------

  static void _applyTagColors(List<_TToken> tokens) {
    for (final t in tokens) {
      final cls = t.tagClass;
      if (cls == null) continue;
      final color = TajweedColors.forClass(cls);
      if (color == null) continue;
      // Defensive: refuse to paint Qalqalah on a non-قطبجد base letter.
      if (_isQalqalahClass(cls) &&
          _isBaseLetter(t.char) &&
          !_qalqalahLetters.contains(t.char)) {
        continue;
      }
      t.color = color;
    }
  }

  // -------------------------------------------------------------------------
  // Pass 2: the lam in الله
  //
  // Pattern in the text: [ا|ٱ] ل ل (shadda) — the second lam carries shadda.
  // The first lam is silent (gray). The second lam is heavy (dark blue) when
  // the preceding word ends in fatha/damma/tanween-fath/tanween-damm, and
  // light (base color) when it ends in kasra/tanween-kasr.
  // -------------------------------------------------------------------------

  static void _applyAllahLamRule(List<_TToken> tokens) {
    for (int i = 2; i < tokens.length - 1; i++) {
      final alef = tokens[i - 2].char;
      if (alef != _alef && alef != _alefWasla) continue;
      if (tokens[i - 1].char != 'ل') continue;
      if (tokens[i].char != 'ل') continue;
      if (tokens[i + 1].char != _shadda) continue;

      // First lam — silent (gray) unless tag already painted it.
      tokens[i - 1].color ??= TajweedColors.silent;

      // Shadda lam — colored by preceding word's last harakah.
      // Default to heavy unless the preceding harakah is explicitly kasra
      // or tanween-kasr (the only contexts in which Allah-lam goes light).
      final preceding = _findPrecedingHarakah(tokens, i - 2);
      final isLight = preceding == _kasra || preceding == _tanweenKasr;
      if (!isLight && tokens[i].color == null) {
        tokens[i].color = TajweedColors.heavyRa;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Pass 3: Ra rules
  //
  // Heavy (mufakhama) when the ra carries fatha or damma (or tanween of
  // either), OR when it's saakin and the preceding harakah is fatha/damma.
  // Light (muraqqaqa) when the ra carries kasra (or tanween-kasr), OR when
  // it's saakin and the preceding harakah is kasra. Default: heavy.
  // -------------------------------------------------------------------------

  static void _applyRaRule(List<_TToken> tokens) {
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].char != 'ر') continue;
      if (tokens[i].color != null) continue; // tag wins

      final harakah = _harakahAfter(tokens, i);
      if (harakah == _fatha ||
          harakah == _damma ||
          harakah == _tanweenFath ||
          harakah == _tanweenDamm) {
        tokens[i].color = TajweedColors.heavyRa;
      } else if (harakah == _kasra || harakah == _tanweenKasr) {
        // Light — leave default base color.
      } else if (harakah == _sukun) {
        final prev = _findPrecedingHarakah(tokens, i);
        if (prev == _kasra || prev == _tanweenKasr) {
          // Light — leave default.
        } else {
          tokens[i].color = TajweedColors.heavyRa;
        }
      }
      // No clear harakah → leave default (don't guess).
    }
  }

  // -------------------------------------------------------------------------
  // Pass 4: heavy letters (always tafkheem)
  // -------------------------------------------------------------------------

  static void _applyHeavyLetters(List<_TToken> tokens) {
    for (final t in tokens) {
      if (t.color != null) continue;
      if (_heavyLetters.contains(t.char)) {
        t.color = TajweedColors.tafkheem;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Pass 5: sun-letter lam fallback
  //
  // Quran.com tags laam_shamsiyah comprehensively, but in case an instance
  // slips through, paint the lam of الـ + sun-letter silent ourselves.
  // -------------------------------------------------------------------------

  static void _applySunLetterFallback(List<_TToken> tokens) {
    for (int i = 1; i < tokens.length - 1; i++) {
      final alef = tokens[i - 1].char;
      if (alef != _alef && alef != _alefWasla) continue;
      if (tokens[i].char != 'ل') continue;
      if (tokens[i].color != null) continue;
      // Find the next base letter, skipping diacritics.
      String? nextLetter;
      for (int j = i + 1; j < tokens.length; j++) {
        final c = tokens[j].char;
        if (_isDiacritic(c)) continue;
        if (_isBaseLetter(c)) {
          nextLetter = c;
          break;
        }
        break;
      }
      if (nextLetter != null && _sunLetters.contains(nextLetter)) {
        tokens[i].color = TajweedColors.silent;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Pass 6: propagate base-letter color to attached diacritics
  //
  // In Arabic, diacritics (harakah, shadda, dagger alef) sit on top of the
  // preceding base letter. So a colored letter must drag its diacritics
  // with it visually — otherwise we get a brown letter with a black fatha
  // mark on top, which looks wrong.
  // -------------------------------------------------------------------------

  static void _propagateDiacritics(List<_TToken> tokens) {
    Color? lastBaseColor;
    for (final t in tokens) {
      if (_isBaseLetter(t.char)) {
        lastBaseColor = t.color;
      } else if (_isDiacritic(t.char) && t.color == null) {
        t.color = lastBaseColor;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Span assembly — group contiguous same-color tokens into one TextSpan
  // -------------------------------------------------------------------------

  static List<InlineSpan> _buildSpans(
    List<_TToken> tokens,
    TextStyle baseStyle,
  ) {
    if (tokens.isEmpty) return const [];
    final spans = <InlineSpan>[];
    final buf = StringBuffer();
    Color? currentColor = tokens.first.color;
    for (final t in tokens) {
      if (t.color != currentColor) {
        if (buf.isNotEmpty) {
          spans.add(TextSpan(
            text: buf.toString(),
            style: currentColor != null
                ? baseStyle.copyWith(color: currentColor)
                : baseStyle,
          ));
          buf.clear();
        }
        currentColor = t.color;
      }
      buf.write(t.char);
    }
    if (buf.isNotEmpty) {
      spans.add(TextSpan(
        text: buf.toString(),
        style: currentColor != null
            ? baseStyle.copyWith(color: currentColor)
            : baseStyle,
      ));
    }
    return spans;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns the harakah character sitting on the letter at [letterIdx],
  /// skipping a leading shadda if present. Returns null if there isn't one.
  static String? _harakahAfter(List<_TToken> tokens, int letterIdx) {
    int j = letterIdx + 1;
    if (j >= tokens.length) return null;
    if (tokens[j].char == _shadda) j++;
    if (j >= tokens.length) return null;
    final c = tokens[j].char;
    return _isHarakah(c) ? c : null;
  }

  /// Walk back from [idx] looking for the harakah on the previous base
  /// letter (across whitespace). Returns null if the previous letter has
  /// no harakah, or if we run off the start.
  static String? _findPrecedingHarakah(List<_TToken> tokens, int idx) {
    for (int j = idx - 1; j >= 0; j--) {
      final c = tokens[j].char;
      if (c == ' ' || c == '\n' || c == '\t' || c == ' ') continue;
      if (_isHarakah(c)) return c;
      if (_isBaseLetter(c)) return null;
    }
    return null;
  }

  static bool _isBaseLetter(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    // 0x0621–0x064A is the main Arabic letter block; 0x0671 is alef wasla.
    return (code >= 0x0621 && code <= 0x064A) || code == 0x0671;
  }

  static bool _isDiacritic(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    // Harakah (0x064B–0x0652) + dagger alef (0x0670) sit on top of letters.
    return (code >= 0x064B && code <= 0x0652) || code == 0x0670;
  }

  static bool _isHarakah(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code >= 0x064B && code <= 0x0652;
  }

  static bool _isQalqalahClass(String cls) {
    final lower = cls.toLowerCase();
    return lower == 'qalqalah' || lower == 'qalaqah' || lower == 'qalqala';
  }

  static String _stripAllTags(String s) {
    return s.replaceAll(_anyTagPattern, '');
  }
}
