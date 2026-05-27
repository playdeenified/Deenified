import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class ReferralSourceScreen extends ConsumerWidget {
  const ReferralSourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

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
                Text(
                  'Where did you hear about us?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildOption(
                  context,
                  ref,
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  value: 'instagram',
                  isSelected: state.referralSource == 'instagram',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'TikTok',
                  icon: Icons.music_note,
                  value: 'tiktok',
                  isSelected: state.referralSource == 'tiktok',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'Friends or Family',
                  icon: Icons.people_outline,
                  value: 'friends_family',
                  isSelected: state.referralSource == 'friends_family',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'Other',
                  icon: Icons.more_horiz,
                  value: 'other',
                  isSelected: state.referralSource == 'other',
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'CONTINUE',
                  onPressed: state.referralSource != null
                      ? () => ref.read(onboardingProvider.notifier).nextStep()
                      : () {},
                  isOutlined: state.referralSource == null,
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
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return ContentCard(
      selected: isSelected,
      onTap: () =>
          ref.read(onboardingProvider.notifier).setReferralSource(value),
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
              color: isSelected
                  ? AppColors.metallicGold
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? AppColors.metallicGold
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
