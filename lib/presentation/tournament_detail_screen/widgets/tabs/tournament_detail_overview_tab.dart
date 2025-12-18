import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../models/tournament.dart';
import '../../../../models/tournament_eligibility.dart';
import '../../../../widgets/tournament/eligibility_status_card.dart';
import '../tournament_info_widget.dart';
import '../prize_pool_widget.dart';
import '../registration_widget.dart';

class TournamentDetailOverviewTab extends StatelessWidget {
  final EligibilityResult? eligibilityResult;
  final Tournament tournament;
  final bool isRegistered;
  final VoidCallback? onRegisterTap;
  final Function(String)? onRegisterWithPayment;
  final VoidCallback? onWithdrawTap;

  const TournamentDetailOverviewTab({
    super.key,
    this.eligibilityResult,
    required this.tournament,
    required this.isRegistered,
    this.onRegisterTap,
    this.onRegisterWithPayment,
    this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Gaps.lg),
      child: Column(
        children: [
          const SizedBox(height: Gaps.lg),
          
          // Eligibility Status Card
          if (eligibilityResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EligibilityStatusCard(
                result: eligibilityResult!,
                onActionPressed: () {
                  final primaryIssue = eligibilityResult!.primaryIssue;
                  if (primaryIssue?.actionRoute != null) {
                    Navigator.pushNamed(context, primaryIssue!.actionRoute!);
                  }
                },
              ),
            ),
          
          if (eligibilityResult != null) const SizedBox(height: Gaps.lg),
          
          TournamentInfoWidget(tournament: tournament),
          const SizedBox(height: Gaps.lg),
          PrizePoolWidget(tournament: tournament),
          const SizedBox(height: Gaps.lg),
          RegistrationWidget(
            tournament: tournament,
            isRegistered: isRegistered,
            onRegisterTap: onRegisterTap,
            onRegisterWithPayment: onRegisterWithPayment,
            onWithdrawTap: onWithdrawTap,
          ),
        ],
      ),
    );
  }
}
