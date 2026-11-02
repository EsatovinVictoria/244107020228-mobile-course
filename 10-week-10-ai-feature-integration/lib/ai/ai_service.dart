import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  static const String defaultApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent';

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client(),
       _apiUrl = _resolveApiUrl(apiUrl);

  static String _resolveApiUrl(String? url) {
    if (url == null || url.isEmpty || url.contains('gemini-pro:')) {
      return defaultApiUrl;
    }
    return url;
  }

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  Stream<String> askStream(String question) async* {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final streamUrl = _apiUrl.contains('generateContent')
        ? _apiUrl.replaceFirst('generateContent', 'streamGenerateContent')
        : _apiUrl;

    final request = http.Request(
      'POST',
      Uri.parse('$streamUrl?alt=sse&key=$apiKey'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': question},
          ],
        },
      ],
    });

    final streamedResponse = await _client.send(request);
    if (streamedResponse.statusCode != 200) {
      try {
        final fallbackText = await ask(question);
        yield fallbackText;
        return;
      } catch (_) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(
          'Gagal memanggil AI API: ${streamedResponse.statusCode} - $body',
        );
      }
    }

    String buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
          try {
            final data = jsonDecode(jsonStr);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          } catch (_) {
            // Ignore incomplete JSON chunks during streaming
          }
        }
      }
    }

    if (buffer.trim().startsWith('data: ')) {
      final jsonStr = buffer.trim().substring(6).trim();
      try {
        final data = jsonDecode(jsonStr);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<String> recognizeText(dynamic imageFile, {String? mimeType}) async {
    final bytes = await _extractBytes(imageFile);
    final resolvedMime = mimeType ?? _detectImageMime(imageFile);
    return _generateMultimodalContent(
      prompt:
          'Ekstrak seluruh teks yang terbaca pada gambar ini secara akurat. '
          'Kembalikan hanya teks yang ditemukan tanpa penjelasan tambahan.',
      bytes: bytes,
      mimeType: resolvedMime,
    );
  }

  Future<String> describeImage(
    dynamic imageFile, {
    String? prompt,
    String? mimeType,
  }) async {
    final bytes = await _extractBytes(imageFile);
    final resolvedMime = mimeType ?? _detectImageMime(imageFile);
    final effectivePrompt =
        prompt ??
        'Analisis dan jelaskan isi gambar ini secara detail dan jelas untuk tujuan deskripsi konten dan aksesibilitas.';
    return _generateMultimodalContent(
      prompt: effectivePrompt,
      bytes: bytes,
      mimeType: resolvedMime,
    );
  }

  Future<String> speechToText(dynamic audioFile, {String? mimeType}) async {
    final bytes = await _extractBytes(audioFile);
    final resolvedMime = mimeType ?? _detectAudioMime(audioFile);
    return _generateMultimodalContent(
      prompt: 'Transkripsikan isi rekaman suara ini ke dalam teks secara akurat dalam Bahasa Indonesia.',
      bytes: bytes,
      mimeType: resolvedMime,
    );
  }

  Future<String> _generateMultimodalContent({
    required String prompt,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final base64Data = base64Encode(bytes);
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {'mimeType': mimeType, 'data': base64Data},
            },
          ],
        },
      ],
    };

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }
      return '';
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  Future<Uint8List> _extractBytes(dynamic file) async {
    if (file is Uint8List) {
      return file;
    } else if (file is List<int>) {
      return Uint8List.fromList(file);
    } else if (file is XFile) {
      return await file.readAsBytes();
    } else if (file is File) {
      return await file.readAsBytes();
    } else if (file is String) {
      return await File(file).readAsBytes();
    }
    throw ArgumentError('Format file tidak didukung: ${file.runtimeType}');
  }

  String _detectImageMime(dynamic file) {
    String path = '';
    if (file is XFile) path = file.path;
    if (file is File) path = file.path;
    if (file is String) path = file;

    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  String _detectAudioMime(dynamic file) {
    String path = '';
    if (file is XFile) path = file.path;
    if (file is File) path = file.path;
    if (file is String) path = file;

    final lower = path.toLowerCase();
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a')) return 'audio/m4a';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mp3';
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: 'ai_api_key');
  }

  Future<void> removeApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }
}
