import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// Quick dopamine beat after the loading screen: "Plan complete!"
class PlanCompleteScreen extends ConsumerStatefulWidget {
  const PlanCompleteScreen({super.key});

  @override
  ConsumerState<PlanCompleteScreen> createState() =>
      _PlanCompleteScreenState();
}

class _PlanCompleteScreenState extends ConsumerState<PlanCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _pop = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          ScaleTransition(
            scale: _pop,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.softGold, AppColors.metallicGold],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.metallicGold.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 72,
                color: AppColors.heroBlack,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Plan complete!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We\'ve built a personalized path to help you reconnect '
            'with the Qur\'an — one small habit at a time.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              text: 'CONTINUE',
              onPressed: () =>
                  ref.read(onboardingProvider.notifier).nextStep(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
