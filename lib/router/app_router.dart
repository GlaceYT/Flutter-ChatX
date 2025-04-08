import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_step1_screen.dart';
import '../features/auth/screens/register_step2_screen.dart';
import '../features/auth/screens/register_step3_screen.dart';
import '../features/auth/screens/register_step4_screen.dart';
import '../features/auth/screens/register_step5_screen.dart';
import '../features/tabs/tabs_screen.dart';
import '../features/core/screens/splash_screen.dart'; // Adjust import path

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => _safe(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => _safe(const LoginScreen()),
      ),
      GoRoute(
        path: '/register-step1',
        builder: (context, state) => _safe(const RegisterStep1Screen()),
      ),
      GoRoute(
        path: '/register-step2',
        builder: (context, state) {
          final name = (state.extra as Map)['name'] ?? '';
          return _safe(RegisterStep2Screen(name: name));
        },
      ),
      GoRoute(
        path: '/register-step3',
        builder: (context, state) {
          final data = state.extra as Map;
          return _safe(RegisterStep3Screen(
            name: data['name'],
            username: data['username'],
          ));
        },
      ),
      GoRoute(
        path: '/register-step4',
        builder: (context, state) {
          final data = state.extra as Map;
          return _safe(RegisterStep4Screen(
            name: data['name'],
            username: data['username'],
            email: data['email'],
          ));
        },
      ),
      GoRoute(
        path: '/register-step5',
        builder: (context, state) {
          final data = state.extra as Map;
          return _safe(RegisterStep5Screen(
            name: data['name'],
            username: data['username'],
            email: data['email'],
            phone: data['phone'],
          ));
        },
      ),
      GoRoute(
        path: '/tabs',
        builder: (context, state) => _safe(const TabsScreen()),
      ),
    ],
  );
});

Widget _safe(Widget child) => SafeArea(child: child);
