import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/widgets.dart';

/// Redesigned home screen — Cream & Gold theme.
/// Mirrors the design reference: greeting row, "continue reading" hero card,
/// streak + today stats, verse of the day, surah list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
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
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(child: _TopBar(userAsync: userAsync)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: const SliverToBoxAdapter(child: _ContinueReadingCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(child: _StatsRow(userAsync: userAsync)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: const SliverToBoxAdapter(child: _VerseOfTheDayCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: const SliverToBoxAdapter(child: _SurahSectionHeader()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: _SurahList(surahsAsync: surahsAsync),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar: avatar + Assalamu greeting + search button
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userAsync});

  final AsyncValue<Map<String, dynamic>?> userAsync;

  @override
  Widget build(BuildContext context) {
    final user = userAsync.valueOrNull;
    final firstName = (user?['first_name'] as String?)?.trim().isNotEmpty == true
        ? user!['first_name'] as String
        : 'Friend';
    final lastName = (user?['last_name'] as String?)?.trim().isNotEmpty == true
        ? user!['last_name'] as String
        : '';
    final initials = _initials(firstName, lastName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.softGold,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.heroBlack,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Assalamu 'Alaikum",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.search,
          onTap: () => context.push(AppRoutes.surahSearch),
        ),
      ],
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final result = '$f$l';
    return result.isEmpty ? '🌙' : result;
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero "continue reading" card
// ---------------------------------------------------------------------------

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    // Real "last read" tracking isn't wired yet, so for now we show a
    // "start here" CTA pointing at Al-Fatiha instead of faking progress.
    const surahName = 'Al-Fatiha';
    const surahArabic = 'سُورَةُ الفَاتِحَة';
    const arabicNumeral = '١';

    return GestureDetector(
      onTap: () => context.push('/surah/1/read', extra: surahName),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroBlack, AppColors.heroBlackSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Soft gold glow + faint Arabic numeral in the right
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: RadialGradient(
                    center: const Alignment(0.5, 0),
                    radius: 0.9,
                    colors: [
                      AppColors.metallicGold.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              top: 24,
              child: Text(
                arabicNumeral,
                style: GoogleFonts.amiri(
                  fontSize: 130,
                  color: AppColors.metallicGold.withValues(alpha: 0.12),
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            // Foreground content
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.metallicGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'START HERE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.metallicGold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    surahName,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnHero,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    surahArabic,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: AppColors.textOnHeroMuted,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to begin your journey through the Qur\'an',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textOnHeroMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Book button (bottom right)
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.metallicGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.metallicGold.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 26,
                  color: AppColors.heroBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row: Streak + Today
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.userAsync});

  final AsyncValue<Map<String, dynamic>?> userAsync;

  @override
  Widget build(BuildContext context) {
    final user = userAsync.valueOrNull;
    final streak = (user?['current_streak'] as int?) ?? 0;
    // Today minutes — placeholder for now; replace once activity tracking lands.
    const minutesToday = 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.softGold.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.metallicGold,
                size: 20,
              ),
            ),
            label: 'STREAK',
            value: '$streak ${streak == 1 ? 'day' : 'days'}',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$minutesToday',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mintDeep,
                ),
              ),
            ),
            label: 'TODAY',
            value: '$minutesToday minutes',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verse of the day card
// ---------------------------------------------------------------------------

class _VerseOfTheDayCard extends StatelessWidget {
  const _VerseOfTheDayCard();

  @override
  Widget build(BuildContext context) {
    // TODO: pull from a daily verse table. Hardcoded for now to match design.
    const arabic = 'إِنَّ مَعَ الْعُسْرِ يُسْرًا';
    const translation = '"Indeed, with hardship comes ease."';
    const source = 'Ash-Sharh · 94:6';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'VERSE OF THE DAY',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGold,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Text(
                  arabic,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            translation,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surah section
// ---------------------------------------------------------------------------

class _SurahSectionHeader extends StatelessWidget {
  const _SurahSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Surah',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a chapter to begin reciting',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.surahs),
          child: Row(
            children: [
              Text(
                'See all',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGold,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.darkGold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.surahsAsync});

  final AsyncValue<List<Map<String, dynamic>>> surahsAsync;

  @override
  Widget build(BuildContext context) {
    return surahsAsync.when(
      data: (surahs) {
        final preview = surahs.take(5).toList();
        return SliverList.separated(
          itemCount: preview.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => _SurahCard(data: preview[i]),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.metallicGold),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Couldn\'t load surahs',
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final id = (data['id'] as int?) ?? 0;
    final name = (data['name_english'] as String?) ??
        (data['name'] as String?) ??
        'Surah';
    final meaning = (data['translation'] as String?) ??
        (data['english_meaning'] as String?) ??
        '';
    final arabic = (data['name_arabic'] as String?) ?? '';
    final revelation =
        (data['revelation_place'] as String?)?.toUpperCase() ?? '';
    final verses = data['ayah_count'] ?? data['verse_count'] ?? data['verses'];
    final juz = data['juz'] ?? data['juz_number'];

    final isMeccan = revelation.toLowerCase().contains('mecc');
    final dotColor = isMeccan ? AppColors.metallicGold : AppColors.mintDeep;
    final revelationLabel = isMeccan
        ? 'Meccan'
        : (revelation.toLowerCase().contains('medina') ? 'Medinan' : '');

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
            _SurahNumberBadge(number: id),
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
                    color: AppColors.darkGold,
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

class _SurahNumberBadge extends StatelessWidget {
  const _SurahNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return SurahNumberBadge(number: number);
  }
}
