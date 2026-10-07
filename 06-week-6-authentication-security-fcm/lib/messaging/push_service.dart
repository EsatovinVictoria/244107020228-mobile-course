import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    'FCM background diterima. Message ID: ${message.messageId}',
  );
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
}

final fcmTokenPreview = ValueNotifier<String>('Belum tersedia');
final fcmTokenSource = ValueNotifier<String>('Belum ada event token');
final fcmTopicStatus = ValueNotifier<String>('Belum berlangganan');

StreamSubscription<String>? _tokenSubscription;

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

String _shortenToken(String token) {
  final length = token.length < 12 ? token.length : 12;
  return '${token.substring(0, length)}...';
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  await _tokenSubscription?.cancel();

  Future<void> handleToken(String token, String source) async {
    fcmTokenPreview.value = _shortenToken(token);
    fcmTokenSource.value = source;

    debugPrint('FCM [$source]: ${fcmTokenPreview.value}');

    await onToken(token);
  }

  _tokenSubscription =
      FirebaseMessaging.instance.onTokenRefresh.listen(
    (token) async {
      try {
        await handleToken(token, 'onTokenRefresh');
      } catch (_) {
        debugPrint('Callback pembaruan token FCM gagal.');
      }
    },
    onError: (Object error) {
      debugPrint('Listener token FCM mengalami kesalahan.');
    },
  );

  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await handleToken(token, 'getToken');
  } else {
    fcmTokenPreview.value = 'Token belum tersedia';
  }

  await FirebaseMessaging.instance.subscribeToTopic(
    'pengumuman-kampus',
  );

  fcmTopicStatus.value = 'Berlangganan pengumuman-kampus';
}

Future<void> disposeFcmToken() async {
  await _tokenSubscription?.cancel();
  _tokenSubscription = null;
}

final _local = FlutterLocalNotificationsPlugin();

StreamSubscription<RemoteMessage>? _foregroundSubscription;
StreamSubscription<RemoteMessage>? _openedAppSubscription;


String? pendingDeepLink;

String _notificationRoute(String? route) {
  if (route == '/') return '/';

  if (route != null &&
      RegExp(r'^/pengumuman/[0-9]+$').hasMatch(route)) {
    return route;
  }

  return '/';
}

Future<void> initLocalNotifications(
  void Function(String route) go,
) async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await _local.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (response) {
      final route = _notificationRoute(response.payload);

      debugPrint('Notifikasi lokal diklik: $route');
      go(route);
    },
  );

  const channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    description: 'Notifikasi pengumuman kampus',
    importance: Importance.high,
  );

  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final launchDetails = await _local.getNotificationAppLaunchDetails();

  if (launchDetails?.didNotificationLaunchApp ?? false) {
    pendingDeepLink = _notificationRoute(
      launchDetails?.notificationResponse?.payload,
    );
  }
}

Future<void> listenForeground(
  void Function(String route) go,
) async {
  await _foregroundSubscription?.cancel();
  await _openedAppSubscription?.cancel();

  _foregroundSubscription = FirebaseMessaging.onMessage.listen(
    (message) async {
      try {
        final route = _notificationRoute(
          message.data['route']?.toString(),
        );

        debugPrint('FCM foreground diterima: $route');

        const androidDetails = AndroidNotificationDetails(
          'pengumuman',
          'Pengumuman Kampus',
          channelDescription: 'Notifikasi pengumuman kampus',
          importance: Importance.high,
          priority: Priority.high,
        );

        await _local.show(
          id: message.hashCode & 0x7fffffff,
          title: message.notification?.title ?? 'Pengumuman',
          body: message.notification?.body ?? '',
          notificationDetails: const NotificationDetails(
            android: androidDetails,
          ),
          payload: route,
        );
      } catch (error) {
        debugPrint('Gagal menampilkan notifikasi lokal: $error');
      }
    },
  );

  _openedAppSubscription =
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = _notificationRoute(
      message.data['route']?.toString(),
    );

    debugPrint('Notifikasi background diklik: $route');
    go(route);
  });
}

Future<void> disposeMessageListeners() async {
  await _foregroundSubscription?.cancel();
  await _openedAppSubscription?.cancel();

  _foregroundSubscription = null;
  _openedAppSubscription = null;
}

Future<void> handleTerminated(
  void Function(String route) go,
) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();

  final localRoute = pendingDeepLink;
  pendingDeepLink = null;

  if (initial != null) {
    final route = _notificationRoute(
      initial.data['route']?.toString(),
    );

    debugPrint('Notifikasi terminated diklik: $route');
    go(route);
  } else if (localRoute != null) {
    debugPrint('Notifikasi lokal membuka aplikasi: $localRoute');
    go(localRoute);
  }
}

Future<void> subscribePengumuman() async {
  await FirebaseMessaging.instance.subscribeToTopic(
    'pengumuman-kampus',
  );

  fcmTopicStatus.value = 'Berlangganan pengumuman-kampus';
  debugPrint('Subscribe pengumuman-kampus berhasil.');
}

Future<void> unsubscribePengumuman() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic(
    'pengumuman-kampus',
  );

  fcmTopicStatus.value = 'Tidak berlangganan pengumuman-kampus';
  debugPrint('Unsubscribe pengumuman-kampus berhasil.');
}