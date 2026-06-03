import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/onboarding_provider.dart';

/// Smooth, continuous loading screen used between onboarding phases.
///
/// IMPORTANT: a PageView constructs this screen *before* the user reaches it,
/// so the progress run + auto-advance must only fire once it's the ACTIVE
/// step. [stepIndex] is this screen's position; we compare against
/// currentStep and only start when they match (prevents the double-advance
/// "skip to auth" glitch).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key, required this.stepIndex});

  final int stepIndex;

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _breatheController;
  bool _advanced = false;
  bool _started = false;

  final List<String> _messages = [
    'Building your plan...',
    'Analyzing your learning style...',
    'Selecting your starting Surahs...',
    'Curating audio stories...',
    'Personalizing your daily goals...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    // Built but NOT started — _startIfActive() kicks it off when visible.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(_handleTick);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  void _startIfActive() {
    if (_started) return;
    if (ref.read(onboardingProvider).currentStep == widget.stepIndex) {
      _started = true;
      _progressController.forward();
    }
  }

  void _handleTick() {
    if (!_advanced && _progressController.value >= 1.0) {
      _advanced = true;
      // Advance only if we're still the active page.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted &&
            ref.read(onboardingProvider).currentStep == widget.stepIndex) {
          ref.read(onboardingProvider.notifier).nextStep();
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController
      ..removeListener(_handleTick)
      ..dispose();
    _breatheController.dispose();
    super.dispose();
  }

  int _messageIndex(double progress) {
    final i = (progress * _messages.length).floor();
    return i.clamp(0, _messages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    // Re-runs whenever currentStep changes; starts the run when we land here.
    ref.watch(onboardingProvider.select((s) => s.currentStep));
    _startIfActive();

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = Curves.easeInOutCubic.transform(
          _progressController.value,
        );
        final messageIndex = _messageIndex(progress);
        final percent = (progress * 100).round();

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Breathing halo behind the spinner
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, _) {
                        final scale = 0.85 + (_breatheController.value * 0.20);
                        final opacity =
                            0.10 + (0.15 * (1 - _breatheController.value));
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.metallicGold
                                      .withValues(alpha: opacity),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: AppColors.metallicGold
                            .withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.metallicGold,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.metallicGold,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Smooth cross-fade between messages
              SizedBox(
                height: 60,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    key: ValueKey<int>(messageIndex),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      _messages[messageIndex],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
