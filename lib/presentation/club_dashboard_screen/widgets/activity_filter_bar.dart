import 'package:flutter/material.dart';
// Temporarily removed AppLocalizations import
import 'package:sabo_arena/core/design_system/design_system.dart';

class ActivityFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final VoidCallback onDateRangeSelected;

  const ActivityFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("Tất cả", 'all', AppIcons.menu),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip("Giải đấu", 'tournament', AppIcons.trophy),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip("Tập luyện", 'training', Icons.fitness_center),
          SizedBox(width: DesignTokens.space8),
          _buildFilterChip("Xã hội", 'social', AppIcons.following),
          SizedBox(width: DesignTokens.space8),
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIcons.sizeSM,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          SizedBox(width: DesignTokens.space4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        onFilterSelected(value);
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space4,
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return ActionChip(
      avatar: Icon(
        Icons.calendar_today,
        size: AppIcons.sizeSM,
        color: AppColors.textSecondary,
      ),
      label: Text("Thời gian"),
      onPressed: onDateRangeSelected,
      backgroundColor: Colors.white,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space4,
      ),
    );
  }
}
