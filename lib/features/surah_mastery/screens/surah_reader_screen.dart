import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/quran_api_service.dart';
import '../../../services/quran_audio_service.dart';
import '../../../services/surah_settings_service.dart';
import '../widgets/reciter_picker_sheet.dart';
import '../widgets/surah_settings_sheet.dart';
import '../widgets/tajweed_text.dart';

/// Full Surah reading screen with Arabic text, translation,
/// expandable word-by-word breakdowns, and reciter audio playback.
class SurahReaderScreen extends StatefulWidget {
  final int surahId;
  final String surahName;

  const SurahReaderScreen({
    super.key,
    required this.surahId,
    required this.surahName,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  late Future<List<QuranVerse>> _versesFuture;
  final Set<int> _expandedVerses = {};
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  // Per-verse repeat cycle state. Only one verse is "active" at a time —
  // tapping the repeat-cycle icon advances through:
  //   idle → 1× → 2× → 3× → ∞ → idle (stops)
  int? _activeRepeatVerseIndex;
  int _activeRepeatCount = 0; // 0 = idle, 1/2/3 = count, -1 = infinite

  // Last verse we auto-scrolled to (so we don't re-scroll on every stream tick)
  int? _lastAutoScrolledVerse;
  String? _selectedReciterName;

  @override
  void initState() {
    super.initState();
    _versesFuture = QuranApiService.instance.getVersesByChapter(widget.surahId);
    QuranAudioService.instance.setSurahDisplayName(widget.surahName);
    // Kick off the audio queue prefetch in parallel with the text load so
    // tapping play is instant instead of triggering the network round-trip.
    QuranAudioService.instance.warmUp(widget.surahId);
    _refreshSelectedReciterName();
    SurahSettingsService.instance
        .ensureLoaded()
        .then((_) => mounted ? setState(() {}) : null);
    SurahSettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshSelectedReciterName() async {
    try {
      final id = await QuranAudioService.instance.getSelectedReciterId();
      final reciters = await QuranApiService.instance.getReciters();
      final match = reciters.firstWhere(
        (r) => r.id == id,
        orElse: () => Reciter(id: id, reciterName: 'Reciter $id'),
      );
      if (mounted) setState(() => _selectedReciterName = match.reciterName);
    } catch (_) {
      // Best-effort — fine if it fails (e.g. offline)
    }
  }

  @override
  void dispose() {
    // Note: we intentionally do NOT stop playback here — background audio is
    // enabled, so leaving this screen (or backgrounding the app) should not
    // silence the recitation. The user stops it from the playback bar or
    // the lock-screen controls.
    SurahSettingsService.instance.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openReciterPicker() async {
    final pickedId = await showReciterPickerSheet(context);
    if (pickedId != null) {
      await _refreshSelectedReciterName();
      // Prefetch with the new reciter so the next play tap is instant.
      QuranAudioService.instance.warmUp(widget.surahId);
    }
  }

  Future<void> _playWholeSurah() async {
    HapticFeedback.lightImpact();
    setState(() {
      _activeRepeatVerseIndex = null;
      _activeRepeatCount = 0;
    });
    try {
      await QuranAudioService.instance.playSurah(widget.surahId);
    } catch (_) {
      _showAudioError();
    }
  }

  /// Per-verse repeat-cycle: advance through idle → 1 → 2 → 3 → ∞ → idle.
  Future<void> _cycleRepeat(int verseIndex) async {
    HapticFeedback.lightImpact();
    int nextCount;
    if (_activeRepeatVerseIndex != verseIndex) {
      // First tap on a fresh verse — start at "play once".
      nextCount = 1;
    } else {
      switch (_activeRepeatCount) {
        case 1:
          nextCount = 2;
          break;
        case 2:
          nextCount = 3;
          break;
        case 3:
          nextCount = -1; // ∞
          break;
        case -1:
        default:
          nextCount = 0; // stop
          break;
      }
    }

    setState(() {
      _activeRepeatVerseIndex = nextCount == 0 ? null : verseIndex;
      _activeRepeatCount = nextCount;
    });

    try {
      if (nextCount == 0) {
        await QuranAudioService.instance.stop();
      } else {
        await QuranAudioService.instance
            .repeatVerse(widget.surahId, verseIndex, nextCount);
      }
    } catch (_) {
      _showAudioError();
    }
  }

  Future<void> _playFromVerse(int verseIndex) async {
    HapticFeedback.lightImpact();
    setState(() {
      _activeRepeatVerseIndex = null;
      _activeRepeatCount = 0;
    });
    try {
      await QuranAudioService.instance
          .playFromVerse(widget.surahId, verseIndex);
    } catch (_) {
      _showAudioError();
    }
  }

  Future<void> _showRepeatSheet(int verseIndex, int verseNumber) async {
    HapticFeedback.mediumImpact();
    final choice = await showModalBottomSheet<_RepeatChoice>(
      context: context,
      backgroundColor: AppColors.deepCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _RepeatOptionsSheet(verseNumber: verseNumber),
    );
    if (choice == null) return;
    try {
      if (choice.isPlayFromHere) {
        await _playFromVerse(verseIndex);
        return;
      }
      setState(() {
        _activeRepeatVerseIndex = verseIndex;
        _activeRepeatCount = choice.repeatCount;
      });
      await QuranAudioService.instance
          .repeatVerse(widget.surahId, verseIndex, choice.repeatCount);
    } catch (_) {
      _showAudioError();
    }
  }

  Future<void> _onSettingsTap() async {
    HapticFeedback.lightImpact();
    await showSurahSettingsSheet(context);
  }

  void _showAudioError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not load audio. Check your connection.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _autoScrollToVerse(int verseNumber) {
    if (_lastAutoScrolledVerse == verseNumber) return;
    _lastAutoScrolledVerse = verseNumber;
    final key = _verseKeys[verseNumber];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tajweedOn = SurahSettingsService.instance.tajweedEnabled;
    final fontSize = SurahSettingsService.instance.arabicFontSize;

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.richBlack,
        surfaceTintColor: AppColors.richBlack,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.surahName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Surah ${widget.surahId} · Reading',
              style: const TextStyle(
                color: AppColors.metallicGold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          _AppBarActionButton(
            icon: Icons.record_voice_over_rounded,
            tooltip: 'Choose Reciter',
            onTap: _openReciterPicker,
          ),
          const SizedBox(width: AppSpacing.xs),
          _AppBarActionButton(
            icon: Icons.play_arrow_rounded,
            tooltip: 'Listen to whole Surah',
            filled: true,
            onTap: _playWholeSurah,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: FutureBuilder<List<QuranVerse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.metallicGold,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading Surah...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: AppColors.textTertiary,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Could not load Surah',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _versesFuture = QuranApiService.instance
                              .getVersesByChapter(widget.surahId);
                        });
                      },
                      icon: const Icon(Icons.refresh,
                          color: AppColors.metallicGold),
                      label: const Text('Retry',
                          style: TextStyle(color: AppColors.metallicGold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.metallicGold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final verses = snapshot.data!;
          return StreamBuilder<int?>(
            stream: QuranAudioService.instance.player.currentIndexStream,
            builder: (context, idxSnap) {
              final activeIndex = idxSnap.data;
              final svcSurah = QuranAudioService.instance.currentSurahId;
              final activeVerseNum = (svcSurah == widget.surahId &&
                      activeIndex != null)
                  ? QuranAudioService.instance.verseNumberForIndex(activeIndex)
                  : null;

              if (activeVerseNum != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _autoScrollToVerse(activeVerseNum);
                });
              }

              return Stack(
                children: [
                  _buildVerseList(
                    context,
                    verses,
                    activeVerseNum,
                    tajweedOn,
                    fontSize,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _PlaybackBar(
                      surahId: widget.surahId,
                      reciterName: _selectedReciterName,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVerseList(
    BuildContext context,
    List<QuranVerse> verses,
    int? activeVerseNumber,
    bool tajweedOn,
    double fontSize,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        120,
      ),
      itemCount: verses.length + 1, // +1 for Bismillah header
      itemBuilder: (context, index) {
        if (index == 0) {
          if (widget.surahId == 9) {
            return const SizedBox.shrink();
          }
          return _buildBismillahHeader(context);
        }

        final verse = verses[index - 1];
        final verseIndex = index - 1;
        final isExpanded = _expandedVerses.contains(verse.verseNumber);
        final isActive = activeVerseNumber == verse.verseNumber;
        final isRepeatActive = _activeRepeatVerseIndex == verseIndex;

        final key = _verseKeys.putIfAbsent(
          verse.verseNumber,
          () => GlobalKey(),
        );

        return Container(
          key: key,
          child: _buildVerseCard(
            context,
            verse,
            verseIndex,
            isExpanded,
            isActive,
            isRepeatActive,
            tajweedOn,
            fontSize,
          ),
        );
      },
    );
  }

  Widget _buildBismillahHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.metallicGold.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.metallicGold.withValues(alpha: 0.6),
                  size: 16,
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.metallicGold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.surahId != 1)
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              style: SurahSettingsService.instance.arabicTextStyle(
                color: AppColors.metallicGold,
                fontSize: 28,
                height: 2.0,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          if (widget.surahId != 1)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'In the name of Allah, the Most Gracious, the Most Merciful',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.metallicGold.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.metallicGold.withValues(alpha: 0.6),
                  size: 16,
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.metallicGold.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    QuranVerse verse,
    int verseIndex,
    bool isExpanded,
    bool isActive,
    bool isRepeatActive,
    bool tajweedOn,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.metallicGold.withValues(alpha: 0.06)
              : AppColors.deepCharcoal,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive ? AppColors.metallicGold : AppColors.glassBorder,
            width: isActive ? 1.5 : 0.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.metallicGold.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse number + action buttons row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.metallicGold.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.metallicGold,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${verse.verseNumber}',
                        style: const TextStyle(
                          color: AppColors.metallicGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    verse.verseKey,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                  const Spacer(),
                  _RepeatCycleButton(
                    repeatCount: isRepeatActive ? _activeRepeatCount : 0,
                    onTap: () => _cycleRepeat(verseIndex),
                    onLongPress: () =>
                        _showRepeatSheet(verseIndex, verse.verseNumber),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _VerseActionButton(
                    icon: Icons.settings_rounded,
                    tooltip: 'Reader settings',
                    onTap: _onSettingsTap,
                  ),
                ],
              ),
            ),

            // Arabic text — optional tajweed coloring, no interactions
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _ArabicVerseText(
                verse: verse,
                fontSize: fontSize,
                tajweedOn: tajweedOn,
              ),
            ),

            // English translation
            if (verse.translationText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  _cleanTranslation(verse.translationText!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),

            // Word-by-word toggle
            if (verse.words.isNotEmpty)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedVerses.remove(verse.verseNumber);
                    } else {
                      _expandedVerses.add(verse.verseNumber);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.glassBorder.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.softGold,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isExpanded
                            ? 'Hide Word-by-Word'
                            : 'Word-by-Word Translation',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.softGold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            if (isExpanded && verse.words.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: verse.words.map((word) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richBlack,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.glassBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (word.transliterationText != null)
                            Text(
                              word.transliterationText!,
                              style: const TextStyle(
                                color: AppColors.softGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (word.translationText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                word.translationText!,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Remove HTML tags from translation text
  String _cleanTranslation(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

/// Renders a verse's Arabic text with optional Tajweed coloring. Non-interactive.
class _ArabicVerseText extends StatelessWidget {
  final QuranVerse verse;
  final double fontSize;
  final bool tajweedOn;

  const _ArabicVerseText({
    required this.verse,
    required this.fontSize,
    required this.tajweedOn,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = SurahSettingsService.instance.arabicTextStyle(
      color: AppColors.textPrimary,
      fontSize: fontSize,
    );

    // Prefer the verse-level tajweed string when present — it's a single
    // continuous run and shapes more reliably than per-word fragments.
    final markup = tajweedOn
        ? (verse.textUthmaniTajweed ?? verse.textUthmani)
        : verse.textUthmani;

    return Text.rich(
      TextSpan(
        children: TajweedTextSpan.build(
          markup,
          baseStyle: baseStyle,
          enabled: tajweedOn,
        ),
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }
}

/// A compact circular icon button used inside a verse card row.
class _VerseActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _VerseActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.metallicGold.withValues(alpha: 0.12),
          ),
          child: Icon(
            icon,
            color: AppColors.heroBlack,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Per-verse repeat-cycle button. Single tap cycles through:
///   idle → 1× → 2× → 3× → ∞ → idle.
/// Shows the current count as a gold badge over the repeat icon.
/// Long-press opens the full repeat menu.
class _RepeatCycleButton extends StatelessWidget {
  final int repeatCount; // 0=idle, 1/2/3, -1=infinite
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RepeatCycleButton({
    required this.repeatCount,
    required this.onTap,
    required this.onLongPress,
  });

  String? get _badgeLabel {
    if (repeatCount == 0) return null;
    if (repeatCount == -1) return '∞';
    return '$repeatCount×';
  }

  @override
  Widget build(BuildContext context) {
    final active = repeatCount != 0;
    final label = _badgeLabel;
    return Tooltip(
      message: active
          ? 'Repeating $label — tap to advance, hold to stop or change'
          : 'Tap to play once · tap again for 2×, 3×, ∞ · long-press for more',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.metallicGold
                    : AppColors.metallicGold.withValues(alpha: 0.12),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.metallicGold.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.repeat_rounded,
                color: active ? AppColors.heroBlack : AppColors.heroBlack,
                size: 22,
              ),
            ),
            if (label != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.heroBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.metallicGold,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.metallicGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-of-screen mini player. Only visible when audio is loaded for this
/// surah. Shows reciter + current verse + play/pause + close.
class _PlaybackBar extends StatelessWidget {
  final int surahId;
  final String? reciterName;

  const _PlaybackBar({required this.surahId, required this.reciterName});

  @override
  Widget build(BuildContext context) {
    final svc = QuranAudioService.instance;
    return StreamBuilder<PlayerState>(
      stream: svc.player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final isThisSurah = svc.currentSurahId == surahId;
        final processing = state?.processingState ?? ProcessingState.idle;
        final hasAudio = isThisSurah && processing != ProcessingState.idle;

        if (!hasAudio) return const SizedBox.shrink();

        final isPlaying = state?.playing ?? false;
        final isLoading = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return StreamBuilder<int?>(
          stream: svc.player.currentIndexStream,
          builder: (context, idxSnap) {
            final idx = idxSnap.data;
            final verseNum = (idx != null) ? svc.verseNumberForIndex(idx) : null;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepCharcoal,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.metallicGold.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.metallicGold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.metallicGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reciterName ?? 'Reciter',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              verseNum != null
                                  ? 'Verse $surahId:$verseNum'
                                  : 'Surah $surahId',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.metallicGold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Previous verse',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          svc.player.seekToPrevious();
                        },
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: AppColors.heroBlack,
                          size: 28,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (isPlaying) {
                            svc.pause();
                          } else {
                            svc.resume();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.metallicGold,
                            shape: BoxShape.circle,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.heroBlack,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppColors.heroBlack,
                                  size: 26,
                                ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next verse',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          svc.player.seekToNext();
                        },
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.heroBlack,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Stop',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          svc.stop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Long-press menu — gives explicit control over repeat count, plus a
/// "Play from here" entry now that the inline play-from-here button has
/// been replaced by Tajweed.
class _RepeatOptionsSheet extends StatelessWidget {
  final int verseNumber;
  const _RepeatOptionsSheet({required this.verseNumber});

  @override
  Widget build(BuildContext context) {
    const options = <_RepeatMenuItem>[
      _RepeatMenuItem(
        label: 'Play once',
        choice: _RepeatChoice.count(1),
        icon: Icons.play_arrow_rounded,
      ),
      _RepeatMenuItem(
        label: 'Repeat 3 times',
        choice: _RepeatChoice.count(3),
        icon: Icons.repeat_rounded,
      ),
      _RepeatMenuItem(
        label: 'Repeat 5 times',
        choice: _RepeatChoice.count(5),
        icon: Icons.repeat_rounded,
      ),
      _RepeatMenuItem(
        label: 'Repeat 10 times',
        choice: _RepeatChoice.count(10),
        icon: Icons.repeat_rounded,
      ),
      _RepeatMenuItem(
        label: 'Repeat indefinitely',
        choice: _RepeatChoice.count(-1),
        icon: Icons.all_inclusive_rounded,
      ),
      _RepeatMenuItem(
        label: 'Play from here to end',
        choice: _RepeatChoice.playFromHere(),
        icon: Icons.playlist_play_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  color: AppColors.metallicGold,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Verse $verseNumber',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.glassBorder),
          ...options.map(
            (o) => InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(o.choice);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      o.icon,
                      color: AppColors.metallicGold,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      o.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _RepeatMenuItem {
  final String label;
  final IconData icon;
  final _RepeatChoice choice;
  const _RepeatMenuItem({
    required this.label,
    required this.icon,
    required this.choice,
  });
}

/// Result type for the repeat-options sheet — either a repeat count or a
/// "play from here through end" request.
class _RepeatChoice {
  final int repeatCount;
  final bool isPlayFromHere;
  const _RepeatChoice.count(this.repeatCount) : isPlayFromHere = false;
  const _RepeatChoice.playFromHere()
      : repeatCount = 0,
        isPlayFromHere = true;
}

/// A bigger, more visible app-bar action button. [filled] makes it a solid
/// gold circle (used for the primary "Listen to whole Surah" action).
class _AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  const _AppBarActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? AppColors.metallicGold
                  : AppColors.metallicGold.withValues(alpha: 0.12),
              border: filled
                  ? null
                  : Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: AppColors.metallicGold.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: filled ? AppColors.heroBlack : AppColors.metallicGold,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
