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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
        final isLoggedIn = authProvider.isAuthenticated;
        final hasBusinessProfile = authProvider.currentUser?.hasBusinessProfile ?? false;
        
        // Handle splash screen
        if (state.pathParameters == '/splash') {
          if (!authProvider.isInitialized) return '/splash';
          if (!isLoggedIn) return '/auth';
          if (!hasBusinessProfile) return '/business-setup';
          return '/main';
        }
        
        // Redirect logic for other routes
        if (!isLoggedIn && state.pathParameters != '/auth') return '/auth';
        if (isLoggedIn && !hasBusinessProfile && state.pathParameters != '/business-setup') {
          return '/business-setup';
        }
        if (isLoggedIn && hasBusinessProfile && (state.pathParameters == '/auth' || state.pathParameters == '/business-setup')) {
          return '/main';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/business-setup',
          builder: (context, state) => const BusinessSetupScreen(),
        ),
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainScreen(),
        ),
      ],
    );
  }
}