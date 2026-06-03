import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// Merged opening screen (old Mission + Our Mission).
/// Big bold hook + a concise mission line, then a single CTA.
class HeroScreen extends ConsumerWidget {
  const HeroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Glowing mosque emblem
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.softGold, AppColors.metallicGold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.metallicGold.withValues(alpha: 0.45),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    size: 60,
                    color: AppColors.heroBlack,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Hook headline — big and black so it pops
                Text(
                  'Your Deen.\nSimplified.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Concise merged mission line
                Text(
                  'Low iman often isn\'t rebellion — it\'s burnout. '
                  'Deenified makes the Qur\'an easy to return to through '
                  'cinematic audio stories and fun, gamified trivia.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                PremiumButton(
                  text: 'BEGIN MY JOURNEY',
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
}
