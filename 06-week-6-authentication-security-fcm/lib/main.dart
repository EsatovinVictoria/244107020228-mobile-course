import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter router;

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

        final loggedIn = authState.value ?? false;

        final goingLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingLogin) {
          return '/login';
        }

        if (loggedIn && goingLogin) {
          return '/';
        }

        return null;
      },

      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

        GoRoute(path: '/', builder: (context, state) => const HomePage()),

        GoRoute(
          path: '/pengumuman/:id',
          builder: (context, state) {
            return AnnouncementPage(id: state.pathParameters['id'] ?? '');
          },
        ),
      ],
    );
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
    router.dispose();
    super.dispose();
  }
}
