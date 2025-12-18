import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../models/tournament.dart';
import '../tournament_rankings_widget.dart';

class TournamentDetailResultsTab extends StatelessWidget {
  final String? tournamentId;
  final Tournament? tournament;

  const TournamentDetailResultsTab({
    super.key,
    this.tournamentId,
    this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    if (tournamentId == null) {
      return const Center(child: Text('Không có thông tin giải đấu'));
    }

    // Remove SingleChildScrollView - let TournamentRankingsWidget handle its own scrolling
    return Padding(
      padding: const EdgeInsets.all(Gaps.lg),
      child: TournamentRankingsWidget(
        tournamentId: tournamentId!,
        tournamentStatus: tournament?.status ?? 'not_started',
      ),
    );
  }
}
