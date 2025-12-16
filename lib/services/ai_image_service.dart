import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// AI Image Generation Service using Kie.ai API
/// Used for creating tournament posters, player avatars, event banners
class AiImageService {
  static const String _imgbbApiKey = '2c3d34ab82d9b3b679cc9303087a7769';
  static const String _kieApiKey = 'eb957901436a99006ef620bd3a532c82';
  static const String _kieApiUrl = 'https://api.kie.ai/api/v1/jobs';

  /// Upload image to imgbb and get URL
  static Future<String> uploadToImgbb(Uint8List imageBytes, String fileName) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    
    // Use base64 encoding for simpler upload
    final base64Image = base64Encode(imageBytes);
    
    final response = await http.post(uri, body: {
      'image': base64Image,
      'name': fileName,
    });
    
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['data']['url'] as String;
  }

  /// Upload File to imgbb
  static Future<String> uploadFileToImgbb(File file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    return uploadToImgbb(bytes, fileName);
  }

  /// Create AI image generation task
  static Future<String> createImageTask({
    required String imageUrl,
    required String prompt,
    String aspectRatio = '1:1',
    String resolution = '4K',
  }) async {
    final response = await http.post(
      Uri.parse('$_kieApiUrl/createTask'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_kieApiKey',
      },
      body: json.encode({
        'model': 'nano-banana-pro',
        'input': {
          'prompt': prompt,
          'aspect_ratio': aspectRatio,
          'resolution': resolution,
          'output_format': 'png',
          'image_input': [imageUrl],
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create task: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['data']['taskId'] as String;
  }

  /// Check task status and get result
  static Future<AiImageResult> checkTaskStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$_kieApiUrl/recordInfo?taskId=$taskId'),
      headers: {
        'Authorization': 'Bearer $_kieApiKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to check status: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final state = data['data']['state'] as String;

    if (state == 'success') {
      final resultJson = json.decode(data['data']['resultJson']);
      final urls = (resultJson['resultUrls'] as List).cast<String>();
      return AiImageResult(
        taskId: taskId,
        state: AiImageState.success,
        imageUrl: urls.isNotEmpty ? urls.first : null,
      );
    } else if (state == 'fail') {
      return AiImageResult(
        taskId: taskId,
        state: AiImageState.fail,
        error: 'Image generation failed',
      );
    } else {
      return AiImageResult(
        taskId: taskId,
        state: AiImageState.generating,
      );
    }
  }

  /// Generate image with polling (convenience method)
  static Future<AiImageResult> generateImage({
    required Uint8List imageBytes,
    required String prompt,
    String aspectRatio = '1:1',
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 5),
    Function(String)? onProgress,
  }) async {
    // Step 1: Upload to imgbb
    onProgress?.call('Uploading image...');
    final imageUrl = await uploadToImgbb(imageBytes, 'input_${DateTime.now().millisecondsSinceEpoch}.png');

    // Step 2: Create task
    onProgress?.call('Creating AI task...');
    final taskId = await createImageTask(
      imageUrl: imageUrl,
      prompt: prompt,
      aspectRatio: aspectRatio,
    );

    // Step 3: Poll for result
    final startTime = DateTime.now();
    int attempts = 0;

    while (DateTime.now().difference(startTime) < timeout) {
      attempts++;
      onProgress?.call('Processing... (${attempts * 5}s)');
      
      await Future.delayed(pollInterval);
      
      final result = await checkTaskStatus(taskId);
      
      if (result.state != AiImageState.generating) {
        return result;
      }
    }

    return AiImageResult(
      taskId: taskId,
      state: AiImageState.fail,
      error: 'Timeout - generation took too long',
    );
  }

  /// Generate image from File
  static Future<AiImageResult> generateImageFromFile({
    required File file,
    required String prompt,
    String aspectRatio = '1:1',
    Function(String)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return generateImage(
      imageBytes: bytes,
      prompt: prompt,
      aspectRatio: aspectRatio,
      onProgress: onProgress,
    );
  }
}

/// AI Image generation state
enum AiImageState { generating, success, fail }

/// AI Image generation result
class AiImageResult {
  final String taskId;
  final AiImageState state;
  final String? imageUrl;
  final String? error;

  AiImageResult({
    required this.taskId,
    required this.state,
    this.imageUrl,
    this.error,
  });

  bool get isSuccess => state == AiImageState.success;
  bool get isFail => state == AiImageState.fail;
  bool get isGenerating => state == AiImageState.generating;
}
