class ClubDashboardStats {
  final int totalMembers;
  final int activeMembers;
  final double monthlyRevenue;
  final int totalTournaments;
  final int tournaments;
  final int ranking;

  ClubDashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.monthlyRevenue,
    required this.totalTournaments,
    required this.tournaments,
    required this.ranking,
  });

  factory ClubDashboardStats.empty() {
    return ClubDashboardStats(
      totalMembers: 0,
      activeMembers: 0,
      monthlyRevenue: 0.0,
      totalTournaments: 0,
      tournaments: 0,
      ranking: 0,
    );
  }
}
