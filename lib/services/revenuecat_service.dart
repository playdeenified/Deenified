import 'dart:developer' as developer;

import 'package:purchases_flutter/purchases_flutter.dart';

import 'supabase_service.dart';

/// Service for managing RevenueCat subscriptions
class RevenueCatService {
  RevenueCatService._();

  static final instance = RevenueCatService._();

  /// Entitlement identifier for premium access
  static const String premiumEntitlement = 'Deenified Pro';

  /// Product identifiers (matching App Store Connect)
  static const String monthlyProductId = 'df_11.99_1m';
  static const String yearlyProductId = 'df_59.99_1y';

  /// Get current customer info
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// Check if user has premium access
  Future<bool> hasPremiumAccess() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(premiumEntitlement);
    } catch (e) {
      return false;
    }
  }

  /// Get premium entitlement info
  Future<EntitlementInfo?> getPremiumEntitlement() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.entitlements.active[premiumEntitlement];
    } catch (e) {
      return null;
    }
  }

  /// Get available offerings (products)
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  /// Get the current (default) offering
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      // Debug logging for package resolution
      if (current != null) {
        developer.log(
          'Offering "${current.identifier}" has ${current.availablePackages.length} packages',
          name: 'RevenueCat',
        );
        for (final pkg in current.availablePackages) {
          developer.log(
            '  Package: ${pkg.identifier} | type: ${pkg.packageType} | '
            'product: ${pkg.storeProduct.identifier} | '
            'price: ${pkg.storeProduct.priceString}',
            name: 'RevenueCat',
          );
        }
        developer.log(
          '  .monthly = ${current.monthly?.identifier ?? "null"}, '
          '.annual = ${current.annual?.identifier ?? "null"}',
          name: 'RevenueCat',
        );
      }

      return current;
    } catch (e) {
      developer.log('Error fetching offerings: $e', name: 'RevenueCat');
      return null;
    }
  }

  /// Purchase a package
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);

      // Sync to Supabase after successful purchase
      await syncSubscriptionToSupabase(customerInfo);

      return customerInfo;
    } catch (e) {
      if (e is PurchasesErrorCode) {
        return null;
      }
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();

      // Sync to Supabase after restore
      await syncSubscriptionToSupabase(customerInfo);

      return customerInfo;
    } catch (e) {
      return null;
    }
  }

  /// Login user to RevenueCat (links Supabase user ID)
  Future<LogInResult?> login(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      developer.log(
        'RevenueCat login: userId=$userId, isNewUser=${result.created}',
        name: 'RevenueCat',
      );

      // Sync subscription status after login
      await syncSubscriptionToSupabase(result.customerInfo);

      return result;
    } catch (e) {
      developer.log('RevenueCat login error: $e', name: 'RevenueCat');
      return null;
    }
  }

  /// Logout user from RevenueCat
  Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      // Handle logout error
    }
  }

  /// Add listener for customer info updates
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Sync RevenueCat subscription status to Supabase.
  ///
  /// IMPORTANT: we only ever write 'expired' when we have an AUTHORITATIVE
  /// negative — i.e. the premium entitlement exists in customerInfo but is
  /// no longer active. If the entitlement is simply ABSENT (which happens on
  /// cold start before RevenueCat has synced from the network, on a blip, or
  /// in sandbox latency), we leave Supabase untouched. Blindly writing
  /// 'expired' there would wrongly downgrade a paying customer.
  Future<void> syncSubscriptionToSupabase(CustomerInfo customerInfo) async {
    try {
      final active = customerInfo.entitlements.active[premiumEntitlement];
      final known = customerInfo.entitlements.all[premiumEntitlement];

      if (active != null && active.isActive) {
        // Authoritative positive — active premium.
        await SupabaseService.instance.updateSubscriptionStatus(
          status: 'premium',
          expiresAt: active.expirationDate != null
              ? DateTime.parse(active.expirationDate!)
              : null,
        );
        developer.log(
          'Synced to Supabase: premium, expires=${active.expirationDate}',
          name: 'RevenueCat',
        );
      } else if (known != null) {
        // Authoritative negative — entitlement exists but is not active
        // (genuinely lapsed/expired). Safe to downgrade.
        await SupabaseService.instance.updateSubscriptionStatus(
          status: 'expired',
          expiresAt: null,
        );
        developer.log('Synced to Supabase: expired (lapsed)',
            name: 'RevenueCat');
      } else {
        // Unknown — no entitlement info yet. Do NOT touch Supabase so we
        // never downgrade a paying user during an unsynced cold start.
        developer.log(
          'Skipped Supabase sync: entitlement state unknown (not downgrading)',
          name: 'RevenueCat',
        );
      }
    } catch (e) {
      developer.log('Failed to sync subscription to Supabase: $e',
          name: 'RevenueCat');
    }
  }

  /// Get subscription status details
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final customerInfo = await getCustomerInfo();
    final premium = customerInfo.entitlements.active[premiumEntitlement];

    if (premium == null) {
      return SubscriptionStatus(
        isActive: false,
        type: SubscriptionType.none,
      );
    }

    return SubscriptionStatus(
      isActive: premium.isActive,
      type: premium.productIdentifier == yearlyProductId
          ? SubscriptionType.yearly
          : SubscriptionType.monthly,
      expirationDate: premium.expirationDate != null
          ? DateTime.parse(premium.expirationDate!)
          : null,
      willRenew: premium.willRenew,
    );
  }
}

/// Subscription status model
class SubscriptionStatus {
  final bool isActive;
  final SubscriptionType type;
  final DateTime? expirationDate;
  final bool willRenew;

  SubscriptionStatus({
    required this.isActive,
    required this.type,
    this.expirationDate,
    this.willRenew = false,
  });
}

/// Subscription types
enum SubscriptionType {
  none,
  monthly,
  yearly,
}
