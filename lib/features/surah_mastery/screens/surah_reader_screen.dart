import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/quran_api_service.dart';
import '../../../services/quran_audio_service.dart';
import '../widgets/reciter_picker_sheet.dart';

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

  // Last verse we auto-scrolled to (so we don't re-scroll on every stream tick)
  int? _lastAutoScrolledVerse;
  // Stash the loaded reciter id for sub-title display
  String? _selectedReciterName;

  @override
  void initState() {
    super.initState();
    _versesFuture = QuranApiService.instance.getVersesByChapter(widget.surahId);
    QuranAudioService.instance.setSurahDisplayName(widget.surahName);
    _refreshSelectedReciterName();
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
    // Note: we intentionally do NOT stop playback here — the user has
    // background audio enabled, so leaving this screen (or backgrounding
    // the app) should not silence the recitation. They stop it from the
    // playback bar or the lock-screen controls.
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openReciterPicker() async {
    final pickedId = await showReciterPickerSheet(context);
    if (pickedId != null) {
      await _refreshSelectedReciterName();
    }
  }

  Future<void> _playWholeSurah() async {
    HapticFeedback.lightImpact();
    try {
      await QuranAudioService.instance.playSurah(widget.surahId);
    } catch (e) {
      _showAudioError();
    }
  }

  Future<void> _loopVerse(int verseIndex) async {
    HapticFeedback.lightImpact();
    try {
      await QuranAudioService.instance
          .repeatVerse(widget.surahId, verseIndex, -1);
    } catch (_) {
      _showAudioError();
    }
  }

  Future<void> _playFromVerse(int verseIndex) async {
    HapticFeedback.lightImpact();
    try {
      await QuranAudioService.instance
          .playFromVerse(widget.surahId, verseIndex);
    } catch (_) {
      _showAudioError();
    }
  }

  Future<void> _showRepeatSheet(int verseIndex, int verseNumber) async {
    HapticFeedback.mediumImpact();
    final choice = await showModalBottomSheet<int>(
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
      await QuranAudioService.instance
          .repeatVerse(widget.surahId, verseIndex, choice);
    } catch (_) {
      _showAudioError();
    }
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
      alignment: 0.2, // pin near the top-third
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // currentSurahId might be null until first playback
              final svcSurah = QuranAudioService.instance.currentSurahId;
              final activeVerseNum = (svcSurah == widget.surahId &&
                      activeIndex != null)
                  ? QuranAudioService.instance.verseNumberForIndex(activeIndex)
                  : null;

              // Auto-scroll on verse change (after the current frame settles).
              if (activeVerseNum != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _autoScrollToVerse(activeVerseNum);
                });
              }

              return Stack(
                children: [
                  _buildVerseList(context, verses, activeVerseNum),
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
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        // Extra bottom padding so the floating playback bar doesn't cover
        // the last verse when it's expanded.
        120,
      ),
      itemCount: verses.length + 1, // +1 for Bismillah header
      itemBuilder: (context, index) {
        // Bismillah header (skip for At-Tawbah; Al-Fatihah handled inside)
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

        final key = _verseKeys.putIfAbsent(verse.verseNumber, () => GlobalKey());

        return Container(
          key: key,
          child: _buildVerseCard(
            context,
            verse,
            verseIndex,
            isExpanded,
            isActive,
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
          // Ornamental divider
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
          // Bismillah text (only show for surahs that aren't Al-Fatihah)
          if (widget.surahId != 1)
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 28,
                color: AppColors.metallicGold,
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
          // Ornamental divider
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
            color: isActive
                ? AppColors.metallicGold
                : AppColors.glassBorder,
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
            // Verse number + audio buttons row
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
                  // Verse number badge
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
                  // Loop this verse (tap) — long-press for repeat count menu
                  Tooltip(
                    message: 'Loop this verse · long-press for options',
                    child: InkWell(
                      onTap: () => _loopVerse(verseIndex),
                      onLongPress: () =>
                          _showRepeatSheet(verseIndex, verse.verseNumber),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.metallicGold.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.repeat_one_rounded,
                          color: isActive
                              ? AppColors.metallicGold
                              : AppColors.heroBlack,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Play from this verse and continue through end of surah
                  Tooltip(
                    message: 'Play from this verse to the end',
                    child: InkWell(
                      onTap: () => _playFromVerse(verseIndex),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.metallicGold.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.playlist_play_rounded,
                          color: AppColors.heroBlack,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arabic text
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                verse.textUthmani,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  color: AppColors.textPrimary,
                  height: 2.2,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
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

            // Expanded word-by-word view
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
        final hasAudio =
            isThisSurah && processing != ProcessingState.idle;

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

/// Bottom sheet shown on long-press of a verse play button. Lets the user
/// repeat that verse N times.
class _RepeatOptionsSheet extends StatelessWidget {
  final int verseNumber;
  const _RepeatOptionsSheet({required this.verseNumber});

  @override
  Widget build(BuildContext context) {
    // Pass 1 for "just once", -1 for infinite.
    const options = <_RepeatOption>[
      _RepeatOption(label: 'Play once', value: 1),
      _RepeatOption(label: 'Repeat 3 times', value: 3),
      _RepeatOption(label: 'Repeat 5 times', value: 5),
      _RepeatOption(label: 'Repeat 10 times', value: 10),
      _RepeatOption(label: 'Repeat indefinitely', value: -1),
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
                  'Repeat Verse $verseNumber',
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
                Navigator.of(context).pop(o.value);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      o.value == -1
                          ? Icons.all_inclusive_rounded
                          : Icons.repeat_rounded,
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

class _RepeatOption {
  final String label;
  final int value;
  const _RepeatOption({required this.label, required this.value});
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? AppColors.metallicGold
                  : AppColors.metallicGold.withValues(alpha: 0.12),
              border: filled
                  ? null
                  : Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.5),
                      width: 1,
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
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
