import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

/// Full list of all 114 Surahs. Mirrors the home screen's visual language
/// (Outfit headlines, deep-charcoal cards, gold accents) so the
/// "see all" jump from home → list doesn't feel like a downgrade.
class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: _ListHeader(surahsAsync: surahsAsync),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: _SurahSliverList(surahsAsync: surahsAsync),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.surahsAsync});

  final AsyncValue<List<Map<String, dynamic>>> surahsAsync;

  @override
  Widget build(BuildContext context) {
    final count = surahsAsync.valueOrNull?.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All Surahs',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count != null
                    ? '$count chapters of the Qur\'an'
                    : 'Loading chapters…',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.search_rounded,
          onTap: () => context.push(AppRoutes.surahSearch),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.deepCharcoal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SurahSliverList extends StatelessWidget {
  const _SurahSliverList({required this.surahsAsync});

  final AsyncValue<List<Map<String, dynamic>>> surahsAsync;

  @override
  Widget build(BuildContext context) {
    return surahsAsync.when(
      data: (surahs) => SliverList.separated(
        itemCount: surahs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _SurahCard(data: surahs[i]),
      ),
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.metallicGold),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Couldn\'t load surahs',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Card mirrors the home screen's surah card so the design language is
/// consistent across the app.
class _SurahCard extends StatelessWidget {
  const _SurahCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final id = (data['id'] as int?) ?? 0;
    final name = (data['name_english'] as String?) ??
        (data['name_transliteration'] as String?) ??
        (data['name'] as String?) ??
        'Surah';
    final meaning = (data['translation'] as String?) ??
        (data['english_meaning'] as String?) ??
        '';
    final arabic = (data['name_arabic'] as String?) ?? '';
    final revelation =
        (data['revelation_place'] as String?)?.toLowerCase() ?? '';
    final verses = data['ayah_count'] ??
        data['verse_count'] ??
        data['total_ayahs'] ??
        data['verses'];
    final juz = data['juz'] ?? data['juz_number'];

    final isMeccan = revelation.contains('mecc') || revelation.contains('makk');
    final isMedinan = revelation.contains('medin') || revelation.contains('madin');
    final dotColor = isMeccan ? AppColors.metallicGold : AppColors.mintDeep;
    final revelationLabel =
        isMeccan ? 'Meccan' : (isMedinan ? 'Medinan' : '');

    return GestureDetector(
      onTap: () => context.push('/surah/$id', extra: name),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.deepCharcoal,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SurahNumberBadge(number: id),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (meaning.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            meaning,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      if (revelationLabel.isNotEmpty) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          revelationLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (verses != null) ...[
                        Text(
                          '·',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          '$verses verses',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (juz != null) ...[
                        Text(
                          '·',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          'Juz $juz',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (arabic.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: AppColors.metallicGold,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
