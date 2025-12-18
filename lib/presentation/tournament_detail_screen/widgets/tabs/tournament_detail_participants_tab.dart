import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../models/user_profile.dart';
import '../participants_list_widget.dart';

class TournamentDetailParticipantsTab extends StatelessWidget {
  final List<UserProfile> participants;
  final VoidCallback? onViewAllTap;

  const TournamentDetailParticipantsTab({
    super.key,
    required this.participants,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Gaps.lg),
      child: Column(
        children: [
          const SizedBox(height: Gaps.lg),
          ParticipantsListWidget(
            participants: participants,
            onViewAllTap: onViewAllTap,
          ),
        ],
      ),
    );
  }
}
