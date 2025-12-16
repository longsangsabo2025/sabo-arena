import 'package:flutter/material.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/app_colors.dart';
import '../../services/basic_referral_service.dart';

/// Basic Referral Code Input Widget
/// Input field for entering referral codes during registration
class BasicReferralCodeInput extends StatefulWidget {
  final String userId;
  final Function(bool success, String message)? onResult;
  final bool showTitle;

  const BasicReferralCodeInput({
    super.key,
    required this.userId,
    this.onResult,
    this.showTitle = true,
  });

  @override
  State<BasicReferralCodeInput> createState() => _BasicReferralCodeInputState();
}

class _BasicReferralCodeInputState extends State<BasicReferralCodeInput> {
  final TextEditingController _codeController = TextEditingController();
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isValid;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndApplyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _validationMessage = 'Vui lòng nhập mã giới thiệu';
        _isValid = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
      _isValid = null;
    });

    try {
      final result = await BasicReferralService.applyReferralCode(
        code: code,
        newUserId: widget.userId,
      );

      if (result != null && result['success'] == true) {
        setState(() {
          _validationMessage = '✅ ${result['message'] ?? 'Thành công!'}';
          _isValid = true;
        });

        widget.onResult?.call(
          true,
          result['message']?.toString() ?? 'Áp dụng mã thành công!',
        );

        // Clear the input after successful application
        _codeController.clear();
      } else {
        setState(() {
          _validationMessage = '❌ ${result?['message'] ?? 'Mã không hợp lệ'}';
          _isValid = false;
        });

        widget.onResult?.call(
          false,
          result?['message']?.toString() ?? 'Có lỗi xảy ra',
        );
      }
    } catch (e) {
      setState(() {
        _validationMessage = '❌ Lỗi kết nối: $e';
        _isValid = false;
      });

      widget.onResult?.call(false, 'Lỗi kết nối: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _onCodeChanged(String value) {
    if (_validationMessage != null) {
      setState(() {
        _validationMessage = null;
        _isValid = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isValid == true
              ? Colors.green
              : _isValid == false
              ? AppColors.error
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(Icons.redeem, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mã Giới Thiệu',
                  style: AppTypography.headingXSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  onChanged: _onCodeChanged,
                  enabled: !_isValidating,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giới thiệu (VD: SABO-USERNAME)',
                    prefixIcon: Icon(
                      Icons.code,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: 'monospace',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateAndApplyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isValidating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Áp dụng',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),

          // Validation Message
          if (_validationMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isValid == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isValid == true
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _validationMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: _isValid == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],

          // Benefits Info
          if (!_isValidating && _validationMessage == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhận +50 điểm SPA khi sử dụng mã giới thiệu hợp lệ',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version for inline use
class CompactReferralCodeInput extends StatelessWidget {
  final String userId;
  final Function(bool success, String message)? onResult;

  const CompactReferralCodeInput({
    super.key,
    required this.userId,
    this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return BasicReferralCodeInput(
      userId: userId,
      onResult: onResult,
      showTitle: false,
    );
  }
}
