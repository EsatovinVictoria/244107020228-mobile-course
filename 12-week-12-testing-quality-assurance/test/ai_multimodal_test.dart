import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week5_offline_notes/ai/ai_service.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/chat_screen.dart';
import 'package:week5_offline_notes/features/multimodal_screen.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

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

class FakeNoteRepository extends NoteRepository {
  final List<Note> storedNotes = [];

  @override
  Future<List<Note>> fetchNotes() async {
    return List.unmodifiable(storedNotes);
  }

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      id: storedNotes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    storedNotes.add(note);
    return note;
  }
}

void main() {
  group('AiService Multimodal Unit Tests', () {
    test('recognizeText mengirim payload inlineData gambar dan mengembalikan teks OCR', () async {
      final storage = FakeSecureStorage({'ai_api_key': 'valid-ocr-key'});
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        final parts = body['contents'][0]['parts'] as List;

        expect(parts[0]['text'], contains('Ekstrak seluruh teks'));
        expect(parts[1]['inlineData']['mimeType'], 'image/jpeg');
        expect(parts[1]['inlineData']['data'], base64Encode(sampleBytes));

        final responseJson = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'NAMA: POLITEKNIK NEGERI MALANG\nNIM: 244107020228\nJURUSAN: TEKNOLOGI INFORMASI',
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
      final result = await service.recognizeText(sampleBytes);

      expect(result, contains('POLITEKNIK NEGERI MALANG'));
      expect(result, contains('244107020228'));
    });

    test(
      'describeImage mengirim payload gambar dengan custom prompt',
      () async {
        final storage = FakeSecureStorage({'ai_api_key': 'valid-vision-key'});
        final sampleBytes = Uint8List.fromList([10, 20, 30]);

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body);
          final parts = body['contents'][0]['parts'] as List;

          expect(parts[0]['text'], 'Identifikasi warna utama pada produk');
          expect(parts[1]['inlineData']['mimeType'], 'image/png');

          final responseJson = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Produk berwarna biru tua dengan aksen perak.'},
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
        final result = await service.describeImage(
          sampleBytes,
          prompt: 'Identifikasi warna utama pada produk',
          mimeType: 'image/png',
        );

        expect(result, 'Produk berwarna biru tua dengan aksen perak.');
      },
    );

    test(
      'speechToText mengirim payload audio dan mengembalikan transkripsi',
      () async {
        final storage = FakeSecureStorage({'ai_api_key': 'valid-stt-key'});
        final audioBytes = Uint8List.fromList([100, 101, 102]);

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body);
          final parts = body['contents'][0]['parts'] as List;

          expect(
            parts[0]['text'],
            contains('Transkripsikan isi rekaman suara'),
          );
          expect(parts[1]['inlineData']['mimeType'], 'audio/wav');
          expect(parts[1]['inlineData']['data'], base64Encode(audioBytes));

          final responseJson = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Beli susu dua kotak dan roti gandum di supermarket.',
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
        final result = await service.speechToText(
          audioBytes,
          mimeType: 'audio/wav',
        );

        expect(result, 'Beli susu dua kotak dan roti gandum di supermarket.');
      },
    );
  });

  group('MultimodalScreen Widget Tests', () {
    testWidgets(
      'menampilkan TabBar 3 fitur: OCR Teks, Vision, Speech-to-Text',
      (tester) async {
        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final service = AiService(storage: storage);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiServiceProvider.overrideWithValue(service)],
            child: const MaterialApp(home: MultimodalScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('AI Multimodal Tools'), findsOneWidget);
        expect(find.text('OCR Teks'), findsOneWidget);
        expect(find.text('Vision'), findsOneWidget);
        expect(find.text('Speech-to-Text'), findsOneWidget);
        expect(
          find.text('OCR (Optical Character Recognition)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'beralih ke tab Vision dan menampilkan prompt instruksi analisis',
      (tester) async {
        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final service = AiService(storage: storage);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [aiServiceProvider.overrideWithValue(service)],
            child: const MaterialApp(home: MultimodalScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Vision'));
        await tester.pumpAndSettle();

        expect(find.text('Image Understanding & Vision'), findsOneWidget);
        expect(
          find.text('Instruksi Analisis (Prompt)'),
          findsNothing,
        ); // no image selected yet
        expect(
          find.text('Pilih foto objek untuk dianalisis oleh AI'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'menjalankan ekstraksi OCR dan menyimpan hasil ke Catatan Lokal',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final mockClient = MockClient((request) async {
          final responseJson = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': 'STRUK BELANJA\n1. Kopi Tubruk Rp 15.000\nTotal: Rp 15.000',
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

        final fakeRepo = FakeNoteRepository();
        final service = AiService(storage: storage, client: mockClient);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aiServiceProvider.overrideWithValue(service),
              noteRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: MultimodalScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Click load sample document button
        await tester.tap(find.byIcon(Icons.file_present));
        await tester.pumpAndSettle();

        expect(find.text('Ekstrak Teks dengan AI'), findsOneWidget);

        // Run OCR
        await tester.ensureVisible(find.text('Ekstrak Teks dengan AI'));
        await tester.tap(find.text('Ekstrak Teks dengan AI'));
        await tester.pumpAndSettle();

        expect(find.text('Hasil Ekstraksi OCR'), findsOneWidget);
        expect(find.textContaining('STRUK BELANJA'), findsOneWidget);

        // Click "Simpan ke Catatan"
        await tester.ensureVisible(find.text('Simpan ke Catatan'));
        await tester.tap(find.text('Simpan ke Catatan'));
        await tester.pumpAndSettle();

        expect(fakeRepo.storedNotes.length, 1);
        expect(fakeRepo.storedNotes.first.body, contains('STRUK BELANJA'));
        expect(
          find.text('Berhasil disimpan ke catatan lokal!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'menjalankan STT pada sampel audio dan menampilkan transkripsi',
      (tester) async {
        final storage = FakeSecureStorage({'ai_api_key': 'dummy-key'});
        final mockClient = MockClient((request) async {
          final responseJson = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': 'Catatan meeting: Sprint review minggu depan jam 9 pagi.',
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

        final fakeRepo = FakeNoteRepository();
        final service = AiService(storage: storage, client: mockClient);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aiServiceProvider.overrideWithValue(service),
              noteRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: MultimodalScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to STT Tab
        await tester.tap(find.text('Speech-to-Text'));
        await tester.pumpAndSettle();

        // Click Sampel Suara
        await tester.tap(find.text('Sampel Suara'));
        await tester.pumpAndSettle();

        expect(find.text('Konversi ke Teks'), findsOneWidget);

        // Run STT
        await tester.tap(find.text('Konversi ke Teks'));
        await tester.pumpAndSettle();

        expect(find.text('Hasil Transkripsi Suara'), findsOneWidget);
        expect(
          find.textContaining('Catatan meeting: Sprint review'),
          findsOneWidget,
        );
      },
    );
  });
}
