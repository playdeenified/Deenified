import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class CommitmentScreen extends ConsumerWidget {
  const CommitmentScreen({super.key});

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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'How much time daily?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildOption(
                  context,
                  ref,
                  label: '5 minutes',
                  subLabel: 'Casual & easy (Recommended)',
                  value: 'casual',
                  isSelected: state.commitmentLevel == 'casual',
                ),
                _buildOption(
                  context,
                  ref,
                  label: '10 minutes',
                  subLabel: 'Serious learner',
                  value: 'serious',
                  isSelected: state.commitmentLevel == 'serious',
                ),
                _buildOption(
                  context,
                  ref,
                  label: '15 minutes',
                  subLabel: 'Intense dedication',
                  value: 'intense',
                  isSelected: state.commitmentLevel == 'intense',
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'I COMMIT',
                  onPressed: state.commitmentLevel != null
                      ? () => ref.read(onboardingProvider.notifier).nextStep()
                      : () {},
                  isOutlined: state.commitmentLevel == null,
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
    required String value,
    required bool isSelected,
  }) {
    return ContentCard(
      selected: isSelected,
      onTap: () =>
          ref.read(onboardingProvider.notifier).setCommitmentLevel(value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: AppColors.metallicGold,
              size: 28,
            )
          else
            const Icon(
              Icons.circle_outlined,
              color: AppColors.textTertiary,
              size: 28,
            ),
        ],
      ),
    );
  }
}
