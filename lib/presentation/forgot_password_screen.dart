import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// ELON_MODE_AUTO_FIX

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFocusNode = FocusNode(); // ✅ Add focus nodes
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _usePhone = false; // Toggle between email and phone

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose(); // ✅ Dispose focus nodes
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_usePhone) {
        // ✅ Improved phone OTP handling
        String phoneNumber = _phoneController.text.trim();

        // Format phone number properly
        if (!phoneNumber.startsWith('0')) {
          phoneNumber = '0$phoneNumber';
        }

        final result = await AuthService.instance.sendPhoneOTP(phoneNumber);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi mã OTP đến số điện thoại $phoneNumber',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to OTP verification screen
          Navigator.of(context).pushNamed(
            '/otp-verification',
            arguments: {
              'phone': phoneNumber,
              'otp_debug': result['otp_debug'], // For development only
              'action': 'reset_password', // ✅ Specify action type
            },
          );
        }
      } else {
        // ✅ Improved email reset handling
        final email = _emailController.text.trim();

        await AuthService.instance.resetPassword(email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi liên kết đặt lại mật khẩu đến $email. Vui lòng kiểm tra hộp thư của bạn.',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // ✅ Better error messages for common cases
        if (errorMessage.contains('not found') ||
            errorMessage.contains('invalid')) {
          if (_usePhone) {
            errorMessage = 'Không tìm thấy tài khoản với số điện thoại này';
          } else {
            errorMessage = 'Không tìm thấy tài khoản với email này';
          }
        } else if (errorMessage.contains('rate limit')) {
          errorMessage =
              'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau 1 phút';
        } else if (errorMessage.toLowerCase().contains('otp')) {
          errorMessage = 'Lỗi gửi OTP: $errorMessage';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                // Clear and retry
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Quên mật khẩu')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.lock_reset, size: 80, color: theme.primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    'Đặt lại mật khẩu',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nhập email hoặc số điện thoại đã đăng ký của bạn. Chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Toggle between Email and Phone
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _usePhone = false);
                              // ✅ Focus email field when switching to email
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                _emailFocusNode.requestFocus();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_usePhone
                                    ? theme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: !_usePhone
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Email',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: !_usePhone
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _usePhone = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _usePhone
                                    ? theme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    color: _usePhone
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Điện thoại',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _usePhone
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Input field based on selection
                  if (!_usePhone)
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      autofocus: true, // ✅ Fix: Auto focus to show keyboard
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Nhập email của bạn',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          _sendResetLink(), // ✅ Submit on Enter
                    )
                  else
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isLoading,
                      autofocus: true, // ✅ Fix: Auto focus to show keyboard
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: 'Số điện thoại của bạn',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        prefixText: '+84 ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        errorStyle: const TextStyle(
                            fontSize: 12), // ✅ Better error display
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        // ✅ Fix: Better phone validation
                        final cleanedPhone =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleanedPhone.length < 9 ||
                            cleanedPhone.length > 10) {
                          return 'Số điện thoại phải có 9-10 chữ số';
                        }
                        if (!cleanedPhone.startsWith('0')) {
                          return 'Số điện thoại phải bắt đầu bằng 0';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          _sendResetLink(), // ✅ Submit on Enter
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _usePhone ? Icons.sms : Icons.send,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _usePhone ? 'Gửi mã OTP' : 'Gửi liên kết',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ); // Close GestureDetector
  }
}
