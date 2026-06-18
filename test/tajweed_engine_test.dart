// End-to-end verification of the Tajweed engine on real Quran.com markup.
//
// Walks the resulting InlineSpan tree for two reference verses, dumps
// "char → color" per character, and asserts the basmala renders exactly
// how we promised it would. Run with: `flutter test test/tajweed_engine_test.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deenified/features/surah_mastery/widgets/tajweed_text.dart';

const _baseStyle = TextStyle(fontSize: 26, color: Color(0xFF1A1A1A));

/// Flatten the InlineSpan tree into a (char, color) list so the test can
/// assert per-character behavior without caring about how spans grouped.
List<(String, Color?)> _flatten(List<InlineSpan> spans) {
  final out = <(String, Color?)>[];
  void walk(InlineSpan s) {
    if (s is TextSpan) {
      final color = s.style?.color;
      final text = s.text ?? '';
      for (var i = 0; i < text.length; i++) {
        out.add((text[i], color));
      }
      for (final child in s.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }
  for (final s in spans) {
    walk(s);
  }
  return out;
}

/// Returns the color of every occurrence of [target] in the flattened list,
/// ignoring [_baseStyle.color] (the default text color) when [skipDefault]
/// is true. Useful for "find the heavy Ra" style assertions.
List<Color?> _colorsOf(
  List<(String, Color?)> flat,
  String target,
) {
  final out = <Color?>[];
  for (final (c, col) in flat) {
    if (c == target) out.add(col);
  }
  return out;
}

void _dump(String label, List<InlineSpan> spans) {
  // ignore: avoid_print
  print('\n--- $label ---');
  for (final (c, col) in _flatten(spans)) {
    final hex = col == null
        ? 'default'
        : '#${col.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    // ignore: avoid_print
    print('  "$c" → $hex');
  }
}

void main() {
  // --- AL-FATIHA :1 (basmala) ------------------------------------------------
  // Exact markup from Quran.com's text_uthmani_tajweed field.
  const basmala =
      'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ '
      '<tajweed class=ham_wasl>ٱ</tajweed>'
      '<tajweed class=laam_shamsiyah>ل</tajweed>'
      'رَّحْمَ<tajweed class=madda_normal>ـٰ</tajweed>نِ '
      '<tajweed class=ham_wasl>ٱ</tajweed>'
      '<tajweed class=laam_shamsiyah>ل</tajweed>'
      'رَّح<tajweed class=madda_permissible>ِي</tajweed>مِ '
      '<span class=end>١</span>';

  test('basmala — Allah lam light after kasra, heavy Ra, silent ال-, madds', () {
    final spans = TajweedTextSpan.build(
      basmala,
      baseStyle: _baseStyle,
      enabled: true,
    );
    _dump('Al-Fatiha 1:1', spans);
    final flat = _flatten(spans);
    final defaultColor = _baseStyle.color;

    // No raw tag chars leaked.
    for (final (c, _) in flat) {
      expect(c, isNot('<'), reason: 'raw tag bracket in output');
      expect(c, isNot('>'), reason: 'raw tag bracket in output');
    }

    // The two ل letters inside الله — after "بِسْمِ" the preceding harakah
    // is kasra, so the shadda-lam stays light (default color).
    // First find the first الله lam pair.
    var firstLamIdx = -1;
    for (var i = 0; i < flat.length - 1; i++) {
      if (flat[i].$1 == 'ل' && flat[i + 1].$1 == 'ل') {
        firstLamIdx = i;
        break;
      }
    }
    expect(firstLamIdx, greaterThan(0));
    expect(flat[firstLamIdx].$2, TajweedColors.silent,
        reason: 'first ل of الله should be silent gray');
    expect(flat[firstLamIdx + 1].$2, defaultColor,
        reason: 'second ل of الله in basmala (kasra context) should be light');

    // ر in الرَّحْمَـٰنِ — Ra with shadda+fatha → heavy.
    final raColors = _colorsOf(flat, 'ر');
    expect(raColors.isNotEmpty, true);
    for (final col in raColors) {
      expect(col, TajweedColors.heavyRa,
          reason: 'every ر in basmala is fatha-Ra → heavy dark blue');
    }

    // Dagger alef in الرَّحْمَـٰنِ — Quran.com emits the tatweel ـ (U+0640)
    // plus the superscript-alef vowel ٰ (U+0670). Both are inside the
    // madda_normal tag and should be cumin red.
    expect(_colorsOf(flat, 'ٰ'), [TajweedColors.maddTabeei],
        reason: 'dagger alef ٰ should be tagged madda_normal cumin red');
    expect(_colorsOf(flat, 'ـ'), [TajweedColors.maddTabeei],
        reason: 'tatweel ـ before dagger alef shares the madd color');

    // ـِ + ي in الرَّحِيم — tagged madda_permissible → orange-red (munfasil).
    // Two letters, both should be that color.
    final yaaIdx = flat.indexWhere(
      (e) => e.$1 == 'ي' && e.$2 == TajweedColors.maddMunfasil,
    );
    expect(yaaIdx, isNot(-1),
        reason: 'ي in الرَّحِيم should carry madda_permissible (munfasil)');

    // No verse-end glyph leaked.
    expect(flat.any((e) => e.$1 == '١'), false,
        reason: 'verse-end ١ should be stripped');
  });

  // --- BAQARAH 2:9 ----------------------------------------------------------
  // The verse the user flagged. Confirm no خ in this verse gets the
  // Qalqalah (dark blue) color — they should be tafkheem brown instead,
  // and the dagger alef stays cumin red.
  const baqarah29 =
      'يُخَ<tajweed class=madda_normal>ـٰ</tajweed>دِعُونَ '
      '<tajweed class=ham_wasl>ٱ</tajweed>للَّهَ وَ'
      '<tajweed class=ham_wasl>ٱ</tajweed>لَّذِينَ ءَامَنُو'
      '<tajweed class=slnt>اْ</tajweed> وَمَا يَخْدَعُونَ '
      'إِلّ<tajweed class=madda_obligatory>َآ</tajweed> أَ'
      '<tajweed class=ikhafa>نف</tajweed>ُسَهُمْ وَمَا يَشْعُر'
      '<tajweed class=madda_permissible>ُو</tajweed>نَ <span class=end>٩</span>';

  test('Baqarah 2:9 — no خ gets Qalqalah, dagger alef is the red one', () {
    final spans = TajweedTextSpan.build(
      baqarah29,
      baseStyle: _baseStyle,
      enabled: true,
    );
    _dump('Baqarah 2:9', spans);
    final flat = _flatten(spans);

    // Every خ in the verse — should be tafkheem brown, never qalqalah blue.
    final khaaColors = _colorsOf(flat, 'خ');
    expect(khaaColors.isNotEmpty, true,
        reason: 'verse contains at least one خ');
    for (final col in khaaColors) {
      expect(col, TajweedColors.tafkheem,
          reason: 'خ must be tafkheem brown, never qalqalah');
      expect(col, isNot(TajweedColors.qalqalah),
          reason: 'خ is NOT a qalqalah letter');
    }

    // Only the dagger-alef pair (ـ + ٰ) in يُخَـٰدِعُونَ should be cumin red.
    expect(_colorsOf(flat, 'ٰ'), [TajweedColors.maddTabeei]);
    expect(_colorsOf(flat, 'ـ'), [TajweedColors.maddTabeei]);

    // ق ط ب ج د are the only qalqalah letters — none in 2:9 should be blue
    // unless tagged. (None are tagged in this verse's markup.)
    for (final (c, col) in flat) {
      if (col == TajweedColors.qalqalah) {
        expect({'ق', 'ط', 'ب', 'ج', 'د'}.contains(c), true,
            reason: 'qalqalah color must only fall on قطبجد, found on "$c"');
      }
    }
  });
}
