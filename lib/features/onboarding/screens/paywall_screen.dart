import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../services/revenuecat_service.dart';
import '../providers/onboarding_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package> _packages = [];
  String _selectedPlan = 'yearly'; // Track selection by plan name, not Package
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadOfferings() async {
    final offering = await RevenueCatService.instance.getCurrentOffering();

    if (mounted) {
      setState(() {
        if (offering != null) {
          _packages = offering.availablePackages;
          developer.log(
            'Loaded ${_packages.length} packages from offering',
            name: 'Paywall',
          );
          for (final pkg in _packages) {
            developer.log(
              '  ${pkg.identifier} | type=${pkg.packageType} | '
              '${pkg.storeProduct.priceString}',
              name: 'Paywall',
            );
          }
        } else {
          developer.log('No offering loaded from RevenueCat', name: 'Paywall');
        }
        _isLoading = false;
      });
    }
  }

  /// Get the Package for the currently selected plan
  Package? get _selectedPackage {
    try {
      if (_selectedPlan == 'yearly') {
        return _packages.firstWhere((p) => p.packageType == PackageType.annual);
      } else {
        return _packages
            .firstWhere((p) => p.packageType == PackageType.monthly);
      }
    } catch (_) {
      return _packages.firstOrNull;
    }
  }

  /// Get a package's price string by type, with fallback
  String _priceFor(PackageType type, String fallback) {
    try {
      return _packages
          .firstWhere((p) => p.packageType == type)
          .storeProduct
          .priceString;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _handlePurchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to load subscription options. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    developer.log('Purchasing: ${pkg.identifier}', name: 'Paywall');
    setState(() => _isPurchasing = true);

    try {
      final customerInfo =
          await RevenueCatService.instance.purchasePackage(pkg);

      if (customerInfo != null &&
          customerInfo.entitlements.active
              .containsKey(RevenueCatService.premiumEntitlement)) {
        if (mounted) {
          ref.read(onboardingProvider.notifier).nextStep();
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase failed. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Purchase error: $e', name: 'Paywall');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isPurchasing = true);

    try {
      final CustomerInfo customerInfo = await Purchases.restorePurchases();

      // Sync to Supabase
      await RevenueCatService.instance.syncSubscriptionToSupabase(customerInfo);

      if (customerInfo.entitlements.all[RevenueCatService.premiumEntitlement]
              ?.isActive ==
          true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          ref.read(onboardingProvider.notifier).nextStep();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active subscription found.'),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.message ?? 'Unknown error'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Headline
                  Text(
                    'Unlock Full Access',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Start your journey with the Qur\'an today.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Value Props
                  _buildValueProp(
                    icon: Icons.headphones,
                    text: 'Unlimited Audio Stories',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildValueProp(
                    icon: Icons.emoji_events,
                    text: 'Surah Mastery Tracking',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildValueProp(
                    icon: Icons.quiz,
                    text: 'Gamified Trivia & Quizzes',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildValueProp(
                    icon: Icons.local_fire_department,
                    text: 'Streaks & XP Rewards',
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.metallicGold),
                    )
                  else ...[
                    // Yearly Plan
                    _buildPricingCard(
                      title: 'Yearly Access',
                      subtitle: '${_priceFor(PackageType.annual, '\$59.99')}/year',
                      price: _priceFor(PackageType.annual, '\$59.99'),
                      period: '/year',
                      badge: 'Best Value',
                      isSelected: _selectedPlan == 'yearly',
                      onTap: () => setState(() => _selectedPlan = 'yearly'),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Monthly Plan
                    _buildPricingCard(
                      title: 'Monthly Access',
                      subtitle: 'Billed monthly',
                      price: _priceFor(PackageType.monthly, '\$11.99'),
                      period: '/mo',
                      isSelected: _selectedPlan == 'monthly',
                      onTap: () => setState(() => _selectedPlan = 'monthly'),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Subscribe Button
                  _isPurchasing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.metallicGold,
                          ),
                        )
                      : PremiumButton(
                          text: 'SUBSCRIBE NOW',
                          onPressed: _handlePurchase,
                        ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'Cancel anytime. No hidden fees.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Restore Purchases
                  TextButton(
                    onPressed: _isPurchasing ? null : _handleRestore,
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Terms of Use & Privacy Policy (required by Apple 3.1.2c)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _launchUrl('https://deenified.com/pages/terms'),
                        child: Text(
                          'Terms of Use',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.metallicGold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.metallicGold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _launchUrl('https://deenified.com/pages/privacy'),
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.metallicGold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.metallicGold,
                                fontSize: 12,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValueProp({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.metallicGold.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: AppColors.metallicGold, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isSelected
              ? AppColors.metallicGold.withValues(alpha: 0.08)
              : AppColors.deepCharcoal,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            splashColor: AppColors.metallicGold.withValues(alpha: 0.15),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected
                      ? AppColors.metallicGold
                      : AppColors.glassBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.metallicGold
                            : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.metallicGold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.metallicGold
                                  : AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        period,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Badge
        if (badge != null)
          Positioned(
            top: -12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.metallicGold, AppColors.softGold],
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.richBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
