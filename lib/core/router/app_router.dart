import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/inbox/inbox_screen.dart';
import '../../screens/archive/archive_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/url_analysis/url_analysis_screen.dart';
import '../../screens/analysis/manual_analysis_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      
      // Use a simpler approach for route checking
      final currentPath = state.uri.path;
      final isAuthRoute = currentPath.contains('auth') || currentPath.contains('login') || currentPath.contains('register');
      
      // Don't redirect if we're on splash screen
      if (currentPath == '/splash') {
        return null;
      }
      
      // Allow access to main app routes without authentication
      // Only redirect to login if user is trying to access auth routes while logged in
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main App Routes
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/archive',
            builder: (context, state) => const ArchiveScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // URL Analysis Route (outside shell for full screen)
      GoRoute(
        path: '/url-analysis',
        builder: (context, state) {
          // For go_router 12.1.3, use a simpler approach without query parameters
          return const UrlAnalysisScreen(
            url: '',
            messageId: null,
            sender: null,
          );
        },
      ),
      
      // Manual Analysis Route (outside shell for full screen)
      GoRoute(
        path: '/manual-analysis',
        builder: (context, state) => const ManualAnalysisScreen(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive_outlined),
            activeIcon: Icon(Icons.archive),
            label: 'Archive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  int _getCurrentIndex(BuildContext context) {
    // Simple hardcoded approach for now
    return 0; // Default to dashboard
  }
  
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/inbox');
        break;
      case 2:
        context.go('/archive');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}
