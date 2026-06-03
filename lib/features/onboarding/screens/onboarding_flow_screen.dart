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

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBack() {
    final currentStep = ref.read(onboardingProvider).currentStep;
    if (currentStep == 0) {
      context.go(AppRoutes.login);
    } else {
      ref.read(onboardingProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    // Sync page controller with state
    ref.listen(onboardingProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }

      if (next.isComplete) {
        context.go(AppRoutes.home);
      }
    });

    // Screens where we hide the progress bar (paywall + signup form)
    final hideProgressBar = onboardingState.currentStep >= 15;

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with back button + progress
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
                      onTap: _handleBack,
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
                          value: (onboardingState.currentStep + 1) /
                              totalOnboardingSteps,
                          backgroundColor: AppColors.metallicGold
                              .withValues(alpha: 0.18),
                          color: AppColors.metallicGold,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // White surface that hosts each onboarding screen.
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
                  child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: const [
                  // Hook
                  HeroScreen(), // 0 — merged Mission + Our Mission

                  // Profile questions (all write to OnboardingState -> Supabase)
                  IdentityScreen(), // 1  user_type
                  MotivationScreen(), // 2  motivation
                  RelationshipScreen(), // 3  relationship_with_allah
                  FrictionScreen(), // 4  barriers[]
                  LearningStyleScreen(), // 5  learning_style
                  PracticeTimeScreen(), // 6  practice_time
                  CommitmentScreen(), // 7  commitment_level
                  ReferralSourceScreen(), // 8  referral_source (randomized)
                  ReferralInfluencerScreen(), // 9  referral_influencer

                  // Trust + plan build
                  SocialProofScreen(), // 10  testimonials, 4.9
                  LoadingScreen(stepIndex: 11), // 11  "Building your plan..."
                  PlanCompleteScreen(), // 12  celebration
                  RatingsScreen(), // 13  in-app rating
                  PlanRevealScreen(), // 14  reflects their answers

                  // Close
                  PaywallScreen(), // 15 — HARD paywall
                  SignupFormScreen(), // 16 — Account creation
                ],
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
