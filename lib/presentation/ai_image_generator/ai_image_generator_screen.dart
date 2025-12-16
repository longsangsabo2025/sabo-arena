import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ai_image_service.dart';

/// AI Image Generator Screen for SABO Arena
/// Create tournament posters, player avatars, event banners with AI
class AiImageGeneratorScreen extends StatefulWidget {
  final String? initialPrompt;
  final String? presetType; // 'poster', 'avatar', 'banner'

  const AiImageGeneratorScreen({
    super.key,
    this.initialPrompt,
    this.presetType,
  });

  @override
  State<AiImageGeneratorScreen> createState() => _AiImageGeneratorScreenState();
}

class _AiImageGeneratorScreenState extends State<AiImageGeneratorScreen> {
  final _promptController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isGenerating = false;
  String _progress = '';
  AiImageResult? _result;
  String _selectedAspectRatio = '1:1';
  
  // Preset prompts for SABO Arena
  final Map<String, List<String>> _presetPrompts = {
    'poster': [
      'Professional billiards tournament poster, neon lights, dramatic lighting',
      'Esports gaming event poster, futuristic style, vibrant colors',
      'Championship poster with trophy, gold and black theme',
    ],
    'avatar': [
      'Professional gamer portrait, cyberpunk style, neon glow',
      'Billiards player avatar, cool lighting, sports vibe',
      'Esports pro player style, dynamic pose, gaming aesthetic',
    ],
    'banner': [
      'Wide billiards table banner, cinematic lighting, premium feel',
      'Gaming arena banner, LED lights, crowd in background',
      'Tournament announcement banner, bold text space, exciting atmosphere',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      _promptController.text = widget.initialPrompt!;
    }
    
    // Set aspect ratio based on preset type
    if (widget.presetType == 'banner') {
      _selectedAspectRatio = '16:9';
    } else if (widget.presetType == 'avatar') {
      _selectedAspectRatio = '1:1';
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
        _result = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
        _result = null;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_selectedImageBytes == null) {
      _showError('Vui lòng chọn ảnh!');
      return;
    }
    
    if (_promptController.text.trim().isEmpty) {
      _showError('Vui lòng nhập mô tả!');
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 'Đang chuẩn bị...';
      _result = null;
    });

    try {
      final result = await AiImageService.generateImage(
        imageBytes: _selectedImageBytes!,
        prompt: _promptController.text.trim(),
        aspectRatio: _selectedAspectRatio,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      setState(() {
        _result = result;
        _isGenerating = false;
      });

      if (result.isSuccess) {
        _showSuccess('🎉 Tạo ảnh thành công!');
      } else {
        _showError(result.error ?? 'Tạo ảnh thất bại');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError('Lỗi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _shareResult() async {
    if (_result?.imageUrl == null) return;
    await Share.share(_result!.imageUrl!, subject: 'SABO Arena - AI Generated Image');
  }

  Future<void> _openInBrowser() async {
    if (_result?.imageUrl == null) return;
    final uri = Uri.parse(_result!.imageUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _applyPreset(String prompt) {
    _promptController.text = prompt;
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _result = null;
      _promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 AI Image Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection
            _buildImageSection(),
            const SizedBox(height: 16),
            
            // Prompt Input
            _buildPromptSection(),
            const SizedBox(height: 16),
            
            // Aspect Ratio Selection
            _buildAspectRatioSection(),
            const SizedBox(height: 16),
            
            // Generate Button
            _buildGenerateButton(),
            const SizedBox(height: 24),
            
            // Result Section
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📷 Ảnh gốc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                      }),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thư viện'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    final presets = _presetPrompts[widget.presetType] ?? _presetPrompts['poster']!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✨ Mô tả phong cách',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Professional billiards tournament poster, neon lights...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            const Text('Gợi ý:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) => ActionChip(
                label: Text(
                  preset.length > 40 ? '${preset.substring(0, 40)}...' : preset,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _applyPreset(preset),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectRatioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📐 Tỷ lệ khung hình',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '1:1', label: Text('1:1'), icon: Icon(Icons.crop_square)),
                ButtonSegment(value: '16:9', label: Text('16:9'), icon: Icon(Icons.crop_16_9)),
                ButtonSegment(value: '9:16', label: Text('9:16'), icon: Icon(Icons.crop_portrait)),
              ],
              selected: {_selectedAspectRatio},
              onSelectionChanged: (selected) {
                setState(() => _selectedAspectRatio = selected.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isGenerating || _selectedImageBytes == null
            ? null
            : _generateImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_progress),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Text('Tạo ảnh với AI', style: TextStyle(fontSize: 18)),
                ],
              ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_result == null && !_isGenerating) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🖼️ Kết quả',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (_result?.isSuccess == true && _result?.imageUrl != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _result!.imageUrl!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openInBrowser,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Mở ảnh'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareResult,
                          icon: const Icon(Icons.share),
                          label: const Text('Chia sẻ'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (_result?.isFail == true)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _result?.error ?? 'Tạo ảnh thất bại',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_isGenerating)
              Container(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_progress, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
