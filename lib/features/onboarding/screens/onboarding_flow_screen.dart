import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';

import '../providers/onboarding_provider.dart';

// Screens
import 'hero_screen.dart';
import 'identity_screen.dart';
import 'motivation_screen.dart';
import 'relationship_screen.dart';
import 'friction_screen.dart';
import 'learning_style_screen.dart';
import 'practice_time_screen.dart';
import 'commitment_screen.dart';
import 'referral_source_screen.dart';
import 'referral_influencer_screen.dart';
import 'social_proof_screen.dart';
import 'loading_screen.dart';
import 'plan_complete_screen.dart';
import 'ratings_screen.dart';
import 'plan_reveal_screen.dart';
import 'paywall_screen.dart';
import 'signup_form_screen.dart';

/// Onboarding flow.
///
/// Renders ONLY the current step (not a PageView that keeps every screen
/// alive). This is deliberate: with a PageView, the LoadingScreen's timer
/// kept running in the background and animateToPage could desync from the
/// real step — causing duplicate screens, stuck transitions, and skips.
/// Here each screen is mounted only while it is the current step and is
/// disposed the moment we move on, so none of that can happen.
class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  // The ordered list of step builders. Index == step number.
  // Keep this in sync with the indices in onboarding_provider.dart
  // (especially paywallStepIndex).
  static const List<Widget> _steps = [
    HeroScreen(), // 0
    IdentityScreen(), // 1  user_type
    MotivationScreen(), // 2  motivation
    RelationshipScreen(), // 3  relationship_with_allah
    FrictionScreen(), // 4  barriers[]
    LearningStyleScreen(), // 5  learning_style
    PracticeTimeScreen(), // 6  practice_time
    CommitmentScreen(), // 7  commitment_level
    ReferralSourceScreen(), // 8  referral_source (randomized)
    ReferralInfluencerScreen(), // 9  referral_influencer
    SocialProofScreen(), // 10 testimonials, 4.9
    LoadingScreen(stepIndex: 11), // 11 "Building your plan..."
    PlanCompleteScreen(), // 12 celebration
    RatingsScreen(), // 13 in-app rating
    PlanRevealScreen(), // 14 reflects their answers
    PaywallScreen(), // 15 HARD paywall
    SignupFormScreen(), // 16 account creation
  ];

  void _handleBack(WidgetRef ref, BuildContext context) {
    final currentStep = ref.read(onboardingProvider).currentStep;
    if (currentStep == 0) {
      context.go(AppRoutes.login);
    } else {
      ref.read(onboardingProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final step = state.currentStep.clamp(0, _steps.length - 1);

    // When signup finishes, leave onboarding for home.
    ref.listen(onboardingProvider, (previous, next) {
      if (next.isComplete) {
        context.go(AppRoutes.home);
      }
    });

    // Paywall + signup get the full-bleed dark surface; everything else
    // sits on the rounded white card with the progress bar on top.
    final hideProgressBar = step >= 15;

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!hideProgressBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleBack(ref, context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.deepCharcoal,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: (step + 1) / totalOnboardingSteps,
                          backgroundColor:
                              AppColors.metallicGold.withValues(alpha: 0.18),
                          color: AppColors.metallicGold,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  hideProgressBar ? 0 : AppSpacing.md,
                  hideProgressBar ? 0 : AppSpacing.xs,
                  hideProgressBar ? 0 : AppSpacing.md,
                  0,
                ),
                decoration: BoxDecoration(
                  color: hideProgressBar
                      ? AppColors.richBlack
                      : AppColors.deepCharcoal,
                  borderRadius: hideProgressBar
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                  boxShadow: hideProgressBar
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, -2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: hideProgressBar
                      ? BorderRadius.zero
                      : const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                  // Only the current step is mounted. A fade keyed by step
                  // gives a smooth transition without any background timers
                  // or page-controller desync.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey<int>(step),
                      child: _steps[step],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
