import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_screen.dart';
import '../pages/notes_page.dart';

class MultimodalScreen extends ConsumerStatefulWidget {
  const MultimodalScreen({super.key});

  @override
  ConsumerState<MultimodalScreen> createState() => _MultimodalScreenState();
}

class _MultimodalScreenState extends ConsumerState<MultimodalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  Uint8List? _ocrImageBytes;
  String? _ocrImageName;
  String? _ocrResult;
  bool _isOcrLoading = false;

  Uint8List? _visionImageBytes;
  String? _visionImageName;
  final TextEditingController _visionPromptController = TextEditingController(
    text: 'Analisis dan jelaskan isi gambar ini secara detail.',
  );
  String? _visionResult;
  bool _isVisionLoading = false;

  Uint8List? _audioBytes;
  String? _audioName;
  String? _sttResult;
  bool _isSttLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _visionPromptController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForOcr(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _ocrImageBytes = bytes;
          _ocrImageName = picked.name;
          _ocrResult = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar: $e');
    }
  }

  void _loadSampleDocumentForOcr() {
    final sampleBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    setState(() {
      _ocrImageBytes = sampleBytes;
      _ocrImageName = 'sample_ktm_receipt.png';
      _ocrResult = null;
    });
    _showSnackBar('Sampel dokumen dimuat.');
  }

  Future<void> _runOcr() async {
    if (_ocrImageBytes == null) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu.');
      return;
    }

    setState(() {
      _isOcrLoading = true;
      _ocrResult = null;
    });

    final aiService = ref.read(aiServiceProvider);
    try {
      final result = await aiService.recognizeText(_ocrImageBytes!);
      setState(() {
        _isOcrLoading = false;
        _ocrResult = result.trim().isEmpty
            ? 'Tidak ada teks yang terdeteksi pada gambar.'
            : result;
      });
    } catch (e) {
      setState(() {
        _isOcrLoading = false;
        _ocrResult =
            'Error OCR: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _pickImageForVision(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _visionImageBytes = bytes;
          _visionImageName = picked.name;
          _visionResult = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar: $e');
    }
  }

  void _loadSampleImageForVision() {
    final sampleBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    setState(() {
      _visionImageBytes = sampleBytes;
      _visionImageName = 'sample_product.png';
      _visionResult = null;
    });
    _showSnackBar('Sampel produk dimuat.');
  }

  Future<void> _runVision() async {
    if (_visionImageBytes == null) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu.');
      return;
    }

    setState(() {
      _isVisionLoading = true;
      _visionResult = null;
    });

    final aiService = ref.read(aiServiceProvider);
    try {
      final prompt = _visionPromptController.text.trim();
      final result = await aiService.describeImage(
        _visionImageBytes!,
        prompt: prompt.isEmpty ? null : prompt,
      );
      setState(() {
        _isVisionLoading = false;
        _visionResult = result.trim().isEmpty
            ? 'Tidak ada deskripsi yang dihasilkan.'
            : result;
      });
    } catch (e) {
      setState(() {
        _isVisionLoading = false;
        _visionResult =
            'Error Deskripsi Gambar: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  void _loadSampleAudioForStt() {
    final sampleBytes = utf8.encode('RIFF....WAVEfmt ....data....');
    setState(() {
      _audioBytes = Uint8List.fromList(sampleBytes);
      _audioName = 'sample_catatan_suara.wav';
      _sttResult = null;
    });
    _showSnackBar('Sampel rekaman suara dimuat.');
  }

  Future<void> _runStt() async {
    if (_audioBytes == null) {
      _showSnackBar('Silakan pilih rekaman audio terlebih dahulu.');
      return;
    }

    setState(() {
      _isSttLoading = true;
      _sttResult = null;
    });

    final aiService = ref.read(aiServiceProvider);
    try {
      final result = await aiService.speechToText(
        _audioBytes!,
        mimeType: 'audio/wav',
      );
      setState(() {
        _isSttLoading = false;
        _sttResult = result.trim().isEmpty
            ? 'Tidak ada ucapan yang terdeteksi.'
            : result;
      });
    } catch (e) {
      setState(() {
        _isSttLoading = false;
        _sttResult =
            'Error Speech-to-Text: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _saveAsNote(String title, String content) async {
    if (content.trim().isEmpty) return;
    try {
      final repository = ref.read(noteRepositoryProvider);
      await repository.addNote(title: title, body: content);
      ref.invalidate(notesProvider);
      _showSnackBar('Berhasil disimpan ke catatan lokal!');
    } catch (e) {
      _showSnackBar('Gagal menyimpan catatan: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Multimodal Tools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner), text: 'OCR Teks'),
            Tab(icon: Icon(Icons.image_search), text: 'Vision'),
            Tab(icon: Icon(Icons.mic), text: 'Speech-to-Text'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOcrTab(), _buildVisionTab(), _buildSttTab()],
      ),
    );
  }

  Widget _buildOcrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardInfo(
            title: 'OCR (Optical Character Recognition)',
            description: 'Ekstrak teks otomatis dari foto KTM, kwitansi, receipt, dokumen penting, atau papan pengumuman menggunakan AI Vision.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  onPressed: () => _pickImageForOcr(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  onPressed: () => _pickImageForOcr(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Muat Sampel Dokumen',
                icon: const Icon(Icons.file_present),
                onPressed: _loadSampleDocumentForOcr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ocrImageBytes != null) ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _ocrImageBytes!,
                  fit: BoxFit.contain,
                  cacheWidth: 400,
                  cacheHeight: 400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'File: ${_ocrImageName ?? 'Dokumen terpilih'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _isOcrLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.text_fields),
              label: Text(
                _isOcrLoading
                    ? 'Mengekstrak Teks...'
                    : 'Ekstrak Teks dengan AI',
              ),
              onPressed: _isOcrLoading ? null : _runOcr,
            ),
          ] else
            _buildPlaceholder(
              icon: Icons.receipt_long_outlined,
              label: 'Pilih foto dokumen/receipt untuk memulai ekstraksi OCR',
            ),
          if (_ocrResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'Hasil Ekstraksi OCR',
              content: _ocrResult!,
              onSave: () => _saveAsNote(
                'OCR: ${_ocrImageName ?? 'Dokumen'}',
                _ocrResult!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardInfo(
            title: 'Image Understanding & Vision',
            description: 'Analisis gambar untuk deskripsi produk, identifikasi objek, ekstraksi konteks, atau fitur aksesibilitas tuna netra.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  onPressed: () => _pickImageForVision(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  onPressed: () => _pickImageForVision(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Muat Sampel Produk',
                icon: const Icon(Icons.image_outlined),
                onPressed: _loadSampleImageForVision,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_visionImageBytes != null) ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _visionImageBytes!,
                  fit: BoxFit.contain,
                  cacheWidth: 400,
                  cacheHeight: 400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _visionPromptController,
              decoration: const InputDecoration(
                labelText: 'Instruksi Analisis (Prompt)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _isVisionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isVisionLoading
                    ? 'Menganalisis...'
                    : 'Analisis Gambar dengan AI',
              ),
              onPressed: _isVisionLoading ? null : _runVision,
            ),
          ] else
            _buildPlaceholder(
              icon: Icons.image_search_outlined,
              label: 'Pilih foto objek untuk dianalisis oleh AI',
            ),
          if (_visionResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'Hasil Analisis Gambar',
              content: _visionResult!,
              onSave: () => _saveAsNote(
                'Deskripsi: ${_visionImageName ?? 'Objek'}',
                _visionResult!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSttTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardInfo(
            title: 'Speech-to-Text (STT)',
            description: 'Konversi rekaman suara menjadi teks tertulis untuk input cepat saat membuat catatan atau mendukung aksesibilitas pengguna.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Sampel Suara'),
                  onPressed: _loadSampleAudioForStt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_audioBytes != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.blueAccent),
                title: Text(_audioName ?? 'Audio Rekaman'),
                subtitle: Text(
                  '${_audioBytes!.lengthInBytes} bytes data audio',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _isSttLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.transcribe),
              label: Text(
                _isSttLoading ? 'Mentranskripsi...' : 'Konversi ke Teks',
              ),
              onPressed: _isSttLoading ? null : _runStt,
            ),
          ] else
            _buildPlaceholder(
              icon: Icons.mic_none_outlined,
              label: 'Pilih sampel rekaman suara untuk ditranskripsi ke teks',
            ),
          if (_sttResult != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'Hasil Transkripsi Suara',
              content: _sttResult!,
              onSave: () => _saveAsNote(
                'Catatan Suara (${DateTime.now().toLocal().toString().substring(0, 16)})',
                _sttResult!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfo({required String title, required String description}) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String content,
    required VoidCallback onSave,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SelectableText(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Salin'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    _showSnackBar('Teks disalin ke clipboard.');
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.note_add, size: 16),
                  label: const Text('Simpan ke Catatan'),
                  onPressed: onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
