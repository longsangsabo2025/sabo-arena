enum TournamentTabStatus {
  upcoming,
  live,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case TournamentTabStatus.upcoming:
        return 'upcoming';
      case TournamentTabStatus.live:
        return 'ongoing';
      case TournamentTabStatus.completed:
        return 'completed';
      case TournamentTabStatus.cancelled:
        return 'cancelled';
    }
  }

  static TournamentTabStatus fromString(String value) {
    switch (value) {
      case 'upcoming':
        return TournamentTabStatus.upcoming;
      case 'live':
      case 'ongoing':
        return TournamentTabStatus.live;
      case 'completed':
        return TournamentTabStatus.completed;
      case 'cancelled':
        return TournamentTabStatus.cancelled;
      default:
        return TournamentTabStatus.upcoming;
    }
  }

  String get displayName {
    switch (this) {
      case TournamentTabStatus.upcoming:
        return 'Sắp diễn ra';
      case TournamentTabStatus.live:
        return 'Đang diễn ra';
      case TournamentTabStatus.completed:
        return 'Đã kết thúc';
      case TournamentTabStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
