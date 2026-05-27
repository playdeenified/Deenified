import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';

import '../providers/onboarding_provider.dart';

// Screens
import 'mission_screen.dart';
import 'our_mission_screen.dart';
import 'identity_screen.dart';
import 'motivation_screen.dart';
import 'validation_screen.dart';
import 'friction_screen.dart';
import 'relationship_screen.dart';
import 'learning_style_screen.dart';
import 'practice_time_screen.dart';
import 'loading_screen.dart';
import 'diagnosis_screen.dart';
import 'media_reveal_screen.dart';
import 'mastery_reveal_screen.dart';
import 'commitment_screen.dart';
import 'features_screen.dart';
import 'benefits_screen.dart';
import 'social_proof_screen.dart';
import 'value_stack_screen.dart';
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
          duration: AppDurations.normal,
          curve: Curves.easeInOut,
        );
      }

      if (next.isComplete) {
        context.go(AppRoutes.home);
      }
    });

    // Screens where we hide the progress bar (paywall + signup form)
    final hideProgressBar = onboardingState.currentStep >= 18;

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button + progress
            if (!hideProgressBar)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _handleBack,
                    ),

                    // Progress bar
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        child: LinearProgressIndicator(
                          value: (onboardingState.currentStep + 1) /
                              totalOnboardingSteps,
                          backgroundColor: AppColors.deepCharcoal,
                          color: AppColors.metallicGold,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: const [
                  // Phase 1: Hook
                  MissionScreen(), // 0 — Welcome
                  OurMissionScreen(), // 1 — Our Mission (NEW)

                  // Phase 2: Buy-In
                  IdentityScreen(), // 2
                  MotivationScreen(), // 3
                  ValidationScreen(), // 4
                  FrictionScreen(), // 5
                  RelationshipScreen(), // 6
                  LearningStyleScreen(), // 7
                  PracticeTimeScreen(), // 8

                  // Phase 3: Diagnosis
                  LoadingScreen(), // 9
                  DiagnosisScreen(), // 10

                  // Phase 4: Solution Loop
                  MediaRevealScreen(), // 11 — Video player
                  MasteryRevealScreen(), // 12
                  CommitmentScreen(), // 13

                  // Phase 5: Commitment
                  FeaturesScreen(), // 14
                  BenefitsScreen(), // 15
                  SocialProofScreen(), // 16 — Redesigned

                  // Phase 6: Close/Paywall
                  ValueStackScreen(), // 17
                  PaywallScreen(), // 18 — RevenueCat
                  SignupFormScreen(), // 19 — Account creation
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
