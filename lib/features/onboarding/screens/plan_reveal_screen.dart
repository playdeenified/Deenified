import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// "Your Deenified plan is ready" — reflects the user's onboarding answers
/// back to them so the plan feels personal before the paywall.
class PlanRevealScreen extends ConsumerWidget {
  const PlanRevealScreen({super.key});

  static const _goalLabels = {
    'closeness': 'Grow closer to Allah',
    'consistency': 'Be consistent with your Deen',
    'confidence': 'Build confidence in prayer',
    'halal_fun': 'Halal fun & learning',
  };

  static const _styleLabels = {
    'visual': 'Visual — quizzes & reading',
    'auditory': 'Auditory — stories & recitation',
    'both': 'A mix of everything',
  };

  static const _timeLabels = {
    'morning': 'Mornings',
    'afternoon': 'Afternoons',
    'evening': 'Evenings',
    'late_night': 'Late nights',
  };

  static const _commitLabels = {
    'casual': '5 min / day',
    'serious': '10 min / day',
    'intense': '15 min / day',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingProvider);

    final rows = <(IconData, String, String)>[
      (
        Icons.flag_rounded,
        'Your goal',
        _goalLabels[s.motivation] ?? 'Reconnect with the Qur\'an',
      ),
      (
        Icons.school_rounded,
        'Learning style',
        _styleLabels[s.learningStyle] ?? 'A mix of everything',
      ),
      (
        Icons.schedule_rounded,
        'Best time',
        _timeLabels[s.practiceTime] ?? 'Anytime that works',
      ),
      (
        Icons.bolt_rounded,
        'Daily commitment',
        _commitLabels[s.commitmentLevel] ?? '5 min / day',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.lg * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your Deenified plan\nis ready',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Built around your answers.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Plan card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.deepCharcoal,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.metallicGold.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        _planRow(context, rows[i].$1, rows[i].$2, rows[i].$3),
                        if (i != rows.length - 1)
                          const Divider(
                            height: AppSpacing.lg,
                            color: AppColors.glassBorder,
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'UNLOCK MY PLAN',
                  onPressed: () =>
                      ref.read(onboardingProvider.notifier).nextStep(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _planRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.softGold, AppColors.metallicGold],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.heroBlack, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppColors.darkGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
