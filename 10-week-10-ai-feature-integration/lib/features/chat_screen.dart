import 'package:go_router/go_router.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isStreaming = false;
  String? _streamingBuffer;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatus();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKeyStatus() async {
    final aiService = ref.read(aiServiceProvider);
    final key = await aiService.getApiKey();
    if ((key == null || key.isEmpty) && mounted) {
      _showApiKeyDialog(isMandatory: false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _detectSensitiveData(String input) {
    final nikRegex = RegExp(r'\b\d{16}\b');
    final phoneRegex = RegExp(r'\b(\+?62|0)8[1-9][0-9]{7,10}\b');
    return nikRegex.hasMatch(input) || phoneRegex.hasMatch(input);
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading || _isStreaming) return;

    if (_detectSensitiveData(text)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Peringatan Privasi'),
            ],
          ),
          content: const Text(
            'Pesan Anda terdeteksi mengandung nomor NIK atau nomor telepon sensitif.\n\n'
            'Sesuai panduan keamanan, jangan mengirim data pribadi rahasia ke cloud AI API.\n\n'
            'Apakah Anda tetap ingin mengirim pesan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal & Edit'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Tetap Kirim'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _isStreaming = true;
      _streamingBuffer = '';
    });
    _scrollToBottom();

    final aiService = ref.read(aiServiceProvider);

    try {
      final stream = aiService.askStream(text);
      _streamSubscription = stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _streamingBuffer = (_streamingBuffer ?? '') + chunk;
          });
          _scrollToBottom();
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isStreaming = false;
            final errorText = error.toString().replaceFirst('Exception: ', '');
            _messages.add(
              ChatMessage(
                text: 'Gagal mendapatkan respon AI: $errorText',
                isUser: false,
                timestamp: DateTime.now(),
                isError: true,
              ),
            );
            _streamingBuffer = null;
          });
          _scrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isStreaming = false;
            if (_streamingBuffer != null && _streamingBuffer!.isNotEmpty) {
              _messages.add(
                ChatMessage(
                  text: _streamingBuffer!,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            }
            _streamingBuffer = null;
          });
          _scrollToBottom();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        final errorText = e.toString().replaceFirst('Exception: ', '');
        _messages.add(
          ChatMessage(
            text: 'Terjadi kesalahan: $errorText',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _streamingBuffer = null;
      });
      _scrollToBottom();
    }
  }

  Future<void> _showApiKeyDialog({bool isMandatory = false}) async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Pengaturan API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci ini disimpan secara aman menggunakan Flutter Secure Storage.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await aiService.removeApiKey();
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key telah dihapus.')),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await aiService.saveApiKey(newKey);
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API Key berhasil disimpan dengan aman.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant Chat'),
        actions: [
          IconButton(
            tooltip: 'AI Tools (OCR, STT, Vision)',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => context.push('/ai-tools'),
          ),
          IconButton(
            tooltip: 'Pengaturan API Key',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _showApiKeyDialog(),
          ),
          IconButton(
            tooltip: 'Bersihkan Percakapan',
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty
                ? null
                : () {
                    setState(() {
                      _messages.clear();
                      _streamingBuffer = null;
                    });
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSecurityBanner(),
          Expanded(
            child: _messages.isEmpty && !_isStreaming && !_isLoading
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.withAlpha(30),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Privasi: Jangan mengirim data sensitif (NIK, nomor telepon, alamat rahasia) ke AI.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mulai Percakapan dengan AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajukan pertanyaan seputar catatan Anda, ringkasan teks, ide, atau informasi umum dengan streaming response realtime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final displayCount =
        _messages.length + ((_isStreaming || _isLoading) ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          final message = _messages[index];
          return _buildChatBubble(message);
        }

        return _buildStreamingBubble();
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: message.isError
              ? theme.colorScheme.errorContainer
              : isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isError
                    ? theme.colorScheme.onErrorContainer
                    : isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble() {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading &&
                (_streamingBuffer == null || _streamingBuffer!.isEmpty))
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI sedang berpikir...',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              )
            else
              Text(
                _streamingBuffer ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isBusy = _isLoading || _isStreaming;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                enabled: !isBusy,
                decoration: const InputDecoration(
                  hintText: 'Tanyakan sesuatu kepada AI...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              onPressed: isBusy ? null : _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
