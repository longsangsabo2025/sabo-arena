import 'package:flutter/material.dart';

class TournamentInfoWidget extends StatelessWidget {
  final Map<String, dynamic> tournament;

  const TournamentInfoWidget({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
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
                        '${tournament["startDate"]}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.people,
                        '${tournament["currentParticipants"]}/${tournament["maxParticipants"]} người',
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
                        tournament["eliminationType"] as String,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.info_outline,
                        tournament["status"] as String,
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
                        tournament["entryFee"] as String,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.military_tech,
                        tournament["rankRequirement"] as String,
                      ),
                    ),
                  ],
                ),
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
                  tournament["description"] as String,
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
}
