import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../services/supabase_service.dart';
import '../../../services/revenuecat_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null) {
        await RevenueCatService.instance.login(response.user!.id);
      }

      if (mounted) {
        final hasPremium = await RevenueCatService.instance.hasPremiumAccess();
        if (mounted) {
          if (hasPremium) {
            context.go('/home');
          } else {
            context.go('/renew');
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Invalid Username or Password';
        if (e.message.contains('Email not confirmed')) {
          message = 'Please confirm your email before signing in.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.deepCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);

              try {
                await SupabaseService.instance
                    .resetPassword(resetEmailController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Password reset email sent! Check your inbox.',
                      ),
                      backgroundColor: AppColors.metallicGold,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Send Reset Link',
              style: TextStyle(color: AppColors.metallicGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignInSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(
                              top: AppSpacing.sm,
                              bottom: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glassBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(sheetContext),
                              child: Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.richBlack,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Welcome back',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: Text(
                            'Sign in to keep your streak going.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.metallicGold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : PremiumButton(
                                text: 'SIGN IN',
                                onPressed: () async {
                                  await _handleSignIn();
                                  if (mounted) setSheetState(() {});
                                },
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: Stack(
        children: [
          // Subtle radial gold glow behind the title
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.9,
                  colors: [
                    AppColors.metallicGold.withValues(alpha: 0.10),
                    AppColors.richBlack,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quote pinned near the top
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Text(
                    '"Seek knowledge from the cradle to the grave."',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Title block sits high, not vertically centered
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Deenified',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.metallicGold,
                              fontSize: 56,
                              height: 1.0,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ISLAMIC TRIVIA',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w500,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Spacer pushes the card to the bottom
                const Spacer(),

                // Big bottom card — full width, lower, taller
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.deepCharcoal,
                        AppColors.richBlack,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color:
                            AppColors.metallicGold.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.metallicGold.withValues(alpha: 0.10),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Learn the Deen through\nfun, daily trivia.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Bite-sized questions. Real knowledge. Every day.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumButton(
                          text: 'GET STARTED',
                          onPressed: () => context.go('/onboarding'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Have an account?',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _showSignInSheet,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.metallicGold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
