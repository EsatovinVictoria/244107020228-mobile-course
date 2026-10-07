import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _campusTopic = 'pengumuman-kampus';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: do not use BuildContext, ref, or navigate here.
  await Firebase.initializeApp();
  debugPrint('FCM background diterima: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

final fcmTokenPreview = ValueNotifier<String>('Belum tersedia');
final fcmTokenSource = ValueNotifier<String>('Belum ada event token');
final fcmTopicStatus = ValueNotifier<String>('Belum berlangganan');

class PushService {
  PushService({
    required this.api,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final Dio api;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _pendingLocalRoute;

  Future<void> initialize({
    required void Function(String route) onRoute,
  }) async {
    await _initializeLocalNotifications(onRoute);
    await _listenForMessages(onRoute);
    await _handleTerminatedMessage(onRoute);

    final granted = await requestPermission();
    if (!granted) {
      debugPrint('Izin notifikasi belum diberikan.');
      return;
    }

    await _initializeToken();
    await subscribePengumuman();
  }

  Future<bool> requestPermission() async {
    // iOS: this displays the APNs permission prompt and supports provisional
    // authorization. Android 13+: POST_NOTIFICATIONS is requested by FCM.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
    );

    // Android 13+: keep the explicit plugin request for local notifications.
    // It is harmless on older Android versions and a no-op on iOS.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _initializeToken() async {
    await _tokenSubscription?.cancel();

    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        try {
          await _registerDevice(token, source: 'onTokenRefresh');
        } catch (error) {
          debugPrint('Registrasi token FCM yang diperbarui gagal: $error');
        }
      },
      onError: (Object error) {
        debugPrint('Listener token FCM mengalami kesalahan: $error');
      },
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerDevice(token, source: 'getToken');
    } else {
      fcmTokenPreview.value = 'Token belum tersedia';
    }
  }

  Future<void> _registerDevice(
    String token, {
    required String source,
  }) async {
    fcmTokenPreview.value = _shortenToken(token);
    fcmTokenSource.value = source;

    await api.post<void>(
      '/devices',
      data: <String, String>{
        'token': token,
        'platform': defaultTargetPlatform.name,
      },
    );
    debugPrint('Token FCM [$source] berhasil didaftarkan ke backend.');
  }

  Future<void> _initializeLocalNotifications(
    void Function(String route) onRoute,
  ) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        // Navigation is delegated to the UI layer; this service has no
        // BuildContext and is safe to use from notification callbacks.
        onRoute(_notificationRoute(response.payload));
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
      _pendingLocalRoute = _notificationRoute(
        launchDetails?.notificationResponse?.payload,
      );
    }
  }

  Future<void> _listenForMessages(
    void Function(String route) onRoute,
  ) async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) async {
        try {
          final route = _notificationRoute(message.data['route']?.toString());
          const androidDetails = AndroidNotificationDetails(
            'pengumuman',
            'Pengumuman Kampus',
            channelDescription: 'Notifikasi pengumuman kampus',
            importance: Importance.high,
            priority: Priority.high,
          );
          const iosDetails = DarwinNotificationDetails();

          await _local.show(
            id: message.hashCode & 0x7fffffff,
            title: message.notification?.title ?? 'Pengumuman',
            body: message.notification?.body ?? '',
            notificationDetails: const NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            ),
            payload: route,
          );
        } catch (error) {
          debugPrint('Gagal menampilkan notifikasi lokal: $error');
        }
      },
    );

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onRoute(_notificationRoute(message.data['route']?.toString())),
    );
  }

  Future<void> _handleTerminatedMessage(
    void Function(String route) onRoute,
  ) async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onRoute(_notificationRoute(initial.data['route']?.toString()));
    } else if (_pendingLocalRoute != null) {
      onRoute(_pendingLocalRoute!);
    }
    _pendingLocalRoute = null;
  }

  Future<void> subscribePengumuman() async {
    await _messaging.subscribeToTopic(_campusTopic);
    fcmTopicStatus.value = 'Berlangganan $_campusTopic';
  }

  Future<void> unsubscribePengumuman() async {
    await _messaging.unsubscribeFromTopic(_campusTopic);
    fcmTopicStatus.value = 'Tidak berlangganan $_campusTopic';
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
  }

  String _shortenToken(String token) {
    final length = token.length < 12 ? token.length : 12;
    return '${token.substring(0, length)}...';
  }

  String _notificationRoute(String? route) {
    if (route == '/') return '/';
    if (route != null && RegExp(r'^/pengumuman/[0-9]+$').hasMatch(route)) {
      return route;
    }
    return '/';
  }
}
