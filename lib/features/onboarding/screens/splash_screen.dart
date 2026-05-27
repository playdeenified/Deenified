import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';
import '../../../services/revenuecat_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Check auth status after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateBasedOnAuth();
      }
    });
  }

  Future<void> _navigateBasedOnAuth() async {
    final isUserAuth = ref.read(isAuthenticatedProvider);

    if (isUserAuth) {
      // Check if user has premium access
      final hasPremium = await RevenueCatService.instance.hasPremiumAccess();

      if (mounted) {
        if (hasPremium) {
          context.go(AppRoutes.home);
        } else {
          // No premium — show renewal paywall
          context.go(AppRoutes.renew);
        }
      }
    } else {
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.metallicGold,
                      AppColors.softGold,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.metallicGold.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories,
                  size: 60,
                  color: AppColors.richBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // App Name
              Text(
                'Deenified',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.metallicGold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Islamic trivia',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
