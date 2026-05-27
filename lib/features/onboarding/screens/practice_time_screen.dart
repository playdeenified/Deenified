import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class PracticeTimeScreen extends ConsumerWidget {
  const PracticeTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What time of day do you want to practice?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildOption(
                  context,
                  ref,
                  label: 'Morning',
                  subLabel: 'Start the day with Fajr energy',
                  icon: Icons.wb_sunny,
                  value: 'morning',
                  isSelected: state.practiceTime == 'morning',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'Afternoon',
                  subLabel: 'A midday spiritual reset',
                  icon: Icons.light_mode,
                  value: 'afternoon',
                  isSelected: state.practiceTime == 'afternoon',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'Evening',
                  subLabel: 'Wind down with the Qur\'an',
                  icon: Icons.wb_twilight,
                  value: 'evening',
                  isSelected: state.practiceTime == 'evening',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'Late Night',
                  subLabel: 'Quiet hours of reflection',
                  icon: Icons.bedtime,
                  value: 'late_night',
                  isSelected: state.practiceTime == 'late_night',
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'BUILD MY PLAN',
                  onPressed: state.practiceTime != null
                      ? () => ref.read(onboardingProvider.notifier).nextStep()
                      : () {},
                  isOutlined: state.practiceTime == null,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String subLabel,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return ContentCard(
      selected: isSelected,
      onTap: () =>
          ref.read(onboardingProvider.notifier).setPracticeTime(value),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.metallicGold.withValues(alpha: 0.1)
                  : AppColors.deepCharcoal,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  isSelected ? AppColors.metallicGold : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? AppColors.metallicGold
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
