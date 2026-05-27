import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

class ReferralInfluencerScreen extends ConsumerStatefulWidget {
  const ReferralInfluencerScreen({super.key});

  @override
  ConsumerState<ReferralInfluencerScreen> createState() =>
      _ReferralInfluencerScreenState();
}

class _ReferralInfluencerScreenState
    extends ConsumerState<ReferralInfluencerScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text =
        ref.read(onboardingProvider).referralInfluencer ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      ref.read(onboardingProvider.notifier).setReferralInfluencer(value);
    }
    ref.read(onboardingProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
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
                  'If an influencer brought you here, who?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Type their name. Skip if no one referred you.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.metallicGold),
                    ),
                  ),
                  onSubmitted: (_) => _handleContinue(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  text: 'CONTINUE',
                  onPressed: _handleContinue,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).nextStep();
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
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
