import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  AiService({FlutterSecureStorage? storage, http.Client? client, String? apiUrl})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client(),
      _apiUrl =
          apiUrl ??
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

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
      final body = await streamedResponse.stream.bytesToString();
      throw Exception(
        'Gagal memanggil AI API: ${streamedResponse.statusCode} - $body',
      );
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
