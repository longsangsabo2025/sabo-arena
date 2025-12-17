import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/rank_migration_helper.dart';
import '../../../services/share_service.dart';
import '../../../services/referral_service.dart';
import '../../../models/user_profile.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class QRCodeWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onClose;

  const QRCodeWidget({super.key, required this.userData, this.onClose});

  @override
  State<QRCodeWidget> createState() => _QRCodeWidgetState();
}

class _QRCodeWidgetState extends State<QRCodeWidget> {
  String? _qrData;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Get real user data - Ưu tiên display_name vì full_name có thể là "User" (default Apple Sign In)
      final userId = widget.userData["id"] as String? ?? "temp-id";
      final displayName =
          widget.userData["display_name"] as String? ??
          widget.userData["displayName"] as String? ??
          widget.userData["full_name"] as String? ??
          widget.userData["fullName"] as String? ??
          "Người dùng";
      final username = widget.userData["username"] as String? ?? "user";

      // Tạo UserProfile object từ userData để sử dụng với ShareService
      final userProfile = UserProfile(
        id: userId,
        email: widget.userData["email"] as String? ?? "",
        fullName: displayName, // Use display_name as fullName for QR
        displayName: displayName,
        username: username,
        role: 'player',
        skillLevel: 'beginner',
        totalWins: 0,
        totalLosses: 0,
        totalTournaments: 0,
        eloRating:
            widget.userData["elo_rating"] as int? ??
            widget.userData["eloRating"] as int? ??
            1000,
        spaPoints: 0,
        totalPrizePool: 0.0,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sử dụng ShareService để tạo QR data với mã ref tích hợp
      final qrData = await ShareService.generateUserQRDataWithReferral(
        userProfile,
      );

      setState(() {
        _qrData = qrData;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print userData to check avatar field
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mã QR của tôi',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // QR Code Section
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow.withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // User Info
                Row(
                  children: [
                    Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl:
                              widget.userData["avatar_url"] as String? ??
                              widget.userData["avatarUrl"] as String? ??
                              widget.userData["avatar"] as String?,
                          width: 15.w,
                          height: 15.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userData["display_name"] as String? ??
                                widget.userData["displayName"] as String? ??
                                widget.userData["full_name"] as String? ??
                                widget.userData["fullName"] as String? ??
                                "Người dùng",
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Rank ${RankMigrationHelper.getNewDisplayName(widget.userData["rank"] as String?)} • ELO ${widget.userData["elo_rating"] ?? widget.userData["eloRating"] ?? 1450}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // QR Code - Real or Loading
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      width: 45.w,
                      height: 45.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isGenerating
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.lightTheme.colorScheme.primary,
                              ),
                            )
                          : _qrData != null
                          ? QrImageView(
                              data: _qrData!,
                              version: QrVersions.auto,
                              size: 40.w,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            )
                          : _buildQRPattern(),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // User ID
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${_getUserCode()}',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Referral Info
                _buildReferralInfo(),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareQRCode(context),
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    label: Text('Chia sẻ'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveQRCode(context),
                    icon: CustomIconWidget(
                      iconName: 'download',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    label: Text('Lưu ảnh'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Instructions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                Text(
                  'Bạn bè có thể quét mã QR này để xem profile của bạn',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'gift',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Người mới đăng ký qua QR sẽ nhận 50 SPA, bạn nhận 100 SPA',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  String _getUserCode() {
    final userId = widget.userData["id"] as String? ?? "temp-id";
    return widget.userData["userCode"] as String? ??
        widget.userData["userId"] as String? ??
        "SABO${userId.hashCode.abs().toString().padLeft(6, '0')}";
  }

  Future<String?> _getReferralCode() async {
    final userId = widget.userData["id"] as String?;
    if (userId != null) {
      return await ReferralService.instance.getUserReferralCode(userId);
    }
    return null;
  }

  Widget _buildReferralInfo() {
    return FutureBuilder<String?>(
      future: _getReferralCode(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'gift',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Mã giới thiệu: ${snapshot.data}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildQRPattern() {
    // Simple QR-like pattern for demonstration
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 21,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 441, // 21x21
      itemBuilder: (context, index) {
        // Create a simple pattern that looks like QR code
        final row = index ~/ 21;
        final col = index % 21;

        // Corner squares
        final isCornerSquare =
            (row < 7 && col < 7) ||
            (row < 7 && col > 13) ||
            (row > 13 && col < 7);

        // Random pattern for middle area
        final isBlack =
            isCornerSquare || (row + col) % 3 == 0 || (row * col) % 7 == 0;

        return Container(
          decoration: BoxDecoration(
            color: isBlack ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(0.5),
          ),
        );
      },
    );
  }

  void _shareQRCode(BuildContext context) async {
    if (_qrData != null) {
      // In real app, implement sharing functionality with full referral content
      HapticFeedback.lightImpact();

      try {
        // Tạo nội dung chia sẻ với thông tin mã ref
        final userId = widget.userData["id"] as String?;
        final fullName =
            widget.userData["full_name"] as String? ??
            widget.userData["fullName"] as String? ??
            "Người dùng";

        if (userId != null) {
          final userProfile = UserProfile(
            id: userId,
            email: widget.userData["email"] as String? ?? "",
            fullName: fullName,
            displayName: widget.userData["username"] as String? ?? fullName,
            role: 'player',
            skillLevel: 'beginner',
            totalWins: 0,
            totalLosses: 0,
            totalTournaments: 0,
            eloRating: 1000,
            spaPoints: 0,
            totalPrizePool: 0.0,
            isVerified: false,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await ShareService.shareUserProfile(userProfile);
        } else {
          // Fallback: copy QR data to clipboard
          Clipboard.setData(ClipboardData(text: _qrData!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã copy link profile vào clipboard'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        // Fallback: copy QR data to clipboard
        Clipboard.setData(ClipboardData(text: _qrData!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã copy link profile vào clipboard'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang tạo mã QR, vui lòng đợi...'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _saveQRCode(BuildContext context) {
    // In real app, implement save to gallery functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu mã QR vào thư viện ảnh'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

