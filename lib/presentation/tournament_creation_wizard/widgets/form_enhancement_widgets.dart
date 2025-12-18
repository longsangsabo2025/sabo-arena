import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';

/// Widget hiển thị progress của form với step completion indicators
class FormProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final List<bool> stepCompleted;
  final bool hasUnsavedChanges;

  const FormProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.stepCompleted,
    this.hasUnsavedChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = stepCompleted.length > index
                  ? stepCompleted[index]
                  : false;
              final isPast = index < currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? Colors.green.shade600
                              : isPast
                              ? Colors.orange.shade400
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.h),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1) SizedBox(width: 8.w),
                  ],
                ),
              );
            }),
          ),

          SizedBox(height: 12.h),

          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = stepCompleted.length > index
                  ? stepCompleted[index]
                  : false;
              final isPast = index < currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade600
                            : isActive
                            ? Colors.blue.shade600
                            : isPast
                            ? Colors.orange.shade400
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 14.w)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.w,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      stepTitles[index],
                      style: TextStyle(
                        fontSize: 10.w,
                        color: isActive
                            ? Colors.blue.shade600
                            : Colors.grey.shade600,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),

          // Unsaved changes indicator
          if (hasUnsavedChanges) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.orange.shade600, size: 8.w),
                  SizedBox(width: 6.w),
                  Text(
                    'Có thay đổi chưa lưu',
                    style: TextStyle(
                      fontSize: 11.w,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
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

/// Widget hiển thị validation feedback tốt hơn
class ValidationFeedbackWidget extends StatelessWidget {
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final Map<String, String> successes;

  const ValidationFeedbackWidget({
    super.key,
    this.errors = const {},
    this.warnings = const {},
    this.successes = const {},
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyFeedback =
        errors.isNotEmpty || warnings.isNotEmpty || successes.isNotEmpty;

    if (!hasAnyFeedback) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          // Errors
          if (errors.isNotEmpty) ...[
            _buildFeedbackCard(
              icon: Icons.error_outline,
              color: Colors.red,
              title: 'Lỗi cần sửa',
              items: errors,
            ),
            SizedBox(height: 8.h),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            _buildFeedbackCard(
              icon: Icons.warning_outlined,
              color: Colors.orange,
              title: 'Cảnh báo',
              items: warnings,
            ),
            SizedBox(height: 8.h),
          ],

          // Successes
          if (successes.isNotEmpty) ...[
            _buildFeedbackCard(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              title: 'Hoàn thành',
              items: successes,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard({
    required IconData icon,
    required Color color,
    required String title,
    required Map<String, String> items,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.w,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...items.entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6.w, color: color),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(fontSize: 13.w, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              ,
        ],
      ),
    );
  }
}

/// Enhanced form field với validation visual feedback
class EnhancedFormField extends StatelessWidget {
  final String label;
  final String? value;
  final TextEditingController? controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final bool isValid;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const EnhancedFormField({
    super.key,
    required this.label,
    this.value,
    this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.isValid = true,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isEmpty = (controller?.text ?? value) == null || (controller?.text ?? value)!.isEmpty;
    final showValidIcon = !isEmpty && isValid && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          initialValue: controller != null ? null : (readOnly ? null : value),
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            labelStyle: TextStyle(
              color: hasError
                  ? Colors.red.shade700
                  : isRequired && isEmpty
                  ? Colors.orange.shade700
                  : null,
            ),
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: hasError
                        ? Colors.red.shade600
                        : showValidIcon
                        ? Colors.green.shade600
                        : null,
                  )
                : null,
            suffixIcon:
                suffix ??
                (showValidIcon
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20.w,
                      )
                    : hasError
                    ? Icon(Icons.error, color: Colors.red.shade600, size: 20.w)
                    : null),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: showValidIcon
                    ? Colors.green.shade300
                    : isRequired && isEmpty
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade600 : Colors.blue.shade600,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
