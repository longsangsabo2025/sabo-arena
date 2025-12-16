/// Design System Example Page
///
/// Demonstrates all components and features of the design system
/// Use this as a reference when building new pages

import 'package:flutter/material.dart';
import '../design_system.dart';

class DesignSystemExamplePage extends StatelessWidget {
  const DesignSystemExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System Examples')),
      body: ListView(
        padding: context.responsiveScreenPadding,
        children: [
          // Typography Section
          _buildSection(
            context,
            title: 'Typography',
            children: [
              Text('Display Large', style: AppTypography.displayLarge),
              Text('Display Medium', style: AppTypography.displayMedium),
              Text('Heading Large', style: AppTypography.headingLarge),
              Text('Heading Medium', style: AppTypography.headingMedium),
              Text('Body Large', style: AppTypography.bodyLarge),
              Text('Body Medium (Default)', style: AppTypography.bodyMedium),
              Text('Label Medium', style: AppTypography.labelMedium),
              Text('Caption Medium', style: AppTypography.captionMedium),
            ],
          ),

          // Colors Section
          _buildSection(
            context,
            title: 'Colors',
            children: [
              _buildColorRow('Primary', AppColors.primary),
              _buildColorRow('Secondary', AppColors.secondary),
              _buildColorRow('Success', AppColors.success),
              _buildColorRow('Error', AppColors.error),
              _buildColorRow('Warning', AppColors.warning),
              _buildColorRow('Info', AppColors.info),
            ],
          ),

          // Buttons Section
          _buildSection(
            context,
            title: 'Buttons',
            children: [
              DSButton.primary(text: 'Primary Button', onPressed: () {}),
              SizedBox(height: DesignTokens.space12),
              DSButton.secondary(text: 'Secondary Button', onPressed: () {}),
              SizedBox(height: DesignTokens.space12),
              DSButton.tertiary(text: 'Tertiary Button', onPressed: () {}),
              SizedBox(height: DesignTokens.space12),
              DSButton.ghost(text: 'Ghost Button', onPressed: () {}),
              SizedBox(height: DesignTokens.space12),
              DSButton.primary(
                text: 'With Icon',
                leadingIcon: AppIcons.add,
                onPressed: () {},
              ),
              SizedBox(height: DesignTokens.space12),
              DSButton.primary(
                text: 'Loading',
                isLoading: true,
                onPressed: null,
              ),
              SizedBox(height: DesignTokens.space12),
              DSButton.primary(
                text: 'Full Width',
                fullWidth: true,
                onPressed: () {},
              ),
            ],
          ),

          // Text Fields Section
          _buildSection(
            context,
            title: 'Text Fields',
            children: [
              DSTextField(
                label: 'Email',
                hintText: 'Enter your email',
                prefixIcon: AppIcons.email,
              ),
              SizedBox(height: DesignTokens.space16),
              DSTextField(
                label: 'Password',
                hintText: 'Enter password',
                prefixIcon: AppIcons.lock,
                obscureText: true,
              ),
              SizedBox(height: DesignTokens.space16),
              DSTextField(
                label: 'With Error',
                errorText: 'This field is required',
                prefixIcon: AppIcons.error,
              ),
            ],
          ),

          // Cards Section
          _buildSection(
            context,
            title: 'Cards',
            children: [
              DSCard.elevated(
                onTap: () {},
                child: Padding(
                  padding: DesignTokens.all(DesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elevated Card', style: AppTypography.headingSmall),
                      SizedBox(height: DesignTokens.space8),
                      Text(
                        'This is an elevated card with shadow',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: DesignTokens.space12),
              DSCard.outlined(
                onTap: () {},
                child: Padding(
                  padding: DesignTokens.all(DesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outlined Card', style: AppTypography.headingSmall),
                      SizedBox(height: DesignTokens.space8),
                      Text(
                        'This is an outlined card with border',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Avatars Section
          _buildSection(
            context,
            title: 'Avatars',
            children: [
              Row(
                children: [
                  DSAvatar(size: DSAvatarSize.small, fallbackText: 'SM'),
                  SizedBox(width: DesignTokens.space12),
                  DSAvatar(size: DSAvatarSize.medium, fallbackText: 'MD'),
                  SizedBox(width: DesignTokens.space12),
                  DSAvatar(size: DSAvatarSize.large, fallbackText: 'LG'),
                  SizedBox(width: DesignTokens.space12),
                  DSAvatar(
                    size: DSAvatarSize.extraLarge,
                    fallbackText: 'XL',
                    showOnlineIndicator: true,
                  ),
                ],
              ),
            ],
          ),

          // Loading Indicators Section
          _buildSection(
            context,
            title: 'Loading Indicators',
            children: [
              Row(
                children: [
                  DSSpinner.primary(size: DSSpinnerSize.small),
                  SizedBox(width: DesignTokens.space16),
                  DSSpinner.primary(size: DSSpinnerSize.medium),
                  SizedBox(width: DesignTokens.space16),
                  DSSpinner.primary(size: DSSpinnerSize.large),
                ],
              ),
              SizedBox(height: DesignTokens.space16),
              DSProgressBar(value: 0.65, showPercentage: true),
            ],
          ),

          // Icons Section
          _buildSection(
            context,
            title: 'Icons',
            children: [
              Wrap(
                spacing: DesignTokens.space16,
                runSpacing: DesignTokens.space16,
                children: [
                  _buildIconItem(AppIcons.home, 'Home'),
                  _buildIconItem(AppIcons.search, 'Search'),
                  _buildIconItem(AppIcons.notifications, 'Notifications'),
                  _buildIconItem(AppIcons.profile, 'Profile'),
                  _buildIconItem(AppIcons.like, 'Like'),
                  _buildIconItem(AppIcons.comment, 'Comment'),
                  _buildIconItem(AppIcons.share, 'Share'),
                  _buildIconItem(AppIcons.trophy, 'Trophy'),
                ],
              ),
            ],
          ),

          // Spacing Section
          _buildSection(
            context,
            title: 'Spacing Scale',
            children: [
              _buildSpacingExample('space4', DesignTokens.space4),
              _buildSpacingExample('space8', DesignTokens.space8),
              _buildSpacingExample('space12', DesignTokens.space12),
              _buildSpacingExample('space16', DesignTokens.space16),
              _buildSpacingExample('space24', DesignTokens.space24),
              _buildSpacingExample('space32', DesignTokens.space32),
            ],
          ),

          // Responsive Section
          _buildSection(
            context,
            title: 'Responsive Info',
            children: [
              _buildInfoRow('Device Type', context.deviceType.toString()),
              _buildInfoRow('Is Mobile', context.isMobile.toString()),
              _buildInfoRow('Is Tablet', context.isTablet.toString()),
              _buildInfoRow('Is Desktop', context.isDesktop.toString()),
              _buildInfoRow('Screen Width', '${context.screenWidth.toInt()}px'),
              _buildInfoRow(
                'Screen Height',
                '${context.screenHeight.toInt()}px',
              ),
            ],
          ),

          // Chips Section
          _buildSection(
            context,
            title: 'Chips',
            children: [
              DSChipGroup(
                chips: [
                  DSChip.filled(label: 'Filled', onTap: () {}),
                  DSChip.outlined(label: 'Outlined', onTap: () {}),
                  DSChip.tonal(label: 'Tonal', onTap: () {}),
                  DSChip.filled(
                    label: 'With Icon',
                    leadingIcon: AppIcons.tag,
                    onTap: () {},
                  ),
                  DSChip.input(label: 'Deletable', onDelete: () {}),
                ],
              ),
            ],
          ),

          // Badges Section
          _buildSection(
            context,
            title: 'Badges',
            children: [
              Wrap(
                spacing: DesignTokens.space24,
                runSpacing: DesignTokens.space16,
                children: [
                  DSBadge.count(
                    count: 5,
                    child: Icon(AppIcons.notifications, size: 32),
                  ),
                  DSBadge.dot(
                    color: DSBadgeColor.success,
                    child: Icon(AppIcons.profile, size: 32),
                  ),
                  DSBadge.text(
                    label: 'NEW',
                    child: Container(
                      width: 60,
                      height: 60,
                      color: AppColors.gray200,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.space16),
              Row(
                children: [
                  DSBadgeStandalone(text: 'Primary'),
                  SizedBox(width: DesignTokens.space8),
                  DSBadgeStandalone(
                    text: 'Success',
                    color: DSBadgeColor.success,
                  ),
                  SizedBox(width: DesignTokens.space8),
                  DSBadgeStandalone(text: 'Error', color: DSBadgeColor.error),
                ],
              ),
            ],
          ),

          // Switch Section
          _buildSection(
            context,
            title: 'Switches',
            children: [
              DSSwitchTile(
                title: 'Enable notifications',
                subtitle: 'Receive push notifications',
                value: true,
                onChanged: (value) {},
              ),
              DSSwitchTile(
                title: 'Dark mode',
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),

          // Checkbox Section
          _buildSection(
            context,
            title: 'Checkboxes',
            children: [
              DSCheckboxTile(
                title: 'Remember me',
                value: true,
                onChanged: (value) {},
              ),
              DSCheckboxTile(
                title: 'Send me updates',
                subtitle: 'Get the latest news and updates',
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),

          // Radio Section
          _buildSection(
            context,
            title: 'Radio Buttons',
            children: [
              DSRadioGroup<String>(
                options: const [
                  DSRadioOption(value: 'option1', title: 'Option 1'),
                  DSRadioOption(value: 'option2', title: 'Option 2'),
                  DSRadioOption(
                    value: 'option3',
                    title: 'Option 3',
                    subtitle: 'With subtitle',
                  ),
                ],
                selectedValue: 'option1',
                onChanged: (value) {},
              ),
            ],
          ),

          // Snackbar Demo Section
          _buildSection(
            context,
            title: 'Snackbars',
            children: [
              DSButton.secondary(
                text: 'Show Success',
                onPressed: () => DSSnackbar.success(
                  context: context,
                  message: 'Operation successful!',
                ),
              ),
              SizedBox(height: DesignTokens.space8),
              DSButton.secondary(
                text: 'Show Error',
                onPressed: () => DSSnackbar.error(
                  context: context,
                  message: 'An error occurred!',
                ),
              ),
              SizedBox(height: DesignTokens.space8),
              DSButton.secondary(
                text: 'Show Warning',
                onPressed: () => DSSnackbar.warning(
                  context: context,
                  message: 'Warning: Please check your input',
                ),
              ),
              SizedBox(height: DesignTokens.space8),
              DSButton.secondary(
                text: 'Show Info',
                onPressed: () => DSSnackbar.info(
                  context: context,
                  message: 'Did you know? This is a tip!',
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.space64),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: DesignTokens.space24),
        Text(title, style: AppTypography.headingMedium),
        SizedBox(height: DesignTokens.space16),
        ...children,
      ],
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
              border: Border.all(color: AppColors.border),
            ),
          ),
          SizedBox(width: DesignTokens.space12),
          Text(name, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildIconItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: AppIcons.sizeLG, color: AppColors.primary),
        SizedBox(height: DesignTokens.space4),
        Text(label, style: AppTypography.captionMedium),
      ],
    );
  }

  Widget _buildSpacingExample(String name, double size) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        children: [
          Container(width: size, height: 20, color: AppColors.primary),
          SizedBox(width: DesignTokens.space12),
          Text('$name (${size.toInt()}px)', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.bodyMediumMedium),
        ],
      ),
    );
  }
}
