import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/quran_api_service.dart';

/// Full Surah reading screen with Arabic text, translation,
/// and expandable word-by-word breakdowns.
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

  @override
  void initState() {
    super.initState();
    _versesFuture = QuranApiService.instance.getVersesByChapter(widget.surahId);
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
          return _buildVerseList(context, verses);
        },
      ),
    );
  }

  Widget _buildVerseList(BuildContext context, List<QuranVerse> verses) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: verses.length + 1, // +1 for Bismillah header
      itemBuilder: (context, index) {
        // Bismillah header (skip for Al-Fatihah and At-Tawbah)
        if (index == 0) {
          if (widget.surahId == 9) {
            return const SizedBox.shrink(); // At-Tawbah has no Bismillah
          }
          return _buildBismillahHeader(context);
        }

        final verse = verses[index - 1];
        final isExpanded = _expandedVerses.contains(verse.verseNumber);

        return _buildVerseCard(context, verse, isExpanded);
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
            Text(
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
    bool isExpanded,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.deepCharcoal,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse number badge
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
                  const Spacer(),
                  Text(
                    verse.verseKey,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
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
