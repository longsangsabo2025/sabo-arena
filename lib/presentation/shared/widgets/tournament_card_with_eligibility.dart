import 'package:flutter/material.dart';
import '../../../models/tournament.dart';
import '../../../models/tournament_eligibility.dart';
import '../../../services/tournament_eligibility_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/tournament/eligibility_status_card.dart';
import './tournament_card_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Wrapper for TournamentCardWidget with eligibility badge
class TournamentCardWithEligibility extends StatefulWidget {
  final Tournament tournament;
  final Map<String, dynamic> tournamentCardData;
  final VoidCallback? onTap;
  final VoidCallback? onResultTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onShareTap;

  const TournamentCardWithEligibility({
    super.key,
    required this.tournament,
    required this.tournamentCardData,
    this.onTap,
    this.onResultTap,
    this.onDetailTap,
    this.onShareTap,
  });

  @override
  State<TournamentCardWithEligibility> createState() =>
      _TournamentCardWithEligibilityState();
}

class _TournamentCardWithEligibilityState
    extends State<TournamentCardWithEligibility> {
  EligibilityResult? _eligibilityResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    try {
      final user = await UserService.instance.getCurrentUserProfile();
      
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // Check if user is registered (you may need to add this check)
      // For now, assume not registered
      final result = TournamentEligibilityService.checkEligibility(
        tournament: widget.tournament,
        user: user,
        isAlreadyRegistered: false,
      );

      if (mounted) {
        setState(() {
          _eligibilityResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TournamentCardWidget(
      tournament: widget.tournamentCardData,
      onTap: () {
        // Check eligibility before allowing tap action
        if (!_isLoading && _eligibilityResult != null && !_eligibilityResult!.isEligible) {
          // Show eligibility dialog if not eligible
          _showEligibilityDialog(context);
        } else {
          // Allow normal tap action if eligible or still loading
          widget.onTap?.call();
        }
      },
      onResultTap: widget.onResultTap,
      onDetailTap: widget.onDetailTap,
      onShareTap: widget.onShareTap,
    );
  }

  void _showEligibilityDialog(BuildContext context) {
    if (_eligibilityResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: EligibilityStatusCard(
            result: _eligibilityResult!,
            onActionPressed: () {
              Navigator.pop(context);
              final route = _eligibilityResult!.primaryIssue?.actionRoute;
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
          ),
        ),
      ),
    );
  }
}

