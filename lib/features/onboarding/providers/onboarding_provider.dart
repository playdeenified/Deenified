import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

/// Onboarding state class
class OnboardingState {
  final int currentStep;
  final String? userType;
  final String? motivation;
  final List<String> barriers;
  final String? relationshipWithAllah;
  final String? learningStyle;
  final String? practiceTime;
  final String? commitmentLevel;
  final String? referralSource;
  final String? referralInfluencer;
  final bool paywallPassed;
  final bool isComplete;

  const OnboardingState({
    this.currentStep = 0,
    this.userType,
    this.motivation,
    this.barriers = const [],
    this.relationshipWithAllah,
    this.learningStyle,
    this.practiceTime,
    this.commitmentLevel,
    this.referralSource,
    this.referralInfluencer,
    this.paywallPassed = false,
    this.isComplete = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? userType,
    String? motivation,
    List<String>? barriers,
    String? relationshipWithAllah,
    String? learningStyle,
    String? practiceTime,
    String? commitmentLevel,
    String? referralSource,
    String? referralInfluencer,
    bool? paywallPassed,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userType: userType ?? this.userType,
      motivation: motivation ?? this.motivation,
      barriers: barriers ?? this.barriers,
      relationshipWithAllah:
          relationshipWithAllah ?? this.relationshipWithAllah,
      learningStyle: learningStyle ?? this.learningStyle,
      practiceTime: practiceTime ?? this.practiceTime,
      commitmentLevel: commitmentLevel ?? this.commitmentLevel,
      referralSource: referralSource ?? this.referralSource,
      referralInfluencer: referralInfluencer ?? this.referralInfluencer,
      paywallPassed: paywallPassed ?? this.paywallPassed,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Total number of onboarding screens
const int totalOnboardingSteps = 17;

/// Index of the hard paywall in the onboarding PageView. The user CANNOT
/// advance past this step until they've actually purchased/restored.
const int paywallStepIndex = 15;

/// Onboarding provider to manage onboarding flow state
@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  /// Timestamp of the last navigation, used to debounce rapid double-taps.
  /// Without this, a fast double-tap on a CONTINUE/UNLOCK button fires
  /// nextStep() twice and skips a whole screen — including the paywall.
  DateTime? _lastNavAt;

  bool get _navLocked {
    final now = DateTime.now();
    if (_lastNavAt != null &&
        now.difference(_lastNavAt!) < const Duration(milliseconds: 600)) {
      return true;
    }
    _lastNavAt = now;
    return false;
  }

  /// Go to next step (debounced against double-taps).
  /// HARD GATE: cannot advance past the paywall without purchasing —
  /// this makes the paywall unskippable even if a tap slips past the
  /// debounce or any other navigation fires unexpectedly.
  void nextStep() {
    if (_navLocked) return;
    if (state.currentStep == paywallStepIndex && !state.paywallPassed) {
      return;
    }
    if (state.currentStep < totalOnboardingSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Called by the paywall ONLY after a verified purchase/restore.
  /// Unlocks the gate so the user can proceed to account creation.
  void markPaywallPassed() {
    state = state.copyWith(paywallPassed: true);
  }

  /// Go to previous step (debounced against double-taps)
  void previousStep() {
    if (_navLocked) return;
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < totalOnboardingSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Set user type (me/child/family/new muslim)
  void setUserType(String type) {
    state = state.copyWith(userType: type);
  }

  /// Set motivation
  void setMotivation(String motivation) {
    state = state.copyWith(motivation: motivation);
  }

  /// Toggle barrier selection
  void toggleBarrier(String barrier) {
    final barriers = List<String>.from(state.barriers);
    if (barriers.contains(barrier)) {
      barriers.remove(barrier);
    } else {
      barriers.add(barrier);
    }
    state = state.copyWith(barriers: barriers);
  }

  /// Set relationship with Allah
  void setRelationshipWithAllah(String relationship) {
    state = state.copyWith(relationshipWithAllah: relationship);
  }

  /// Set learning style
  void setLearningStyle(String style) {
    state = state.copyWith(learningStyle: style);
  }

  /// Set preferred time of day for practice
  void setPracticeTime(String time) {
    state = state.copyWith(practiceTime: time);
  }

  /// Set commitment level
  void setCommitmentLevel(String level) {
    state = state.copyWith(commitmentLevel: level);
  }

  /// Set referral source (where they heard about us)
  void setReferralSource(String source) {
    state = state.copyWith(referralSource: source);
  }

  /// Set referral influencer name (free text)
  void setReferralInfluencer(String name) {
    state = state.copyWith(referralInfluencer: name);
  }

  /// Complete onboarding
  void completeOnboarding() {
    state = state.copyWith(isComplete: true);
  }

  /// Reset onboarding
  void reset() {
    state = const OnboardingState();
  }
}

/// Progress percentage for onboarding
@riverpod
double onboardingProgress(OnboardingProgressRef ref) {
  final state = ref.watch(onboardingProvider);
  return (state.currentStep + 1) / totalOnboardingSteps;
}
