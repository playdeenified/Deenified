import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.metallicGold, width: 2),
                    color: AppColors.metallicGold.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.mosque_outlined,
                    size: 64,
                    color: AppColors.metallicGold,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Headline
                Text(
                  'Your Deen.\nSimplified.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Subheadline
                Text(
                  'Master the short Surahs, build consistent habits, and connect with the Qur\'an like never before.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // CTA
                PremiumButton(
                  text: 'GET STARTED',
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).nextStep();
                  },
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}
