import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../services/supabase_service.dart';
import '../../../services/revenuecat_service.dart';
import '../providers/onboarding_provider.dart';

class SignupFormScreen extends ConsumerStatefulWidget {
  const SignupFormScreen({super.key});

  @override
  ConsumerState<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends ConsumerState<SignupFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedCountryCode = '+1';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static const _countryCodes = [
    {'code': '+1', 'country': 'US/CA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+91', 'country': 'IN'},
    {'code': '+92', 'country': 'PK'},
    {'code': '+880', 'country': 'BD'},
    {'code': '+20', 'country': 'EG'},
    {'code': '+966', 'country': 'SA'},
    {'code': '+971', 'country': 'AE'},
    {'code': '+60', 'country': 'MY'},
    {'code': '+62', 'country': 'ID'},
    {'code': '+90', 'country': 'TR'},
    {'code': '+33', 'country': 'FR'},
    {'code': '+49', 'country': 'DE'},
    {'code': '+234', 'country': 'NG'},
    {'code': '+27', 'country': 'ZA'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final onboardingState = ref.read(onboardingProvider);

      // Pass all onboarding data as metadata so the handle_new_user()
      // trigger can populate public.users even before email confirmation.
      await SupabaseService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone':
              '$_selectedCountryCode${_phoneController.text.replaceAll('-', '').trim()}',
          if (onboardingState.userType != null)
            'user_type': onboardingState.userType,
          if (onboardingState.motivation != null)
            'motivation': onboardingState.motivation,
          'barriers': onboardingState.barriers,
          if (onboardingState.relationshipWithAllah != null)
            'relationship_with_allah': onboardingState.relationshipWithAllah,
          if (onboardingState.learningStyle != null)
            'learning_style': onboardingState.learningStyle,
          if (onboardingState.practiceTime != null)
            'practice_time': onboardingState.practiceTime,
          if (onboardingState.commitmentLevel != null)
            'commitment_level': onboardingState.commitmentLevel,
        },
      );

      // After signUp with email confirmation enabled, currentUser may be null.
      // The handle_new_user trigger reads raw_user_meta_data to populate the
      // users table, so no manual upsert is needed here.
      final user = SupabaseService.instance.currentUser;

      if (mounted) {
        ref.read(onboardingProvider.notifier).completeOnboarding();

        if (user != null) {
          // Sync user ID with RevenueCat
          await RevenueCatService.instance.login(user.id);
          // No email confirmation required — go straight to home
          context.go('/home');
        } else {
          // Email confirmation required — tell user to check email
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created! Please check your email to confirm, then sign in.',
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 5),
            ),
          );
          context.go('/login');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Could not create account. Please try again.';
        if (e.message.contains('already registered') ||
            e.message.contains('already been registered')) {
          message = 'This email is already registered. Please sign in instead.';
        } else if (e.message.contains('weak_password') ||
            e.message.contains('password')) {
          message = 'Password is too weak. Please use a stronger password.';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Header
              Text(
                'Create Your Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.metallicGold,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Almost there! Set up your account to save your progress.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // First Name & Last Name side by side
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.metallicGold),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.metallicGold),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.metallicGold),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.metallicGold),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Phone Number Field with Country Code
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Code Dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        dropdownColor: AppColors.deepCharcoal,
                        style: Theme.of(context).textTheme.bodyMedium,
                        items: _countryCodes.map((cc) {
                          return DropdownMenuItem(
                            value: cc['code'],
                            child: Text(
                              '${cc['code']} ${cc['country']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCountryCode = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Phone Number Input
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _PhoneNumberFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '555-123-4567',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.metallicGold),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        final digits = value.replaceAll('-', '');
                        if (digits.length < 7) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Terms
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                  children: [
                    const TextSpan(
                        text: 'By creating an account, you agree to our '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _launchUrl('https://deenified.com/pages/terms'),
                        child: Text(
                          'Terms of Service',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.metallicGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.metallicGold,
                                  ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () =>
                            _launchUrl('https://deenified.com/pages/privacy'),
                        child: Text(
                          'Privacy Policy',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.metallicGold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.metallicGold,
                                  ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.metallicGold,
                      ),
                    )
                  : PremiumButton(
                      text: 'CREATE ACCOUNT & START LEARNING',
                      onPressed: _handleSignup,
                    ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formats phone digits as XXX-XXX-XXXX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 10) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
