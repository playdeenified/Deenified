import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/onboarding_provider.dart';

/// "Rate us — it would help a ton." Triggers the native StoreKit review
/// prompt. Placed right after the "Plan complete!" dopamine beat.
class RatingsScreen extends ConsumerStatefulWidget {
  const RatingsScreen({super.key});

  @override
  ConsumerState<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends ConsumerState<RatingsScreen>
    with SingleTickerProviderStateMixin {
  final _inAppReview = InAppReview.instance;
  late final AnimationController _shimmer;
  // Once they tap "Rate Us", the button becomes "Continue" and they stay
  // on the screen until they manually advance.
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _requestReview() async {
    HapticFeedback.mediumImpact();
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
      // Never block onboarding on a rating failure.
    }
    // Do NOT auto-advance — flip the button to "Continue" and let the user
    // tap it themselves once they're done with the rating prompt.
    if (mounted) {
      setState(() => _rated = true);
    }
  }

  void _advance() {
    HapticFeedback.lightImpact();
    ref.read(onboardingProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),

          // Animated row of gold stars
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final t = (_shimmer.value * 5 - i).clamp(0.0, 1.0);
                  final scale = 1.0 + (0.18 * (t < 0.5 ? t : 1 - t) * 2);
                  return Transform.scale(
                    scale: scale,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.metallicGold,
                        size: 40,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Rate Deenified',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We\'re a small team building this for the Ummah. '
            'A quick rating would help a ton and lets more Muslims find us.',
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
            child: _rated
                ? PremiumButton(
                    text: 'CONTINUE',
                    onPressed: _advance,
                  )
                : PremiumButton(
                    text: 'RATE US',
                    icon: Icons.favorite_rounded,
                    onPressed: _requestReview,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // "Maybe later" only before they've rated.
          if (!_rated)
            TextButton(
              onPressed: _advance,
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(height: 40),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
