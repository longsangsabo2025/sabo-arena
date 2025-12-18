class UserSocialStats {
  final int followersCount;
  final int followingCount;
  final int challengesCount;
  final int tournamentsCount;
  final int ranking;
  final int likesCount;

  const UserSocialStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.challengesCount = 0,
    this.tournamentsCount = 0,
    this.ranking = 0,
    this.likesCount = 0,
  });

  UserSocialStats copyWith({
    int? followersCount,
    int? followingCount,
    int? challengesCount,
    int? tournamentsCount,
    int? ranking,
    int? likesCount,
  }) {
    return UserSocialStats(
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      challengesCount: challengesCount ?? this.challengesCount,
      tournamentsCount: tournamentsCount ?? this.tournamentsCount,
      ranking: ranking ?? this.ranking,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}
