import 'package:flutter/material.dart';
import '../../theme/app_bar_theme.dart' as app_theme;

import '../../routes/app_routes.dart';
import '../../widgets/loading_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/design_system/design_system.dart';
import 'widgets/horizontal_club_list.dart';
import 'widgets/club_detail_section.dart';
import 'controllers/club_list_controller.dart';
import 'dialogs/club_registration_dialog.dart';
import 'dialogs/club_search_dialog.dart';
import 'dialogs/club_filter_dialog.dart';
// ELON_MODE_AUTO_FIX

class ClubMainScreen extends StatefulWidget {
  const ClubMainScreen({super.key});

  @override
  State<ClubMainScreen> createState() => _ClubMainScreenState();
}

class _ClubMainScreenState extends State<ClubMainScreen> {
  late ClubListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClubListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showRegisterClubDialog() {
    ClubRegistrationDialog.show(
      context,
      onConfirm: _navigateToRegisterClubForm,
    );
  }

  void _navigateToRegisterClubForm() {
    Navigator.pushNamed(context, '/club_registration_screen');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            automaticallyImplyLeading: false,
            title: app_theme.AppBarTheme.buildGradientTitle('Câu lạc bộ'),
            centerTitle: false,
            actions: [
              // Filter button
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  onPressed: _showFilterDialog,
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Lọc câu lạc bộ',
                ),
              ),
              // Search button
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: _showSearchDialog,
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Icon(
                          Icons.search,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Tìm kiếm câu lạc bộ',
                    ),
                    // Filter active indicator
                    if (_controller.searchQuery.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => _controller.search(''),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Rank management button
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.rankManagementScreen);
                  },
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Quản lý hạng',
                ),
              ),
              // Register club button
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: _showRegisterClubDialog,
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Icon(
                      Icons.add_business_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  tooltip: 'Đăng ký câu lạc bộ',
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 0.5,
                color: AppColors.gray200,
              ),
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.clubs.isEmpty) {
      return const LoadingStateWidget(
        message: 'Đang tải danh sách câu lạc bộ...',
      );
    }

    if (_controller.errorMessage != null && _controller.clubs.isEmpty) {
      return RefreshableErrorStateWidget(
        errorMessage: _controller.errorMessage,
        onRefresh: () async => _controller.loadClubs(refresh: true),
        title: 'Không thể tải danh sách câu lạc bộ',
        description: 'Đã xảy ra lỗi khi tải thông tin câu lạc bộ',
        showErrorDetails: true,
      );
    }

    if (!_controller.isLoading && _controller.clubs.isEmpty) {
      return RefreshableEmptyStateWidget(
        message: 'Chưa có câu lạc bộ nào',
        subtitle: 'Hãy là người đầu tiên đăng ký câu lạc bộ của bạn',
        icon: Icons.business,
        onRefresh: () async => _controller.loadClubs(refresh: true),
        actionLabel: 'Đăng ký câu lạc bộ',
        onAction: _showRegisterClubDialog,
      );
    }

    return Column(
      children: [
        // Top section: Horizontal Club List (1/3 screen)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: HorizontalClubList(
            clubs: _controller.clubs,
            selectedClub: _controller.selectedClub,
            onClubSelected: _controller.selectClub,
            onLoadMore: () => _controller.loadClubs(),
          ),
        ),

        // Divider
        Container(
          height: 1,
          color: AppColors.gray200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),

        // Bottom section: Club Detail (2/3 screen)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: _controller.selectedClub != null
                ? ClubDetailSection(
                    key: ValueKey(_controller.selectedClub!.id),
                    club: _controller.selectedClub!,
                    onNeedRefresh: () => _controller.loadClubs(refresh: true),
                  )
                : Center(
                    key: const ValueKey('empty'),
                    child: Text(
                      'Chọn một câu lạc bộ để xem chi tiết', overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }






  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Row(
  //         children: [
  //           Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
  //           const SizedBox(width: 8),
  //           Text('Cam kết xác thực', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
  //         ],
  //       ),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Tôi cam kết rằng:', overflow: TextOverflow.ellipsis, style: AppTypography.headingSmall),
  //             const SizedBox(height: 12),
  //             _buildCommitmentItem(
  //               '✓',
  //               'Tôi là chủ sở hữu hoặc người được ủy quyền đại diện cho câu lạc bộ này',
  //             ),
  //             _buildCommitmentItem(
  //               '✓',
  //               'Tất cả thông tin tôi cung cấp là chính xác và có thể xác minh',
  //             ),
  //             _buildCommitmentItem(
  //               '✓',
  //               'Tôi có đủ tài liệu chứng minh quyền sở hữu/quản lý câu lạc bộ',
  //             ),
  //             _buildCommitmentItem(
  //               '✓',
  //               'Tôi đồng ý với quy trình xác minh của Sabo Arena',
  //             ),
  //             _buildCommitmentItem(
  //               '✓',
  //               'Tôi hiểu rằng thông tin sai lệch sẽ dẫn đến từ chối đăng ký',
  //             ),
  //             const SizedBox(height: 16),
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.red.withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.gavel, color: Colors.red.shade700, size: 20),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       'Lưu ý: Việc cung cấp thông tin sai lệch hoặc giả mạo có thể dẫn đến khóa tài khoản vĩnh viễn.', overflow: TextOverflow.ellipsis, style: TextStyle(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w500,
  //                         color: Colors.red.shade700,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         DSButton(
  //           text: 'Quay lại',
  //           onPressed: () => Navigator.of(context).pop(),
  //           variant: DSButtonVariant.ghost,
  //         ),
  //         DSButton(
  //           text: 'Tôi cam kết và tiếp tục',
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             _navigateToRegisterClubForm();
  //           },
  //           variant: DSButtonVariant.primary,
  //         ),
  //       ],
  //     ),
  //   );
  // }





  void _showSearchDialog() {
    ClubSearchDialog.show(
      context,
      initialQuery: _controller.searchQuery,
      onSearch: _controller.search,
    );
  }

  void _showFilterDialog() {
    ClubFilterDialog.show(context);
  }
}

