import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../../services/social_auth_service.dart';

/// Widget for social authentication buttons (Google, Facebook, Apple)
class SocialAuthButtons extends StatefulWidget {
  final Function(String provider, dynamic user)? onSuccess;
  final Function(String provider, String error)? onError;
  final bool showApple;
  final bool showGoogle;
  final bool showFacebook;
  final String buttonText; // "Sign in" or "Sign up"

  const SocialAuthButtons({
    super.key,
    this.onSuccess,
    this.onError,
    this.showApple = true,
    this.showGoogle = true,
    this.showFacebook = true,
    this.buttonText = 'Sign in',
  });

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  final SocialAuthService _socialAuth = SocialAuthService();
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isAppleLoading = false;
  bool _isAppleAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppleAvailability();
  }

  Future<void> _checkAppleAvailability() async {
    if (widget.showApple && Platform.isIOS) {
      final available = await SocialAuthService.isAppleSignInAvailable();
      if (mounted) {
        setState(() {
          _isAppleAvailable = available;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final response = await _socialAuth.signInWithGoogle();
      if (response?.user != null && mounted) {
        widget.onSuccess?.call('google', response!.user);
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('google', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isFacebookLoading) return;

    setState(() {
      _isFacebookLoading = true;
    });

    try {
      final response = await _socialAuth.signInWithFacebook();
      if (response?.user != null && mounted) {
        widget.onSuccess?.call('facebook', response!.user);
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('facebook', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isAppleLoading || !_isAppleAvailable) return;

    setState(() {
      _isAppleLoading = true;
    });

    try {
      final response = await _socialAuth.signInWithApple();
      if (response?.user != null && mounted) {
        widget.onSuccess?.call('apple', response!.user);
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('apple', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = [];

    // Apple Sign In (iOS only)
    if (widget.showApple && _isAppleAvailable && Platform.isIOS) {
      buttons.add(_buildAppleButton());
    }

    // Google Sign In
    if (widget.showGoogle) {
      buttons.add(_buildGoogleButton());
    }

    // Facebook Sign In
    if (widget.showFacebook) {
      buttons.add(_buildFacebookButton());
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Divider with "Or continue with"
        if (buttons.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.space16),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                  ),
                  child: const Text(
                    'Hoặc tiếp tục với',
                    style: AppTypography.captionMedium,
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border, thickness: 1)),
              ],
            ),
          ),
        ],

        // Social buttons
        ...buttons.map(
          (button) => Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space12),
            child: button,
          ),
        ),
      ],
    );
  }

  Widget _buildAppleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isAppleLoading ? null : _handleAppleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
        child: _isAppleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apple, color: Colors.white, size: 20),
                  SizedBox(width: DesignTokens.space8),
                  Text(
                    '${widget.buttonText} with Apple',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
        child: _isGoogleLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.g_mobiledata,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: DesignTokens.space8),
                  Text(
                    '${widget.buttonText} with Google',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFacebookButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isFacebookLoading ? null : _handleFacebookSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2), // Facebook blue
          side: const BorderSide(color: Color(0xFF1877F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
        child: _isFacebookLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.facebook, color: Colors.white, size: 20),
                  SizedBox(width: DesignTokens.space8),
                  Text(
                    '${widget.buttonText} with Facebook',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
