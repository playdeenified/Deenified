import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

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
                  'Who is this for?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildOption(
                  context,
                  ref,
                  label: 'Myself',
                  value: 'me',
                  icon: Icons.person_outline,
                  isSelected: state.userType == 'me',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'My Child',
                  value: 'child',
                  icon: Icons.child_care,
                  isSelected: state.userType == 'child',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'My Family',
                  value: 'family',
                  icon: Icons.family_restroom,
                  isSelected: state.userType == 'family',
                ),
                _buildOption(
                  context,
                  ref,
                  label: 'I\'m a New Muslim',
                  value: 'new_muslim',
                  icon: Icons.waving_hand_outlined,
                  isSelected: state.userType == 'new_muslim',
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'CONTINUE',
                  onPressed: state.userType != null
                      ? () => ref.read(onboardingProvider.notifier).nextStep()
                      : () {},
                  isOutlined: state.userType == null,
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
    required String value,
    required IconData icon,
    required bool isSelected,
  }) {
    return ContentCard(
      selected: isSelected,
      onTap: () => ref.read(onboardingProvider.notifier).setUserType(value),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                isSelected ? AppColors.metallicGold : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? AppColors.metallicGold
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: AppColors.metallicGold,
              size: 24,
            ),
        ],
      ),
    );
  }
}
