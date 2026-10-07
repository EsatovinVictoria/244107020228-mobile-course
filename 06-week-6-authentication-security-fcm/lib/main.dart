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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  registerBackgroundHandler();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter router;
  String? _pendingNotificationRoute;

  @override
  void initState() {
    super.initState();

    router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);

        if (authState.isLoading) {
          return null;
        }

        final loggedIn = authState.asData?.value ?? false;
        final goingLogin = state.matchedLocation == '/login';

        if (!loggedIn) {
          return goingLogin ? null : '/login';
        }

        // Setelah login siap, buka tujuan notifikasi yang disimpan.
        final pendingRoute = _pendingNotificationRoute;

        if (pendingRoute != null) {
          _pendingNotificationRoute = null;

          if (state.matchedLocation != pendingRoute) {
            return pendingRoute;
          }

          return null;
        }

        if (goingLogin) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/debug',
          builder: (context, state) => const DebugPage(),
        ),
        GoRoute(
          path: '/pengumuman/:id',
          builder: (context, state) {
            return AnnouncementPage(
              id: state.pathParameters['id'] ?? '',
            );
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

      await initLocalNotifications(goFromNotification);
      await listenForeground(goFromNotification);

      // Proses notifikasi yang membuka aplikasi dari terminated.
      await handleTerminated(goFromNotification);

      final granted = await requestNotificationPermission();

      if (!granted) {
        debugPrint('Izin notifikasi belum diberikan.');
        return;
      }

      debugPrint('Izin notifikasi diberikan.');

      await initFcmToken(
        onToken: (token) async {
          debugPrint(
            'Token FCM diterima; backend belum dikonfigurasi.',
          );
        },
      );

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
    unawaited(disposeMessageListeners());
    unawaited(disposeFcmToken());

    router.dispose();
    super.dispose();
  }
}