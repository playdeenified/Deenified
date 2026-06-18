import 'package:flutter/material.dart';

/// Standard Tajweed color palette used by Quran.com / printed Mushafs.
///
/// Letters annotated with these classes get colored to highlight the rule
/// of recitation that applies to them — e.g. red for Qalqalah, green for
/// Idgham with Ghunnah, blue for Madd.
class TajweedColors {
  TajweedColors._();

  static const ghunnah = Color(0xFFFF7E1E); // orange — nasal sound
  static const qalqalah = Color(0xFFDD0008); // red — bouncing sound
  static const ikhfa = Color(0xFF9400A8); // purple — hiding
  static const idgham = Color(0xFF169200); // green — merging
  static const iqlab = Color(0xFF26BFFD); // teal — flipping
  static const madd2 = Color(0xFF537FFF); // blue — 2-beat madd
  static const madd246 = Color(0xFF4050FF); // deeper blue — flexible madd
  static const maddMuttasil = Color(0xFF7B68EE); // indigo
  static const maddMunfasil = Color(0xFF5D5DFF);
  static const maddLazem = Color(0xFF7B1FA2); // dark purple — necessary
  static const hamzaWasl = Color(0xFF9E9E9E); // grey — silent hamza
  static const silent = Color(0xFFBDBDBD); // light grey — silent letter

  /// Resolve a `<tajweed class="...">` value to a color. Returns null
  /// for unknown classes so the letter falls back to the normal text color.
  static Color? forClass(String cls) {
    switch (cls) {
      case 'ghunnah':
        return ghunnah;
      case 'qalaqah':
      case 'qalqala':
      case 'qalqalah':
        return qalqalah;
      case 'ikhafa':
      case 'ikhafa_shafawi':
      case 'ikhfa':
      case 'ikhfa_shafawi':
        return ikhfa;
      case 'idgham_chunnah':
      case 'idgham_ghunnah':
      case 'idgham_no_ghunnah':
      case 'idgham_no_chunnah':
      case 'idgham_shafawi':
      case 'idgham_mutajanisain':
      case 'idgham_mutaqaribain':
      case 'idgham_wo_ghunnah':
        return idgham;
      case 'iqlab':
        return iqlab;
      case 'madd_2':
        return madd2;
      case 'madd_246':
      case 'madda_normal':
        return madd246;
      case 'madd_muttasil':
      case 'madda_permissible':
        return maddMuttasil;
      case 'madd_munfasil':
        return maddMunfasil;
      case 'madd_lazem':
      case 'madd_lazim':
      case 'madda_necessary':
        return maddLazem;
      case 'ham_wasl':
      case 'hamzat_wasl':
        return hamzaWasl;
      case 'slnt':
      case 'silent':
        return silent;
      default:
        return null;
    }
  }
}

/// Renders Quran.com's `text_uthmani_tajweed` markup (e.g.
/// `<tajweed class="ghunnah">...</tajweed>`) as colored [InlineSpan]s.
///
/// Letters that don't fall under a known tajweed class are rendered in the
/// fallback [baseColor]. Pass [enabled=false] to render the plain Arabic
/// without any tajweed coloring (kept here so callers don't have to
/// branch on which widget to build).
class TajweedTextSpan {
  TajweedTextSpan._();

  /// Build inline spans for a single tajweed-marked Arabic chunk.
  static List<InlineSpan> build(
    String tajweedMarkup, {
    required TextStyle baseStyle,
    required bool enabled,
  }) {
    if (!enabled) {
      return [TextSpan(text: tajweedMarkup, style: baseStyle)];
    }
    final spans = <InlineSpan>[];
    // <tajweed class="...">inner</tajweed> — case-insensitive
    final pattern = RegExp(
      r'<tajweed\s+class="([^"]+)">([^<]*)<\/tajweed>',
      caseSensitive: false,
    );
    int cursor = 0;
    for (final match in pattern.allMatches(tajweedMarkup)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: tajweedMarkup.substring(cursor, match.start),
          style: baseStyle,
        ));
      }
      final cls = match.group(1) ?? '';
      final inner = match.group(2) ?? '';
      final color = TajweedColors.forClass(cls);
      spans.add(TextSpan(
        text: inner,
        style: color != null
            ? baseStyle.copyWith(color: color)
            : baseStyle,
      ));
      cursor = match.end;
    }
    if (cursor < tajweedMarkup.length) {
      spans.add(TextSpan(
        text: tajweedMarkup.substring(cursor),
        style: baseStyle,
      ));
    }
    return spans;
  }
}
