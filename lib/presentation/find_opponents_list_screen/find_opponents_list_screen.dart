import 'package:flutter/material.dart';
import '../../services/opponent_matching_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/loading_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/common/app_button.dart';
import './widgets/opponent_user_card.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Screen hiển thị danh sách đối thủ được đề xuất (Facebook style)
class FindOpponentsListScreen extends StatefulWidget {
  final bool isTab;
  const FindOpponentsListScreen({super.key, this.isTab = false});

  @override
  State<FindOpponentsListScreen> createState() =>
      _FindOpponentsListScreenState();
}

class _FindOpponentsListScreenState extends State<FindOpponentsListScreen> {
  final OpponentMatchingService _matchingService =
      OpponentMatchingService.instance;

  // ♾️ Infinite Scroll Pagination Controller
  late PagingController<int, UserProfile> _pagingController;
  String? _errorMessage;

  // 🚀 MUSK: Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<UserProfile> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();

    // Initialize paging controller
    _pagingController = PagingController<int, UserProfile>(firstPageKey: 0);

    // Add page request listener
    _pagingController.addPageRequestListener((pageKey) {
      _fetchOpponentsPage(pageKey);
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchOpponentsPage(int pageKey) async {
    try {
      final opponents = await _matchingService.findMatchedOpponents(
        radiusKm: 500,
        rankFilter: null,
        limit: 20,
        offset: pageKey,
      );

      final isLastPage = opponents.length < 20;
      if (isLastPage) {
        _pagingController.appendLastPage(opponents);
      } else {
        _pagingController.appendPage(opponents, pageKey + opponents.length);
      }
    } catch (error) {
      _pagingController.error = error;
      _errorMessage = _getErrorMessage(error);
    }
  }

  Future<void> _loadOpponents() async {
    _pagingController.refresh();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('location')) {
      return 'Không thể xác định vị trí của bạn. Vui lòng cấp quyền truy cập vị trí.';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra và thử lại.';
    } else if (errorStr.contains('authentication')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    } else {
      return 'Có lỗi xảy ra khi tìm kiếm đối thủ. Vui lòng thử lại sau.';
    }
  }

  /// 🚀 MUSK: Debounced search với smart filtering
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
        });
      }
      return;
    }

    // Simple local filtering first (instant results)
    final allOpponents = _pagingController.itemList ?? [];
    final localResults = allOpponents.where((user) {
      return user.displayName.toLowerCase().contains(query.toLowerCase()) ||
          (user.rank ?? '').toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (mounted) {
      setState(() {
        _showSearchResults = true;
        _searchResults = localResults;
      });
    }
  }

  /// Clear search và return to main list
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTab) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: _buildHeaderSearchBar(),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF050505)),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildHeaderSearchBar(),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  /// 🚀 MUSK: Modern search bar for header
  Widget _buildHeaderSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? const Color(0xFF0866FF)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Tìm đối thủ theo tên, rank...',
          hintStyle: const TextStyle(
            color: Color(0xFF65676B),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF65676B),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF65676B),
                    size: 18,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF050505),
          fontSize: 15,
        ),
        onTap: () {
          if (mounted) {
            setState(() {}); // Trigger rebuild to show focus state
          }
        },
        onTapOutside: (_) {
          if (mounted) {
            setState(() {}); // Trigger rebuild to hide focus state
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    // 🚀 MUSK: Show search results khi đang search
    if (_showSearchResults) {
      return _buildSearchResults();
    }

    return RefreshIndicator(
      onRefresh: _loadOpponents,
      child: Column(
        children: [
          // Search hint khi chưa search
          if (_searchController.text.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                '💡 Gõ tên hoặc rank ở thanh tìm kiếm để tìm kiếm nhanh',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: PagedListView<int, UserProfile>(
              pagingController: _pagingController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              builderDelegate: PagedChildBuilderDelegate<UserProfile>(
                itemBuilder: (context, opponent, index) {
                  return OpponentUserCard(
                    user: opponent,
                    onRefresh: () {
                      // Refresh paging controller
                      _pagingController.refresh();
                    },
                  );
                },
                firstPageProgressIndicatorBuilder: (context) =>
                    const LoadingStateWidget(
                        message: 'Đang tìm đối thủ phù hợp...'),
                newPageProgressIndicatorBuilder: (context) => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )),
                firstPageErrorIndicatorBuilder: (context) => ErrorStateWidget(
                  errorMessage: _errorMessage,
                  onRetry: _loadOpponents,
                ),
                noItemsFoundIndicatorBuilder: (context) => EmptyStateWidget(
                  icon: Icons.person_search,
                  message: 'Không tìm thấy đối thủ',
                  subtitle: 'Thử mở rộng phạm vi tìm kiếm hoặc thử lại sau',
                  actionLabel: 'Làm mới',
                  onAction: _loadOpponents,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 MUSK: Search results with instant feedback
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF050505),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử từ khóa khác hoặc xem gợi ý bên dưới',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Xóa tìm kiếm',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              icon: Icons.clear,
              iconTrailing: false,
              onPressed: _clearSearch,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search results header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm thấy ${_searchResults.length} kết quả cho "${_searchController.text}"',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearSearch,
                child: const Text(
                  'Xóa',
                  style: TextStyle(
                    color: Color(0xFF0866FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final opponent = _searchResults[index];
              return OpponentUserCard(
                user: opponent,
                onRefresh: () {
                  // Refresh search results
                  _onSearchChanged();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
