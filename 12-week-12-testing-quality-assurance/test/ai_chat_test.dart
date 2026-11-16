import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week5_offline_notes/ai/ai_service.dart';
import 'package:week5_offline_notes/features/chat_screen.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  FakeSecureStorage([Map<String, String>? initial]) {
    if (initial != null) {
      _data.addAll(initial);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('AiService Unit Tests', () {
    test('ask melempar exception ketika API key belum disimpan', () async {
      final storage = FakeSecureStorage();
      final service = AiService(storage: storage);

      expect(
        () => service.ask('Halo AI'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test('ask mengembalikan teks respon saat status code 200', () async {
      final storage = FakeSecureStorage({'ai_api_key': 'test-gemini-key'});
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'test-gemini-key');
        final body = jsonDecode(request.body);
        expect(body['contents'][0]['parts'][0]['text'], 'Jelaskan SQLite');

        final responseJson = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'SQLite adalah database embedded SQL yang ringan dan handal.',
                  },
                ],
              },
            },
          ],
        });

        return http.Response(
          responseJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(storage: storage, client: mockClient);
      final result = await service.ask('Jelaskan SQLite');

      expect(
        result,
        'SQLite adalah database embedded SQL yang ringan dan handal.',
      );
    });

    test('ask melempar exception saat server merespon selain 200', () async {
      final storage = FakeSecureStorage({'ai_api_key': 'invalid-key'});
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = AiService(storage: storage, client: mockClient);

      expect(
        () => service.ask('Tes gagal'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Gagal memanggil AI API: 401'),
          ),
        ),
      );
    });

    test(
      'saveApiKey, getApiKey, dan removeApiKey berfungsi dengan benar',
      () async {
        final storage = FakeSecureStorage();
        final service = AiService(storage: storage);

        expect(await service.getApiKey(), isNull);

        await service.saveApiKey('secret-12345');
        expect(await service.getApiKey(), 'secret-12345');

        await service.removeApiKey();
        expect(await service.getApiKey(), isNull);
      },
    );

    test(
      'askStream mem-parsing server-sent events dan menghasilkan stream teks',
      () async {
        final storage = FakeSecureStorage({'ai_api_key': 'stream-key'});
        final mockClient = MockClient.streaming((request, bodyStream) async {
          final sseData = [
            'data: {"candidates":[{"content":{"parts":[{"text":"Halo! "}]}}]}\n\n',
            'data: {"candidates":[{"content":{"parts":[{"text":"Ada yang bisa "}]}}]}\n\n',
            'data: {"candidates":[{"content":{"parts":[{"text":"saya bantu?"}]}}]}\n\n',
            'data: [DONE]\n\n',
          ];

          final stream = Stream<List<int>>.fromIterable(
            sseData.map((s) => utf8.encode(s)),
          );

          return http.StreamedResponse(
            stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        });

        final service = AiService(storage: storage, client: mockClient);
        final streamResult = await service.askStream('Halo').toList();

        expect(streamResult, ['Halo! ', 'Ada yang bisa ', 'saya bantu?']);
      },
    );
  });

  group('ChatScreen Widget Tests', () {
    testWidgets(
      'menampilkan AppBar, banner privasi keamanan, dan empty state awal',
      (tester) async {
        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final service = AiService(storage: storage);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiServiceProvider.overrideWithValue(service)],
            child: const MaterialApp(home: ChatScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('AI Assistant Chat'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(
          find.textContaining('Privasi: Jangan mengirim data sensitif'),
          findsOneWidget,
        );
        expect(find.text('Mulai Percakapan dengan AI'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Tanyakan sesuatu kepada AI...'),
          findsOneWidget,
        );
      },
    );

    testWidgets('mengirim pesan dan menampilkan respon streaming AI', (
      tester,
    ) async {
      final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final sseData = [
          'data: {"candidates":[{"content":{"parts":[{"text":"Catatan Anda "}]}}]}\n\n',
          'data: {"candidates":[{"content":{"parts":[{"text":"tersimpan aman."}]}}]}\n\n',
        ];
        return http.StreamedResponse(
          Stream.fromIterable(sseData.map(utf8.encode)),
          200,
        );
      });

      final service = AiService(storage: storage, client: mockClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiServiceProvider.overrideWithValue(service)],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Bagaimana kondisi catatan saya?',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Bagaimana kondisi catatan saya?'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Catatan Anda tersimpan aman.'), findsOneWidget);
    });

    testWidgets(
      'mendeteksi nomor sensitif (NIK 16 digit) dan memunculkan dialog peringatan privasi',
      (tester) async {
        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final service = AiService(storage: storage);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiServiceProvider.overrideWithValue(service)],
            child: const MaterialApp(home: ChatScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Halo ini nomor NIK saya 3507123456789012',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Peringatan Privasi'), findsOneWidget);
        expect(
          find.textContaining('Pesan Anda terdeteksi mengandung nomor NIK'),
          findsOneWidget,
        );

        await tester.tap(find.text('Batal & Edit'));
        await tester.pumpAndSettle();

        expect(find.text('Peringatan Privasi'), findsNothing);
        expect(find.byType(ListView), findsNothing);
      },
    );
  });
}
