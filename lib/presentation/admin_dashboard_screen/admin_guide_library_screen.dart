import 'package:flutter/material.dart';
import '../../models/admin_guide_models.dart';
import '../../services/admin_guide_service.dart';
import '../../theme/app_theme.dart';
import 'admin_guide_viewer_screen.dart';

/// Admin Guide Library - Browse and search all guides
class AdminGuideLibraryScreen extends StatefulWidget {
  const AdminGuideLibraryScreen({super.key});

  @override
  State<AdminGuideLibraryScreen> createState() =>
      _AdminGuideLibraryScreenState();
}

class _AdminGuideLibraryScreenState extends State<AdminGuideLibraryScreen> {
  final _guideService = AdminGuideService();
  final _searchController = TextEditingController();

  List<AdminGuide> _guides = [];
  List<AdminGuide> _filteredGuides = [];
  bool _isLoading = true;
  GuideCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuides() async {
    setState(() => _isLoading = true);
    try {
      final guides = await _guideService.getAllGuides(forceRefresh: true);
      setState(() {
        _guides = guides;
        _filteredGuides = guides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải guides: $e')));
      }
    }
  }

  void _filterGuides() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuides = _guides.where((guide) {
        final matchesSearch = query.isEmpty ||
            guide.title.toLowerCase().contains(query) ||
            guide.description.toLowerCase().contains(query) ||
            guide.tags.any((tag) => tag.toLowerCase().contains(query));

        final matchesCategory =
            _selectedCategory == null || guide.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Hướng dẫn Admin'),
        backgroundColor: AppTheme.primaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGuides,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          _buildSearchAndFilter(),

          // Category Chips
          _buildCategoryChips(),

          // Guides List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGuides.isEmpty
                    ? _buildEmptyState()
                    : _buildGuidesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm hướng dẫn...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterGuides();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) => _filterGuides(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip(null, 'Tất cả', Icons.all_inclusive),
          ...GuideCategory.values.map((category) {
            return _buildCategoryChip(
              category,
              _getCategoryName(category),
              _getCategoryIcon(category),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    GuideCategory? category,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _filterGuides();
        },
        selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildGuidesList() {
    // Group by category
    final groupedGuides = <GuideCategory, List<AdminGuide>>{};
    for (final guide in _filteredGuides) {
      groupedGuides.putIfAbsent(guide.category, () => []).add(guide);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedGuides.length,
      itemBuilder: (context, index) {
        final category = groupedGuides.keys.elementAt(index);
        final guides = groupedGuides[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(category), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${guides.length}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Guides in category
            ...guides.map((guide) => _buildGuideCard(guide)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGuideCard(AdminGuide guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openGuide(guide),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // NEW badge
                  if (guide.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MỚI',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                guide.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Metadata
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${guide.estimatedMinutes} phút',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${guide.steps.length} bước',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Tags
              if (guide.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: guide.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy hướng dẫn',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _openGuide(AdminGuide guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminGuideViewerScreen(guide: guide),
      ),
    );
  }

  String _getCategoryName(GuideCategory category) {
    switch (category) {
      case GuideCategory.gettingStarted:
        return 'Bắt đầu';
      case GuideCategory.clubManagement:
        return 'Quản lý CLB';
      case GuideCategory.tournamentManagement:
        return 'Giải đấu';
      case GuideCategory.userManagement:
        return 'Người dùng';
      case GuideCategory.notifications:
        return 'Thông báo';
      case GuideCategory.analytics:
        return 'Phân tích';
      case GuideCategory.advanced:
        return 'Nâng cao';
    }
  }

  IconData _getCategoryIcon(GuideCategory category) {
    switch (category) {
      case GuideCategory.gettingStarted:
        return Icons.rocket_launch;
      case GuideCategory.clubManagement:
        return Icons.business;
      case GuideCategory.tournamentManagement:
        return Icons.emoji_events;
      case GuideCategory.userManagement:
        return Icons.people;
      case GuideCategory.notifications:
        return Icons.notifications;
      case GuideCategory.analytics:
        return Icons.analytics;
      case GuideCategory.advanced:
        return Icons.settings;
    }
  }
}
