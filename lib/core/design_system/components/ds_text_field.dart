/// DSTextField - Design System Text Field Component
///
/// Instagram/Facebook quality text input with:
/// - 2 variants (outlined, filled)
/// - Label and hint text
/// - Error states with validation
/// - Prefix/suffix icons
/// - Character counter
/// - Multi-line support
/// - Password toggle
/// - Focus animation
///
/// Usage:
/// ```dart
/// DSTextField(
///   label: 'Email',
///   hintText: 'Enter your email',
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Text field variants
enum DSTextFieldVariant {
  /// Outlined border style
  outlined,

  /// Filled background style
  filled,
}

/// Design System Text Field Component
class DSTextField extends StatefulWidget {
  /// Text controller
  final TextEditingController? controller;

  /// Initial value
  final String? initialValue;

  /// Label text
  final String? label;

  /// Hint text
  final String? hintText;

  /// Helper text (shown below field)
  final String? helperText;

  /// Error text (overrides validator)
  final String? errorText;

  /// Validator function
  final String? Function(String?)? validator;

  /// Text field variant
  final DSTextFieldVariant variant;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix widget (overrides suffixIcon)
  final Widget? suffix;

  /// Prefix widget (overrides prefixIcon)
  final Widget? prefix;

  /// Suffix icon tap callback
  final VoidCallback? onSuffixIconTap;

  /// Prefix icon tap callback
  final VoidCallback? onPrefixIconTap;

  /// Text change callback
  final void Function(String)? onChanged;

  /// Submit callback
  final void Function(String)? onSubmitted;

  /// Focus change callback
  final void Function(bool)? onFocusChanged;

  /// Tap callback
  final VoidCallback? onTap;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Max lines (1 for single line, null for unlimited)
  final int? maxLines;

  /// Min lines
  final int? minLines;

  /// Max length
  final int? maxLength;

  /// Show character counter
  final bool showCounter;

  /// Obscure text (for passwords)
  final bool obscureText;

  /// Enable password toggle
  final bool enablePasswordToggle;

  /// Enable field
  final bool enabled;

  /// Read only
  final bool readOnly;

  /// Auto focus
  final bool autofocus;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Auto validate mode
  final AutovalidateMode? autovalidateMode;

  /// Focus node
  final FocusNode? focusNode;

  /// Custom border radius
  final double? borderRadius;

  /// Enable haptic feedback
  final bool enableHaptic;

  const DSTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.variant = DSTextFieldVariant.outlined,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.prefix,
    this.onSuffixIconTap,
    this.onPrefixIconTap,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autovalidateMode,
    this.focusNode,
    this.borderRadius,
    this.enableHaptic = true,
  }) : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue',
        );

  /// Email text field factory
  factory DSTextField.email({
    TextEditingController? controller,
    String? label,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool autofocus = false,
  }) {
    return DSTextField(
      controller: controller,
      label: label ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }

  /// Password text field factory
  factory DSTextField.password({
    TextEditingController? controller,
    String? label,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool autofocus = false,
  }) {
    return DSTextField(
      controller: controller,
      label: label ?? 'Password',
      hintText: hintText ?? 'Enter your password',
      obscureText: true,
      enablePasswordToggle: true,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_outline,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }

  /// Search text field factory
  factory DSTextField.search({
    TextEditingController? controller,
    String? hintText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    VoidCallback? onClearTap,
  }) {
    return DSTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      variant: DSTextFieldVariant.filled,
      prefixIcon: Icons.search,
      suffixIcon: Icons.close,
      onSuffixIconTap: onClearTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }

  /// Multiline text field factory
  factory DSTextField.multiline({
    TextEditingController? controller,
    String? label,
    String? hintText,
    int? maxLines,
    int? maxLength,
    bool showCounter = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return DSTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: showCounter,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  @override
  State<DSTextField> createState() => _DSTextFieldState();
}

class _DSTextFieldState extends State<DSTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  String? _errorText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _togglePasswordVisibility() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);

    // Run validator if provided
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  void _handleTap() {
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  Color get _fillColor {
    if (!widget.enabled) {
      return AppColors.gray100;
    }

    if (widget.variant == DSTextFieldVariant.filled) {
      return _isFocused ? AppColors.gray100 : AppColors.gray50;
    }

    return Colors.transparent;
  }

  Color get _borderColor {
    if (_hasError) {
      return AppColors.error;
    }

    if (!widget.enabled) {
      return AppColors.gray300;
    }

    if (_isFocused) {
      return AppColors.primary;
    }

    return AppColors.border;
  }

  double get _borderWidth {
    if (_isFocused) {
      return 2.0;
    }
    return 1.0;
  }

  bool get _hasError => _errorText != null || widget.errorText != null;

  String? get _displayErrorText => widget.errorText ?? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _hasError
                  ? AppColors.error
                  : widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
        ],

        // Text Field
        AnimatedContainer(
          duration: DesignTokens.durationFast,
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: DesignTokens.radius(
              widget.borderRadius ?? DesignTokens.radiusSM,
            ),
            border: Border.all(color: _borderColor, width: _borderWidth),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onChanged: _handleChanged,
            onSubmitted: widget.onSubmitted,
            onTap: _handleTap,
            style: TextStyle(
              fontSize: 15,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 15,
                color: AppColors.textTertiary,
              ),
              prefixIcon: _buildPrefixIcon(),
              suffixIcon: _buildSuffixIcon(),
              prefix: widget.prefix,
              suffix: widget.suffix,
              contentPadding: DesignTokens.only(
                left: widget.prefixIcon == null && widget.prefix == null
                    ? DesignTokens.space16
                    : DesignTokens.space12,
                right: widget.suffixIcon == null && widget.suffix == null
                    ? DesignTokens.space16
                    : DesignTokens.space12,
                top: DesignTokens.space12,
                bottom: DesignTokens.space12,
              ),
              border: InputBorder.none,
              counterText: widget.showCounter ? null : '',
            ),
          ),
        ),

        // Helper/Error Text
        if (widget.helperText != null || _displayErrorText != null) ...[
          SizedBox(height: DesignTokens.space8),
          Row(
            children: [
              if (_hasError)
                Icon(
                  Icons.error_outline,
                  size: DesignTokens.iconXS,
                  color: AppColors.error,
                ),
              if (_hasError) SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Text(
                  _displayErrorText ?? widget.helperText!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _hasError ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Character Counter
        if (widget.showCounter && widget.maxLength != null) ...[
          SizedBox(height: DesignTokens.space4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_controller.text.length}/${widget.maxLength}',
              style: TextStyle(
                fontSize: 12,
                color: _controller.text.length > widget.maxLength!
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon == null) return null;

    return GestureDetector(
      onTap: widget.onPrefixIconTap,
      child: Icon(
        widget.prefixIcon,
        size: DesignTokens.iconMD,
        color: _hasError
            ? AppColors.error
            : _isFocused
                ? AppColors.primary
                : AppColors.textSecondary,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    // Password toggle takes priority
    if (widget.enablePasswordToggle && widget.obscureText) {
      return GestureDetector(
        onTap: _togglePasswordVisibility,
        child: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: DesignTokens.iconMD,
          color: _isFocused ? AppColors.primary : AppColors.textSecondary,
        ),
      );
    }

    // Clear button for search fields (when has text)
    if (widget.suffixIcon == Icons.close && _controller.text.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (widget.enableHaptic) {
            HapticFeedback.lightImpact();
          }
          _controller.clear();
          widget.onChanged?.call('');
          widget.onSuffixIconTap?.call();
        },
        child: const Icon(
          Icons.close,
          size: DesignTokens.iconMD,
          color: AppColors.textSecondary,
        ),
      );
    }

    if (widget.suffixIcon == null) return null;

    return GestureDetector(
      onTap: widget.onSuffixIconTap,
      child: Icon(
        widget.suffixIcon,
        size: DesignTokens.iconMD,
        color: _hasError
            ? AppColors.error
            : _isFocused
                ? AppColors.primary
                : AppColors.textSecondary,
      ),
    );
  }
}

/// Text field with validation indicator
class DSValidatedTextField extends StatefulWidget {
  /// All DSTextField properties
  final DSTextField textField;

  /// Show validation checkmark when valid
  final bool showValidationCheck;

  const DSValidatedTextField({
    super.key,
    required this.textField,
    this.showValidationCheck = true,
  });

  @override
  State<DSValidatedTextField> createState() => _DSValidatedTextFieldState();
}

class _DSValidatedTextFieldState extends State<DSValidatedTextField> {
  bool _isValid = false;

  void _handleValidation(String value) {
    final error = widget.textField.validator?.call(value);
    setState(() {
      _isValid = error == null && value.isNotEmpty;
    });
    widget.textField.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return DSTextField(
      controller: widget.textField.controller,
      initialValue: widget.textField.initialValue,
      label: widget.textField.label,
      hintText: widget.textField.hintText,
      helperText: widget.textField.helperText,
      errorText: widget.textField.errorText,
      validator: widget.textField.validator,
      variant: widget.textField.variant,
      prefixIcon: widget.textField.prefixIcon,
      suffixIcon: widget.showValidationCheck && _isValid
          ? Icons.check_circle
          : widget.textField.suffixIcon,
      suffix: widget.textField.suffix,
      prefix: widget.textField.prefix,
      onSuffixIconTap: widget.textField.onSuffixIconTap,
      onPrefixIconTap: widget.textField.onPrefixIconTap,
      onChanged: _handleValidation,
      onSubmitted: widget.textField.onSubmitted,
      onFocusChanged: widget.textField.onFocusChanged,
      onTap: widget.textField.onTap,
      keyboardType: widget.textField.keyboardType,
      textInputAction: widget.textField.textInputAction,
      maxLines: widget.textField.maxLines,
      minLines: widget.textField.minLines,
      maxLength: widget.textField.maxLength,
      showCounter: widget.textField.showCounter,
      obscureText: widget.textField.obscureText,
      enablePasswordToggle: widget.textField.enablePasswordToggle,
      enabled: widget.textField.enabled,
      readOnly: widget.textField.readOnly,
      autofocus: widget.textField.autofocus,
      textCapitalization: widget.textField.textCapitalization,
      inputFormatters: widget.textField.inputFormatters,
      autovalidateMode: widget.textField.autovalidateMode,
      focusNode: widget.textField.focusNode,
      borderRadius: widget.textField.borderRadius,
      enableHaptic: widget.textField.enableHaptic,
    );
  }
}
