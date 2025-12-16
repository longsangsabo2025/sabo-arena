import 'package:flutter/material.dart';
import '../../../models/club.dart';
import '../../../models/club_review.dart';
import '../../../services/club_review_service.dart';
import '../../../services/auth_service.dart';

/// 🌟 Club Review Dialog - Đánh giá câu lạc bộ
///
/// Features:
/// - Overall rating (1-5 stars)
/// - Detailed ratings (facility, service, atmosphere, price)
/// - Comment text
/// - User-friendly UI
class ClubReviewDialog extends StatefulWidget {
  final Club club;
  final ClubReview? existingReview; // null if new review

  const ClubReviewDialog({super.key, required this.club, this.existingReview});

  @override
  State<ClubReviewDialog> createState() => _ClubReviewDialogState();

  static Future<bool?> show(BuildContext context, Club club) async {
    // Check if user already reviewed
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return null;
    }

    final existingReview = await ClubReviewService().getUserReview(
      club.id,
      userId,
    );

    if (!context.mounted) return null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ClubReviewDialog(club: club, existingReview: existingReview),
    );

    return result;
  }
}

class _ClubReviewDialogState extends State<ClubReviewDialog> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _overallRating = 0.0;
  double? _facilityRating;
  double? _serviceRating;
  double? _atmosphereRating;
  double? _priceRating;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _overallRating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment ?? '';
      _facilityRating = widget.existingReview!.facilityRating;
      _serviceRating = widget.existingReview!.serviceRating;
      _atmosphereRating = widget.existingReview!.atmosphereRating;
      _priceRating = widget.existingReview!.priceRating;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userId = AuthService.instance.currentUser!.id;
    final success = await ClubReviewService().submitReview(
      clubId: widget.club.id,
      userId: userId,
      rating: _overallRating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      facilityRating: _facilityRating,
      serviceRating: _serviceRating,
      atmosphereRating: _atmosphereRating,
      priceRating: _priceRating,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingReview == null
                ? 'Đánh giá đã được gửi!'
                : 'Đánh giá đã được cập nhật!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingReview == null
                              ? 'Đánh giá câu lạc bộ'
                              : 'Cập nhật đánh giá',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.club.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Rating
                      Text(
                        'Đánh giá tổng thể',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _buildStarRating(
                          _overallRating,
                          (rating) => setState(() => _overallRating = rating),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Detailed Ratings (Optional)
                      ExpansionTile(
                        title: const Text('Đánh giá chi tiết (Tùy chọn)'),
                        initiallyExpanded: widget.existingReview != null,
                        children: [
                          _buildDetailedRating(
                            'Cơ sở vật chất',
                            Icons.apartment,
                            _facilityRating,
                            (rating) =>
                                setState(() => _facilityRating = rating),
                          ),
                          _buildDetailedRating(
                            'Dịch vụ',
                            Icons.room_service,
                            _serviceRating,
                            (rating) => setState(() => _serviceRating = rating),
                          ),
                          _buildDetailedRating(
                            'Không khí',
                            Icons.air,
                            _atmosphereRating,
                            (rating) =>
                                setState(() => _atmosphereRating = rating),
                          ),
                          _buildDetailedRating(
                            'Giá cả',
                            Icons.attach_money,
                            _priceRating,
                            (rating) => setState(() => _priceRating = rating),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Comment
                      Text(
                        'Nhận xét (Tùy chọn)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              'Chia sẻ trải nghiệm của bạn về câu lạc bộ...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.existingReview == null
                                  ? 'Gửi đánh giá'
                                  : 'Cập nhật',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(
    double rating,
    Function(double) onRatingChanged, {
    double size = 32,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: starValue <= rating ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDetailedRating(
    String label,
    IconData icon,
    double? rating,
    Function(double?) onRatingChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStarRating(
                  rating ?? 0.0,
                  (r) => onRatingChanged(r),
                  size: 24,
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: rating != null
                      ? () => onRatingChanged(null)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
