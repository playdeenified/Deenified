import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../providers/providers.dart';

class SurahDetailScreen extends ConsumerWidget {
  final int surahId;

  const SurahDetailScreen({super.key, required this.surahId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(surahId));

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: surahAsync.when(
        data: (surah) => _buildContent(context, ref, surah),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? surah) {
    if (surah == null) {
      return const Center(child: Text('Surah not found'));
    }

    return CustomScrollView(
      slivers: [
        // Hero Header — black card with gold accent on cream
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.richBlack,
          surfaceTintColor: AppColors.richBlack,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.deepCharcoal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                kToolbarHeight + 12,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.heroBlack, AppColors.heroBlackSoft],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah['name_arabic'] ?? '',
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontFamily: 'Amiri',
                                color: AppColors.metallicGold,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      surah['name_transliteration'] ?? '',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textOnHero,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      surah['name_english'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnHeroMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(context, '${surah['total_ayahs'] ?? 0}', 'Ayahs'),
                _buildStat(context,
                    _capitalize(surah['revelation_type'] ?? 'meccan'), 'Type'),
                _buildStat(context, '${surah['juz'] ?? 30}', 'Juz'),
              ],
            ),
          ),
        ),

        // Divider
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GoldenDivider(),
          ),
        ),

        // Action Buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Read Button
                PremiumButton(
                  text: 'READ SURAH',
                  icon: Icons.menu_book,
                  isOutlined: true,
                  onPressed: () {
                    context.push(
                      '/surah/$surahId/read',
                      extra: surah['name_transliteration'] ??
                          surah['name_english'] ??
                          'Surah',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Quiz Button
                PremiumButton(
                  text: 'START QUIZ',
                  icon: Icons.quiz,
                  onPressed: () {
                    context.push('/quiz/$surahId');
                  },
                ),
              ],
            ),
          ),
        ),

        // Info Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ContentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.softGold, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'About this Surah',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    surah['description'] ?? 'Description coming soon.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.metallicGold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
