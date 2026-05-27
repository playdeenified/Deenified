import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class OurMissionScreen extends ConsumerWidget {
  const OurMissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Decorative icon (smaller)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.metallicGold.withValues(alpha: 0.2),
                        AppColors.softGold.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 36,
                    color: AppColors.metallicGold,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Headline
                Text(
                  'Our Mission:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Make Deen Easy\nto Return To.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.metallicGold,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Body — condensed
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: AppColors.deepCharcoal.withValues(alpha: 0.5),
                    border: Border.all(
                      color: AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    'Low iman isn\'t always rebellion — often it\'s just burnout. '
                    'Deenified teaches Qur\'an and Islamic knowledge through '
                    'cinematic audio stories and fun, gamified trivia. '
                    'Built for students, professionals, and parents.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // CTA
                PremiumButton(
                  text: 'BEGIN MY JOURNEY',
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).nextStep();
                  },
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
