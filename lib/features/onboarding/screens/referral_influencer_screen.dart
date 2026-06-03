import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/onboarding_provider.dart';

/// "Did an influencer bring you here? Who?" — its own screen.
/// Bottom row: Skip oval (left) + Continue (right, enabled only once text
/// is typed).
class ReferralInfluencerScreen extends ConsumerStatefulWidget {
  const ReferralInfluencerScreen({super.key});

  @override
  ConsumerState<ReferralInfluencerScreen> createState() =>
      _ReferralInfluencerScreenState();
}

class _ReferralInfluencerScreenState
    extends ConsumerState<ReferralInfluencerScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(onboardingProvider).referralInfluencer ?? '';
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    ref.read(onboardingProvider.notifier).nextStep();
  }

  void _handleContinue() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(onboardingProvider.notifier).setReferralInfluencer(value);
    _advance();
  }

  void _handleSkip() {
    HapticFeedback.selectionClick();
    _advance();
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
                const SizedBox(height: AppSpacing.lg),

                // Gold emblem
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.softGold, AppColors.metallicGold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.metallicGold.withValues(alpha: 0.4),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.heroBlack,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Did an influencer\nbring you here?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Drop their name so we can thank them. '
                  'No one? Just skip.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Their name or @handle',
                    prefixIcon: const Icon(Icons.alternate_email),
                    filled: true,
                    fillColor: AppColors.deepCharcoal,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide:
                          const BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(
                        color: AppColors.metallicGold,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleContinue(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Bottom row: Skip (left) + Continue (right, gated on text)
                Row(
                  children: [
                    // Skip oval
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleSkip,
                        child: Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.deepCharcoal,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Continue — gold gradient when ready, greyed when empty
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _hasText ? _handleContinue : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _hasText
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.softGold,
                                      AppColors.metallicGold,
                                    ],
                                  )
                                : null,
                            color: _hasText
                                ? null
                                : AppColors.metallicGold
                                    .withValues(alpha: 0.18),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            boxShadow: _hasText
                                ? [
                                    const BoxShadow(
                                      color: AppColors.darkGold,
                                      offset: Offset(0, 4),
                                      blurRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: _hasText
                                  ? AppColors.heroBlack
                                  : AppColors.textTertiary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
