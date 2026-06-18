import 'package:flutter/material.dart';

/// Standard color-coded Tajweed palette, matching the printed Tajweed
/// editions (Dar Al-Marifah etc.) and Quran.com's reader.
///
/// Letters annotated with these rule classes get colored to highlight the
/// rule of recitation that applies. The full per-rule palette is below; the
/// resolver maps Quran.com's tag aliases onto these colors.
class TajweedColors {
  TajweedColors._();

  // Nasalization
  static const ghunnah = Color(0xFFFF7E1B); // ن مّ shadda — orange/red

  // Ikhfaa family (concealment)
  static const ikhfaa = Color(0xFF4A90E2); // noon saakin / tanween — light blue
  static const ikhfaaMeem = Color(0xFFE91E8E); // meem saakin before ب — pink

  // Idghaam family (merging)
  static const idghamWithGhunnah = Color(0xFF4CAF50); // before ي ن م و
  static const idghamWithoutGhunnah = Color(0xFF2E7D32); // before ل ر
  static const idghamMeem = Color(0xFF81C784); // meem before meem

  // Iqlab (conversion to meem)
  static const iqlab = Color(0xFF9C27B0); // before ب

  // Qalqalah (echoing letters: ق ط ب ج د when saakin)
  static const qalqalah = Color(0xFF1565C0); // dark blue

  // Madd (prolongation) — four-tier red palette, deeper = longer hold
  static const maddTabeei = Color(0xFFC62828); // 2 counts (natural)
  static const maddMunfasil = Color(0xFFE64A19); // 2–4 (permissible)
  static const maddMuttasil = Color(0xFFB71C1C); // 4–5 (obligatory)
  static const maddLazim = Color(0xFFD32F2F); // 6 (necessary)

  // Heavy / light letter rules
  static const tafkheem = Color(0xFF6D4C41); // heavy letters — brown
  static const heavyRa = Color(0xFF1A237E); // Ra mufakhama — deep indigo

  // Silent letters (Hamzat al-Wasl, Laam Shamsiyah, marked-silent)
  static const silent = Color(0xFF9E9E9E); // grey

  /// Resolve a `class=` value to a color, accepting every alias Quran.com
  /// uses for the same underlying rule. Returns null when the class is
  /// unknown — the caller falls back to the base text color.
  static Color? forClass(String raw) {
    final cls = raw.toLowerCase().trim();
    switch (cls) {
      // Ghunnah
      case 'ghunnah':
      case 'ghunna':
        return ghunnah;

      // Ikhfaa
      case 'ikhafa':
      case 'ikhfa':
        return ikhfaa;
      case 'ikhafa_shafawi':
      case 'ikhfa_shafawi':
        return ikhfaaMeem;

      // Idghaam
      case 'idgham_w_ghunnah':
      case 'idgham_chunnah':
      case 'idgham_ghunnah':
      case 'idgham_mutajanisain':
      case 'idgham_mutaqaribain':
        return idghamWithGhunnah;
      case 'idgham_wo_ghunnah':
      case 'idgham_no_ghunnah':
      case 'idgham_no_chunnah':
        return idghamWithoutGhunnah;
      case 'idgham_shafawi':
        return idghamMeem;

      // Iqlab
      case 'iqlab':
        return iqlab;

      // Qalqalah
      case 'qalqala':
      case 'qalqalah':
      case 'qalaqah':
        return qalqalah;

      // Madd family — match Quran.com's four tiers
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

      // Heavy / Ra
      case 'tafkheem':
      case 'heavy':
        return tafkheem;
      case 'ra_mufakhama':
      case 'heavy_ra':
        return heavyRa;

      // Silent
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

/// Renders Quran.com's tajweed markup as colored [InlineSpan]s. Handles
/// both tag conventions Quran.com uses (`<tajweed class=foo>` at the verse
/// level, `<rule class=foo>` at the word level) plus the verse-end glyph
/// `<span class=end>١</span>` (stripped — we render the verse number
/// badge separately).
///
/// When [enabled] is false, the markup is run through an aggressive tag
/// stripper so the user never sees raw HTML-ish text even if upstream
/// somehow returned the marked-up field by mistake.
class TajweedTextSpan {
  TajweedTextSpan._();

  /// Combined pattern: `<tag class=foo>inner</tag>` for either tag name,
  /// with bare, single-, or double-quoted class values.
  static final RegExp _rulePattern = RegExp(
    '<(tajweed|rule)\\s+class\\s*=\\s*["\']?([^"\'>\\s]+)["\']?\\s*>'
    '([^<]*)'
    '</\\1\\s*>',
    caseSensitive: false,
  );

  /// Final-pass stripper. Matches any `<...>` so leftover tags (including
  /// unrecognized ones or malformed nesting) never reach the user.
  static final RegExp _anyTagPattern = RegExp(r'<[^>]+>');

  /// Verse-end glyph (e.g. `<span class=end>١</span>`).
  static final RegExp _verseEndPattern = RegExp(
    r'<span\s+class\s*=\s*"?end"?\s*>[^<]*</span\s*>',
    caseSensitive: false,
  );

  static List<InlineSpan> build(
    String markup, {
    required TextStyle baseStyle,
    required bool enabled,
  }) {
    if (!enabled) {
      return [TextSpan(text: _stripAllTags(markup), style: baseStyle)];
    }

    // Drop verse-end glyphs up front so they don't show up colored.
    final cleaned = markup.replaceAll(_verseEndPattern, '');

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final match in _rulePattern.allMatches(cleaned)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: _stripAllTags(cleaned.substring(cursor, match.start)),
          style: baseStyle,
        ));
      }
      final cls = match.group(2) ?? '';
      final inner = match.group(3) ?? '';
      final color = TajweedColors.forClass(cls);
      spans.add(TextSpan(
        text: inner,
        style:
            color != null ? baseStyle.copyWith(color: color) : baseStyle,
      ));
      cursor = match.end;
    }
    if (cursor < cleaned.length) {
      spans.add(TextSpan(
        text: _stripAllTags(cleaned.substring(cursor)),
        style: baseStyle,
      ));
    }
    return spans;
  }

  /// Belt-and-suspenders strip — kills any `<...>` patterns that may have
  /// slipped past the structured matcher (malformed nesting, unknown
  /// tag names, mojibake from a CDN, etc).
  static String _stripAllTags(String s) {
    return s.replaceAll(_anyTagPattern, '');
  }
}
