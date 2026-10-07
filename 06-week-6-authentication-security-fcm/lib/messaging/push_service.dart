import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';


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

    // Hanya mencetak potongan token.
    debugPrint('FCM [$source]: ${fcmTokenPreview.value}');

    await onToken(token);
  }

  // Pantau perubahan token.
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

  // Ambil token perangkat saat ini.
  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await handleToken(token, 'getToken');
  } else {
    fcmTokenPreview.value = 'Token belum tersedia';
  }

  // Langganan topik sesuai modul.
  await FirebaseMessaging.instance.subscribeToTopic(
    'pengumuman-kampus',
  );

  fcmTopicStatus.value = 'Berlangganan pengumuman-kampus';
}

Future<void> disposeFcmToken() async {
  await _tokenSubscription?.cancel();
  _tokenSubscription = null;
}