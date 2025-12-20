import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sabo_arena/models/tournament.dart';

class TournamentInfoWidget extends StatelessWidget {
  final Tournament tournament;

  const TournamentInfoWidget({super.key, required this.tournament});

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'open':
        return 'Đang mở đăng ký';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String _getSkillLevelDisplay() {
    // If both minRank and maxRank are specified, show range
    if (tournament.minRank != null && tournament.maxRank != null) {
      if (tournament.minRank == tournament.maxRank) {
        return 'Hạng ${tournament.minRank}';
      }
      return 'Hạng ${tournament.minRank} - ${tournament.maxRank}';
    }

    // If only minRank is specified
    if (tournament.minRank != null) {
      return 'Hạng ${tournament.minRank} trở lên';
    }

    // If only maxRank is specified
    if (tournament.maxRank != null) {
      return 'Hạng ${tournament.maxRank} trở xuống';
    }

    // Fallback to skillLevelRequired or default
    return tournament.skillLevelRequired ?? 'Tất cả trình độ';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Thông tin giải đấu',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF050505),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          // Info grid - 2 columns
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Row 1: Thời gian + Số lượng
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        dateFormat.format(tournament.startDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.people,
                        '${tournament.currentParticipants}/${tournament.maxParticipants} người',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: Hình thức + Trạng thái
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.emoji_events,
                        _getTournamentTypeDisplay(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.info_outline,
                        _getStatusDisplay(tournament.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 3: Lệ phí + Yêu cầu
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.payment,
                        tournament.entryFee == 0
                            ? 'Miễn phí'
                            : currencyFormat.format(tournament.entryFee),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.military_tech,
                        _getSkillLevelDisplay(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 4: Location
                _buildInfoItem(
                  Icons.location_on,
                  tournament.venueAddress ?? 'Chưa cập nhật địa điểm',
                ),
                if (tournament.venuePhone != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.phone,
                    '${tournament.venueContact ?? "Liên hệ"}: ${tournament.venuePhone}',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mô tả',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tournament.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF65676B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0866FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF050505),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Get formatted tournament type display
  String _getTournamentTypeDisplay() {
    final type = tournament.tournamentType.toLowerCase();
    switch (type) {
      case 'single_elimination':
        return 'Loại trực tiếp';
      case 'double_elimination':
        return 'Nhánh thắng thua';
      case 'round_robin':
        return 'Vòng tròn';
      case 'swiss':
      case 'swiss_system':
        return 'Swiss System';
      case 'sabo_de8':
        return 'SABO DE8 (8 người)';
      case 'sabo_de16':
        return 'SABO DE16 (16 người)';
      case 'sabo_de32':
        return 'SABO DE32 (32 người)';
      case 'sabo_de64':
        return 'SABO DE64 (64 người)';
      default:
        // Fallback for unknown formats
        return tournament.tournamentType;
    }
  }
}
