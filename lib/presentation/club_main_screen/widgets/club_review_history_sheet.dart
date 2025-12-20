import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../../models/club.dart';
import '../../../models/club_review.dart';
import '../../../services/club_review_service.dart';

/// 📜 Club Review History Sheet - Hiển thị lịch sử đánh giá
class ClubReviewHistorySheet extends StatefulWidget {
  final Club club;

  const ClubReviewHistorySheet({super.key, required this.club});

  @override
  State<ClubReviewHistorySheet> createState() => _ClubReviewHistorySheetState();
}

class _ClubReviewHistorySheetState extends State<ClubReviewHistorySheet> {
  final _reviewService = ClubReviewService();
  List<ClubReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    final reviews = await _reviewService.getClubReviews(
      widget.club.id,
      limit: 50,
      sortBy: 'created_at',
      ascending: false,
    );

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.rate_review,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh giá từ khách hàng',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < widget.club.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.club.rating.toStringAsFixed(1)} (${widget.club.totalReviews} đánh giá)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Reviews list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 64,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có đánh giá nào',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hãy là người đầu tiên đánh giá câu lạc bộ này!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _reviews.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return _buildReviewItem(
                                  review, colorScheme, theme);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(
    ClubReview review,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Avatar
              UserAvatarWidget(
                avatarUrl: review.userAvatar,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(review.createdAt, locale: 'vi'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),

          // Detail ratings (if available)
          if (review.facilityRating != null ||
              review.serviceRating != null ||
              review.atmosphereRating != null ||
              review.priceRating != null)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (review.facilityRating != null)
                    _buildDetailRating(
                      'Cơ sở',
                      review.facilityRating!,
                      colorScheme,
                    ),
                  if (review.serviceRating != null)
                    _buildDetailRating(
                      'Dịch vụ',
                      review.serviceRating!,
                      colorScheme,
                    ),
                  if (review.atmosphereRating != null)
                    _buildDetailRating(
                      'Không khí',
                      review.atmosphereRating!,
                      colorScheme,
                    ),
                  if (review.priceRating != null)
                    _buildDetailRating(
                      'Giá cả',
                      review.priceRating!,
                      colorScheme,
                    ),
                ],
              ),
            ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 12),
              child: Text(review.comment!, style: theme.textTheme.bodyMedium),
            ),

          // Images (if available)
          if (review.imageUrls != null && review.imageUrls!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 12),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.imageUrls![index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRating(
    String label,
    double rating,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
