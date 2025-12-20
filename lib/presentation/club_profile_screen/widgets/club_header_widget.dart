import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/common/app_button.dart';

class ClubHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> clubData;
  final bool isOwner;
  final VoidCallback onEditPressed;
  final VoidCallback onJoinTogglePressed;

  const ClubHeaderWidget({
    super.key,
    required this.clubData,
    required this.isOwner,
    required this.onEditPressed,
    required this.onJoinTogglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 28.h,
      pinned: true,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Menu button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: Colors.white,
            onPressed: () {
              // Menu actions
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            clubData["coverImage"] != null
                ? Image.network(
                    clubData["coverImage"],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.sports_bar,
                          size: 15.w,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.sports_bar,
                      size: 15.w,
                      color: Colors.grey.shade600,
                    ),
                  ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Edit cover button (only for owner)
            if (isOwner)
              Positioned(
                top: 70,
                right: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onEditPressed,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Sửa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Club Info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Club Name with Badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clubData["name"] ?? "Unknown Club",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      clubData["location"] ??
                                          "Unknown Location",
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action Button - Full width
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: isOwner
                            ? 'Chỉnh sửa CLB'
                            : (clubData["isMember"]
                                ? 'Rời khỏi CLB'
                                : 'Tham gia CLB'),
                        type: isOwner
                            ? AppButtonType.outline
                            : AppButtonType.primary,
                        size: AppButtonSize.large,
                        icon: isOwner
                            ? Icons.edit
                            : (clubData["isMember"]
                                ? Icons.exit_to_app
                                : Icons.add),
                        iconTrailing: false,
                        customColor: isOwner
                            ? Colors.white
                            : AppTheme.lightTheme.colorScheme.primary,
                        customTextColor: isOwner ? Colors.white : Colors.white,
                        onPressed:
                            isOwner ? onEditPressed : onJoinTogglePressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
