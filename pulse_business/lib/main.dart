import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_business/screens/stripe/stripe_success_screen.dart';

import 'firebase_options.dart';
import 'models/purchase.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/deals_provider.dart';
import 'screens/main/login_screen.dart';
import 'screens/stripe/stripe_onboarding_screen.dart';
import 'services/stripe_connect_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/business_setup/business_setup_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/qr_scanner/redemption_success_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/theme.dart';


import 'services/redemption_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      debugPrint('✅ Auth working - SHA-1 is correct');
      print('✅ Auth working - SHA-1 is correct');
    } else {
      print('❌ No userX - need to sign in first');
    }
  } catch (e) {
    debugPrint('❌ Auth test failed: $e');
    debugPrint('💡 This confirms SHA-1 fingerprint mismatch');
  }
  //await DatabaseHelper.initializeOnAppStart();
  runApp(const PulseBusinessApp());
}

class PulseBusinessApp extends StatelessWidget {
  const PulseBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => DealsProvider()),
        ChangeNotifierProvider(create: (_) => RedemptionService()),
        ChangeNotifierProvider(create: (_) => StripeConnectService()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Pulse Business',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }

 GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isInitialized = authProvider.isInitialized;
        final isLoggedIn = authProvider.isAuthenticated;
        final hasBusinessProfile = authProvider.currentUser?.hasBusinessProfile ?? false;
        
        print('🔧 Router: Redirect check - Location: "$location"');
        print('🔧 Router: isInitialized: $isInitialized');
        print('🔧 Router: isLoggedIn: $isLoggedIn');
        print('🔧 Router: hasBusinessProfile: $hasBusinessProfile');
        
        // Show splash while initializing
        if (!isInitialized) {
          print('🔧 Router: Not initialized, staying on splash');
          return '/splash';
        }
        
        // If we're on splash and initialization is complete, redirect based on auth state
        if (location == '/splash') {
          if (!isLoggedIn) {
            print('🔧 Router: Initialized, not logged in, redirecting to auth');
            return '/auth';
          }
          if (!hasBusinessProfile) {
            print('🔧 Router: Logged in, no business profile, redirecting to setup');
            return '/business-setup';
          }
          print('🔧 Router: Logged in with business profile, redirecting to main');
          return '/main';
        }
        
        // Protect routes based on auth state
        if (!isLoggedIn && location != '/auth') {
          print('🔧 Router: Not logged in, redirecting to auth');
          return '/auth';
        }
        
        if (isLoggedIn && !hasBusinessProfile && location != '/business-setup') {
          print('🔧 Router: Logged in but no business profile, redirecting to setup');
          return '/business-setup';
        }
        
        if (isLoggedIn && hasBusinessProfile && (location == '/auth' || location == '/business-setup')) {
          print('🔧 Router: Complete profile, redirecting to main');
          return '/main';
        }
        
        print('🔧 Router: No redirect needed, staying on: "$location"');
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) {
            print('🔧 Router: Building splash screen');
            return const SplashScreen();
          },
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            print('🔧 Router: Building auth screen');
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: '/business-setup',
          builder: (context, state) {
            print('🔧 Router: Building business setup screen');
            return const BusinessSetupScreen();
          },
        ),
        GoRoute(
          path: '/main',
          builder: (context, state) {
            print('🔧 Router: Building main screen');
            return const MainScreen();
          },
        ),

        GoRoute(
        path: '/stripe-onboarding',
        builder: (context, state) {
          final canSkip = state.extra as bool? ?? true;
          return StripeOnboardingScreen(canSkip: canSkip);
        },
      ),
        // ROUTE for redemption success
        GoRoute(
          path: '/redemption-success',
          builder: (context, state) {
            print('🔧 Router: Building redemption success screen');
            final redeemedVoucher = state.extra as Purchase?;
            if (redeemedVoucher == null) {
              // If no voucher data, redirect back to main
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/main');
              });
              return const SizedBox(); // Temporary widget while redirecting
            }
            return RedemptionSuccessScreen(redeemedVoucher: redeemedVoucher);
  },
),
        GoRoute(
          path: '/stripe-success',
          builder: (context, state) => const StripeSuccessScreen(),
        ),
      ],
    );
  }
}