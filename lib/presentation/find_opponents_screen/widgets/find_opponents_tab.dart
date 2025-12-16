import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/opponent_matching_service.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import './player_card_widget.dart';

/// Tab to find and display available opponents (Tìm đối thủ)
class FindOpponentsTab extends StatefulWidget {
  const FindOpponentsTab({super.key});

  @override
  State<FindOpponentsTab> createState() => _FindOpponentsTabState();
}

class _FindOpponentsTabState extends State<FindOpponentsTab> {
  final OpponentMatchingService _matchingService =
      OpponentMatchingService.instance;
  List<UserProfile> _opponents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedRank = 'all';
  double _radiusKm = 50.0;

  @override
  void initState() {
    super.initState();
    _loadOpponents();
  }

  Future<void> _loadOpponents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final opponents = await _matchingService.findMatchedOpponents(
        radiusKm: _radiusKm,
        rankFilter: _selectedRank,
      );

      if (mounted) {
        setState(() {
          _opponents = opponents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rank Filter
          const Text(
            'Hạng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _matchingService.getRankOptions().map((rank) {
              final isSelected = _selectedRank == rank;
              return FilterChip(
                label: Text(rank == 'all' ? 'Tất cả' : rank),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedRank = rank);
                  Navigator.pop(context);
                  _loadOpponents();
                },
                selectedColor: const Color(0xFF0866FF).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF0866FF),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Distance Filter
          const Text(
            'Khoảng cách',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: '${_radiusKm.toInt()} km',
                  onChanged: (value) {
                    setState(() => _radiusKm = value);
                  },
                  onChangeEnd: (value) {
                    Navigator.pop(context);
                    _loadOpponents();
                  },
                ),
              ),
              Text(
                '${_radiusKm.toInt()} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Color(0xFF65676B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedRank == 'all'
                        ? 'Tất cả hạng • ${_radiusKm.toInt()} km'
                        : '$_selectedRank • ${_radiusKm.toInt()} km',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF050505),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showFilterSheet,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Lọc'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0866FF),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tìm đối thủ phù hợp...');
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadOpponents,
      );
    }

    if (_opponents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        message: 'Không tìm thấy đối thủ',
        subtitle: 'Thử điều chỉnh bộ lọc để tìm thêm người chơi',
        actionLabel: 'Làm mới',
        onAction: _loadOpponents,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOpponents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _opponents.length,
        itemBuilder: (context, index) {
          final opponent = _opponents[index];
          return PlayerCardWidget(
            player: opponent,
            mode: 'giao_luu', // Default mode for finding opponents
          );
        },
      ),
    );
  }
}
