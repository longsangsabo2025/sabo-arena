import 'package:flutter/material.dart';
// import '../../../../core/app_export.dart' hide AppColors;
import '../../../../core/design_system/design_system.dart';
import '../../../../models/tournament.dart';
import '../tournament_card_widget.dart';

class UserProfileTournamentsTab extends StatelessWidget {
  final List<Tournament> tournaments;
  final String currentTab;
  final Function(String, {bool showResults}) onTournamentTap;
  final Function(Tournament) onShareTap;

  const UserProfileTournamentsTab({
    super.key,
    required this.tournaments,
    required this.currentTab,
    required this.onTournamentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppColors.gray300,
              ),
              const SizedBox(height: 16),
              Text(
                currentTab == 'ready'
                    ? 'Không có giải đấu sắp diễn ra'
                    : currentTab == 'live'
                    ? 'Không có giải đấu đang diễn ra'
                    : 'Không có giải đấu đã hoàn thành',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tournament = tournaments[index];
        final tournamentId = tournament.id;
        final status = tournament.status;

        return TournamentCardWidget(
          tournamentObj: tournament,
          onTap: () {
            if (tournamentId.isNotEmpty) {
              onTournamentTap(tournamentId);
            }
          },
          onResultTap: () {
            if (tournamentId.isNotEmpty && (status == 'completed' || status == 'done')) {
              onTournamentTap(tournamentId, showResults: true);
            }
          },
          onDetailTap: () {
            if (tournamentId.isNotEmpty && (status == 'upcoming' || status == 'ready')) {
              onTournamentTap(tournamentId);
            }
          },
          onShareTap: () => onShareTap(tournament),
        );
      }, childCount: tournaments.length),
    );
  }
}
