import 'package:flutter/material.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../models/tournament.dart';
import '../../../../utils/production_logger.dart';
import '../tournament_rules_widget.dart';

class TournamentDetailRulesTab extends StatelessWidget {
  final Tournament? tournament;
  final List<String> defaultRules;

  const TournamentDetailRulesTab({
    super.key,
    this.tournament,
    required this.defaultRules,
  });

  @override
  Widget build(BuildContext context) {
    List<String> rules = [];

    // Try to get rules from tournament
    if (tournament?.rules != null && tournament!.rules!.trim().isNotEmpty) {
      // Split rules by newline and clean them
      rules = tournament!.rules!
          .split('\n')
          .map((rule) => rule.trim())
          .where((rule) => rule.isNotEmpty)
          .map((rule) {
        // Remove bullet point if it exists
        if (rule.startsWith('•')) {
          return rule.substring(1).trim();
        }
        return rule;
      }).toList();

      ProductionLogger.info(
          '📋 Loaded ${rules.length} rules from tournament data',
          tag: 'TournamentDetailRulesTab');
    }

    // Try special rules if main rules is empty
    if (rules.isEmpty &&
        tournament?.specialRules != null &&
        tournament!.specialRules!.trim().isNotEmpty) {
      rules = tournament!.specialRules!
          .split('\n')
          .map((rule) => rule.trim())
          .where((rule) => rule.isNotEmpty)
          .toList();

      ProductionLogger.info(
          '📋 Loaded ${rules.length} rules from special rules',
          tag: 'TournamentDetailRulesTab');
    }

    // Fallback to default rules if still empty
    if (rules.isEmpty) {
      rules = defaultRules;
      ProductionLogger.info('📋 Using ${rules.length} default fallback rules',
          tag: 'TournamentDetailRulesTab');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Gaps.lg),
      child: Column(
        children: [
          const SizedBox(height: Gaps.lg),
          TournamentRulesWidget(rules: rules),
        ],
      ),
    );
  }
}
