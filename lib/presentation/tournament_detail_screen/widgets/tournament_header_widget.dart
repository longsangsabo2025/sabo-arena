import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class TournamentHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback? onShareTap;
  final ScrollController scrollController;
  final Function(String)? onMenuAction;
  final bool canEditCover;
  final VoidCallback? onEditCoverTap;

  const TournamentHeaderWidget({
    super.key,
    required this.tournament,
    this.onShareTap,
    required this.scrollController,
    this.onMenuAction,
    this.canEditCover = false,
    this.onEditCoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF0F2F5),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: const Color(0xFF050505),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_horiz,
              color: Color(0xFF050505),
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18, color: Color(0xFF65676B)),
                    SizedBox(width: 12),
                    Text(
                      'Chia sẻ',
                      style: TextStyle(fontSize: 15, color: Color(0xFF050505), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              if (canEditCover) // Only show for club owners
                PopupMenuItem(
                  value: 'prize_vouchers',
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 18, color: Color(0xFF65676B)),
                      SizedBox(width: 12),
                      Text(
                        'Voucher giải thưởng',
                        style: TextStyle(fontSize: 15, color: Color(0xFF050505), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18, color: Color(0xFF65676B)),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý',
                      style: TextStyle(fontSize: 15, color: Color(0xFF050505), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: onMenuAction,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            CustomImageWidget(
              imageUrl: tournament["coverImage"] as String,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
            // Edit button (only visible for club owners)
            if (canEditCover && onEditCoverTap != null)
              Positioned(
                top: 60,
                right: 16,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: InkWell(
                    onTap: onEditCoverTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Color(0xFF0866FF),
                      ),
                    ),
                  ),
                ),
              ),
            // Tournament info at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament type badge and club info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0866FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tournament["eliminationType"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Club info
                      if (tournament["organizerClubLogo"] != null ||
                          tournament["organizerClubName"] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tournament["organizerClubLogo"] != null)
                                ClipOval(
                                  child: CustomImageWidget(
                                    imageUrl:
                                        tournament["organizerClubLogo"]
                                            as String,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sports,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                tournament["organizerClubName"] as String? ??
                                    "CLB",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tournament title
                  Text(
                    tournament["title"] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tournament["location"] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
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
      ),
    );
  }

  Color _getEliminationTypeColor(String eliminationType) {
    return const Color(0xFF0866FF); // iOS Facebook blue
  }
}
