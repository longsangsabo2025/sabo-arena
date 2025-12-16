import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/services/share_service.dart';
import 'package:sabo_arena/services/referral_service.dart';
import 'package:sabo_arena/models/user_profile.dart';

/// Widget hiển thị QR code với mã ref tích hợp
class UserQRCodeWidget extends StatefulWidget {
  final UserProfile user;
  final double size;
  final bool showShareButton;

  const UserQRCodeWidget({
    super.key,
    required this.user,
    this.size = 200.0,
    this.showShareButton = true,
  });

  @override
  State<UserQRCodeWidget> createState() => _UserQRCodeWidgetState();
}

class _UserQRCodeWidgetState extends State<UserQRCodeWidget> {
  String? _qrData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  Future<void> _generateQRData() async {
    try {
      setState(() => _isLoading = true);

      // Tạo QR data với mã ref tích hợp
      _qrData = await ShareService.generateUserQRDataWithReferral(widget.user);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // Fallback về QR data thông thường nếu có lỗi
      _qrData = ShareService.generateUserQRData(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                'Mã QR của ${widget.user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thông tin user
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Mã định danh: ${ShareService.generateUserCode(widget.user.id)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quét mã này để kết nối hoặc mời bạn bè',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QR Code
          _isLoading
              ? Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: widget.size,
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),

          const SizedBox(height: 16),

          // Thông tin mã ref (ẩn/hiện)
          FutureBuilder<String?>(
            future: ReferralService.instance.getUserReferralCode(
              widget.user.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Có mã ref tích hợp',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          if (widget.showShareButton) ...[
            const SizedBox(height: 16),

            // Nút chia sẻ
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _qrData == null
                        ? null
                        : () => _shareQRCode(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ mã QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareQRCode(BuildContext context) async {
    if (_qrData == null) return;

    final referralCode = await ReferralService.instance.getUserReferralCode(
      widget.user.id,
    );

    final shareText =
        '''
🏆 Kết nối với ${widget.user.fullName} trên SABO ARENA!

👤 ${widget.user.fullName}
${widget.user.rank != null ? '🎯 Rank: ${widget.user.rank}\n' : ''}⚡ ELO: ${widget.user.eloRating}
🏅 Thắng/Thua: ${widget.user.totalWins}/${widget.user.totalLosses}

🔗 Quét mã QR này để:
${referralCode != null ? '• Nhận điểm bonus khi đăng ký lần đầu\n' : ''}• Xem thông tin chi tiết
• Kết nối và thách đấu

📱 Tải app: https://saboarena.com/download
${referralCode != null ? '🎁 Mã giới thiệu: $referralCode\n' : ''}''';

    // ignore: use_build_context_synchronously
    await Share.share(
      shareText,
      subject: 'Kết nối với ${widget.user.fullName} trên SABO ARENA',
    );
  }
}

/// Widget hiển thị nút chia sẻ QR nhanh
class QuickQRShareButton extends StatelessWidget {
  final UserProfile user;

  const QuickQRShareButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showQRDialog(context),
      icon: const Icon(Icons.qr_code),
      tooltip: 'Hiển thị mã QR',
      iconSize: 24,
    );
  }

  Future<void> _showQRDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mã QR của ${user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: ShareService.generateUserQRDataWithReferral(user),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return QrImageView(data: snapshot.data!, size: 200);
                  }
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final qrData =
                          await ShareService.generateUserQRDataWithReferral(
                            user,
                          );
                      await Share.share(
                        'Quét mã QR này để kết nối với tôi: $qrData',
                        subject: 'Kết nối với ${user.fullName}',
                      );
                    },
                    child: const Text('Chia sẻ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
