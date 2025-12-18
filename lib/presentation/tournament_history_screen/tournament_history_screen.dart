import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../tournament_detail_screen/tournament_detail_screen.dart';
// ELON_MODE_AUTO_FIX

/// Màn hình quản lý lịch sử giải đấu cho Club Owner
class TournamentHistoryScreen extends StatefulWidget {
  final String clubId;

  const TournamentHistoryScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<TournamentHistoryScreen> createState() =>
      _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends State<TournamentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allTournaments = [];
  List<Map<String, dynamic>> _filteredTournaments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSort = 'date_desc'; // date_desc, date_asc, revenue_desc, participants_desc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _filterTournaments();
    }
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      
      final response = await _supabase
          .from('tournaments')
          .select('''
            id,
            title,
            status,
            start_date,
            end_date,
            current_participants,
            max_participants,
            entry_fee,
            prize_pool,
            created_at
          ''')
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false);

      
      setState(() {
        _allTournaments = List<Map<String, dynamic>>.from(response);
        _filteredTournaments = _allTournaments;
        _isLoading = false;
      });

      _filterTournaments();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTournaments() {
    final currentTab = _tabController.index;
    List<Map<String, dynamic>> filtered = [];

    switch (currentTab) {
      case 0: // Tất cả
        filtered = List.from(_allTournaments);
        break;
      case 1: // Đã kết thúc
        filtered = _allTournaments
            .where((t) => t['status'] == 'completed')
            .toList();
        break;
      case 2: // Đang diễn ra
        filtered = _allTournaments
            .where((t) => t['status'] == 'ongoing')
            .toList();
        break;
      case 3: // Sắp diễn ra
        filtered = _allTournaments
            .where((t) => t['status'] == 'upcoming')
            .toList();
        break;
    }

    // Apply sorting
    _sortTournaments(filtered);

    setState(() {
      _filteredTournaments = filtered;
    });
  }

  void _sortTournaments(List<Map<String, dynamic>> tournaments) {
    switch (_selectedSort) {
      case 'date_desc':
        tournaments.sort((a, b) {
          final dateA = DateTime.parse(a['created_at'] ?? '');
          final dateB = DateTime.parse(b['created_at'] ?? '');
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        tournaments.sort((a, b) {
          final dateA = DateTime.parse(a['created_at'] ?? '');
          final dateB = DateTime.parse(b['created_at'] ?? '');
          return dateA.compareTo(dateB);
        });
        break;
      case 'revenue_desc':
        tournaments.sort((a, b) {
          final revenueA = _calculateRevenue(a);
          final revenueB = _calculateRevenue(b);
          return revenueB.compareTo(revenueA);
        });
        break;
      case 'participants_desc':
        tournaments.sort((a, b) {
          final participantsA = a['current_participants'] ?? 0;
          final participantsB = b['current_participants'] ?? 0;
          return participantsB.compareTo(participantsA);
        });
        break;
    }
  }

  double _calculateRevenue(Map<String, dynamic> tournament) {
    final entryFee = (tournament['entry_fee'] as num?)?.toDouble() ?? 0;
    final participants = (tournament['current_participants'] as int?) ?? 0;
    return entryFee * participants;
  }

  String _formatCurrency(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '$amount';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lịch sử giải đấu',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
                _filterTournaments();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: _selectedSort == 'date_desc'
                          ? AppTheme.primaryLight
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mới nhất',
                      style: TextStyle(
                        color: _selectedSort == 'date_desc'
                            ? AppTheme.primaryLight
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: _selectedSort == 'date_asc'
                          ? AppTheme.primaryLight
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cũ nhất',
                      style: TextStyle(
                        color: _selectedSort == 'date_asc'
                            ? AppTheme.primaryLight
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'revenue_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 18,
                      color: _selectedSort == 'revenue_desc'
                          ? AppTheme.primaryLight
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Doanh thu cao',
                      style: TextStyle(
                        color: _selectedSort == 'revenue_desc'
                            ? AppTheme.primaryLight
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'participants_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 18,
                      color: _selectedSort == 'participants_desc'
                          ? AppTheme.primaryLight
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nhiều người',
                      style: TextStyle(
                        color: _selectedSort == 'participants_desc'
                            ? AppTheme.primaryLight
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryLight,
              tabs: const [
                Tab(text: 'Tất cả'),
                Tab(text: 'Hoàn thành'),
                Tab(text: 'Đang diễn ra'),
                Tab(text: 'Sắp diễn ra'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _filteredTournaments.isEmpty
                        ? _buildEmptyView()
                        : _buildTournamentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadTournaments,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message = 'Chưa có giải đấu nào';
    IconData icon = Icons.emoji_events_outlined;

    switch (_tabController.index) {
      case 1:
        message = 'Chưa có giải đấu hoàn thành';
        break;
      case 2:
        message = 'Không có giải đấu đang diễn ra';
        break;
      case 3:
        message = 'Không có giải đấu sắp diễn ra';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList() {
    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTournaments.length,
        itemBuilder: (context, index) {
          final tournament = _filteredTournaments[index];
          return _buildTournamentCard(tournament);
        },
      ),
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final title = tournament['title'] ?? 'Giải đấu không tên';
    final status = tournament['status'] ?? 'unknown';
    final currentParticipants = tournament['current_participants'] ?? 0;
    final maxParticipants = tournament['max_participants'] ?? 0;
    final entryFee = (tournament['entry_fee'] as num?)?.toDouble() ?? 0;
    final prizePool = (tournament['prize_pool'] as num?)?.toDouble() ?? 0;
    final revenue = _calculateRevenue(tournament);
    final startDate = _formatDate(tournament['start_date']);
    final endDate = _formatDate(tournament['end_date']);

    // Status color & text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = AppTheme.successLight;
        statusText = 'Hoàn thành';
        statusIcon = Icons.check_circle;
        break;
      case 'ongoing':
        statusColor = AppTheme.accentLight;
        statusText = 'Đang diễn ra';
        statusIcon = Icons.play_circle;
        break;
      case 'upcoming':
        statusColor = AppTheme.warningLight;
        statusText = 'Sắp diễn ra';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không rõ';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TournamentDetailScreen(),
              settings: RouteSettings(
                arguments: tournament['id'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.people,
                      'Người tham gia',
                      '$currentParticipants/$maxParticipants',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.monetization_on,
                      'Doanh thu',
                      '${_formatCurrency(revenue)} VND',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.card_giftcard,
                      'Giải thưởng',
                      '${_formatCurrency(prizePool)} VND',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.payments,
                      'Phí tham gia',
                      '${_formatCurrency(entryFee)} VND',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      '$startDate - $endDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

