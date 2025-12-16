import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabo_arena/utils/size_extensions.dart';

class TournamentCoverUploadWidget extends StatefulWidget {
  final String? coverImageUrl;
  final Function(Uint8List?, String?) onImageSelected;
  final bool isUploading;

  const TournamentCoverUploadWidget({
    super.key,
    this.coverImageUrl,
    required this.onImageSelected,
    this.isUploading = false,
  });

  @override
  State<TournamentCoverUploadWidget> createState() =>
      _TournamentCoverUploadWidgetState();
}

class _TournamentCoverUploadWidgetState
    extends State<TournamentCoverUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.coverImageUrl != null || _imageBytes != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Icon(Icons.image_outlined,
                  color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: 8.w),
              Text(
                'Ảnh bìa giải đấu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (hasImage)
                Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 12.h),

          // Image preview or placeholder
          GestureDetector(
            onTap: widget.isUploading ? null : _pickImage,
            child: Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasImage
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade200,
                  width: hasImage ? 2 : 1,
                ),
              ),
              child: widget.isUploading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12.h),
                          Text(
                            'Đang tải ảnh lên...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : widget.coverImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.coverImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              ),
                            )
                          : _buildPlaceholder(),
            ),
          ),

          SizedBox(height: 12.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isUploading ? null : _pickImage,
                  icon: Icon(Icons.upload_outlined, size: 18),
                  label: Text(
                    hasImage ? 'Đổi ảnh' : 'Chọn ảnh',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                SizedBox(width: 12.w),
                OutlinedButton.icon(
                  onPressed: widget.isUploading ? null : _removeImage,
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Xóa', style: TextStyle(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 8.h),

          // Helper text
          Text(
            'Khuyến nghị: 1920x1080px, định dạng JPG/PNG, tối đa 5MB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey.shade400),
          SizedBox(height: 12.h),
          Text(
            'Chạm để thêm ảnh bìa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '(Tùy chọn)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _fileName = image.name;
        });
        widget.onImageSelected(bytes, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
    });
    widget.onImageSelected(null, null);
  }
}
