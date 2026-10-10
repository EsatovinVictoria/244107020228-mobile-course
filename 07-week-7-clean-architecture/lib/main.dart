import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/debug_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  registerBackgroundHandler();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter router;
  late final PushService _pushService;
  String? _pendingNotificationRoute;

  @override
  void initState() {
    super.initState();

    _pushService = PushService(api: ref.read(apiClientProvider));

    router = GoRouter(
      initialLocation: AppRoutes.login,
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);

        if (authState.isLoading) {
          return null;
        }

        final loggedIn = authState.asData?.value ?? false;
        final goingLogin = state.matchedLocation == AppRoutes.login;

        if (!loggedIn) {
          return goingLogin ? null : AppRoutes.login;
        }

        final pendingRoute = _pendingNotificationRoute;

        if (pendingRoute != null) {
          _pendingNotificationRoute = null;

          return state.matchedLocation == pendingRoute ? null : pendingRoute;
        }

        return goingLogin ? AppRoutes.home : null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.debug,
          builder: (context, state) => const DebugPage(),
        ),
        GoRoute(
          path: AppRoutes.announcementPattern,
          builder: (context, state) {
            return AnnouncementPage(id: state.pathParameters['id'] ?? '');
          },
        ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_initMessaging());
    });
  }

  Future<void> _initMessaging() async {
    try {
      void goFromNotification(String route) {
        if (!mounted) return;

        // Simpan tujuan, lalu minta router memeriksa status login.
        _pendingNotificationRoute = route;
        router.refresh();
      }

      await _pushService.initialize(onRoute: goFromNotification);
      debugPrint('Inisialisasi FCM dan notifikasi lokal selesai.');
    } catch (error) {
      debugPrint('Inisialisasi messaging gagal: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      router.refresh();
    });

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }

  @override
  void dispose() {
    unawaited(_pushService.dispose());

    router.dispose();
    super.dispose();
  }
}
