import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/revenuecat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up lock-screen / notification audio controls so Quran recitation
  // keeps playing when the screen sleeps or the user backgrounds the app.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.deenified.audio.channel',
    androidNotificationChannelName: 'Deenified Recitation',
    androidNotificationOngoing: true,
  );

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize RevenueCat
  await _initializeRevenueCat();

  // Link RevenueCat user to Supabase user (if already logged in)
  await _linkRevenueCatUser();

  // Listen for subscription changes and sync to Supabase
  _setupSubscriptionListener();

  // Listen for Supabase auth changes to link/unlink RevenueCat
  _setupAuthListener();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: DeenifiedApp()));
}

/// Initialize RevenueCat SDK
Future<void> _initializeRevenueCat() async {
  await Purchases.setLogLevel(LogLevel.warn);

  final configuration = PurchasesConfiguration(
    dotenv.env['REVENUECAT_API_KEY']!,
  )..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();

  await Purchases.configure(configuration);
}

/// Link RevenueCat user to Supabase user if already authenticated
Future<void> _linkRevenueCatUser() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    developer.log(
      'Linking RevenueCat to Supabase user: ${user.id}',
      name: 'App',
    );
    await RevenueCatService.instance.login(user.id);
  }
}

/// Listen for customer info updates (purchase, restore, expiration, renewal)
/// and sync subscription status to Supabase
void _setupSubscriptionListener() {
  RevenueCatService.instance.addCustomerInfoListener((customerInfo) {
    developer.log(
      'CustomerInfo updated — syncing to Supabase',
      name: 'App',
    );
    RevenueCatService.instance.syncSubscriptionToSupabase(customerInfo);
  });
}

/// Listen for Supabase auth state changes to link/unlink RevenueCat user
void _setupAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final user = data.session?.user;

    if (event == AuthChangeEvent.signedIn && user != null) {
      developer.log(
        'Auth: signed in — linking RevenueCat to ${user.id}',
        name: 'App',
      );
      await RevenueCatService.instance.login(user.id);
    } else if (event == AuthChangeEvent.signedOut) {
      developer.log(
        'Auth: signed out — logging out RevenueCat',
        name: 'App',
      );
      await RevenueCatService.instance.logout();
    }
  });
}

/// Get the Supabase client instance
SupabaseClient get supabase => Supabase.instance.client;

class DeenifiedApp extends StatelessWidget {
  const DeenifiedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Deenified',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
