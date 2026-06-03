import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// "Where did you hear about us?" — options are shuffled once per session so
/// users don't just tap the top one, giving us honest attribution data.
class ReferralSourceScreen extends ConsumerStatefulWidget {
  const ReferralSourceScreen({super.key});

  @override
  ConsumerState<ReferralSourceScreen> createState() =>
      _ReferralSourceScreenState();
}

class _ReferralSourceScreenState extends ConsumerState<ReferralSourceScreen> {
  // Shuffled once on first build, then stable for this user's session.
  late final List<_SourceOption> _options;

  @override
  void initState() {
    super.initState();
    _options = List<_SourceOption>.from(_allOptions)..shuffle(Random());
  }

  static const _allOptions = [
    _SourceOption('Instagram', Icons.camera_alt_outlined, 'instagram'),
    _SourceOption('TikTok', Icons.music_note, 'tiktok'),
    _SourceOption('Friends or Family', Icons.people_outline, 'friends_family'),
    _SourceOption('YouTube', Icons.smart_display_outlined, 'youtube'),
    _SourceOption('Other', Icons.more_horiz, 'other'),
  ];

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final opt in _options)
                  _buildOption(
                    context,
                    label: opt.label,
                    icon: opt.icon,
                    value: opt.value,
                    isSelected: state.referralSource == opt.value,
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
    BuildContext context, {
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
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.softGold, AppColors.metallicGold],
                    )
                  : null,
              color: isSelected ? null : AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.heroBlack : AppColors.darkGold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.metallicGold),
        ],
      ),
    );
  }
}

class _SourceOption {
  const _SourceOption(this.label, this.icon, this.value);
  final String label;
  final IconData icon;
  final String value;
}
