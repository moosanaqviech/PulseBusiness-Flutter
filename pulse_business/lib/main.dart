import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/deals_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/business_setup/business_setup_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/theme.dart';


import 'services/redemption_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
            return const AuthScreen();
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
      ],
    );
  }
}