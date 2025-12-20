import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/tournament.dart';
import '../../../../models/club.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/production_logger.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../shared/widgets/tournament_card_widget.dart';

class ClubTournamentsTab extends StatelessWidget {
  final Club club;
  final List<Tournament> tournaments;
  final bool isLoading;
  final String? error;
  final String filter;
  final bool isClubOwner;
  final Function(String) onFilterChanged;
  final VoidCallback onRefresh;
  final Function(Tournament) onDeleteTournament;
  final Function(Tournament) onHideTournament;

  const ClubTournamentsTab({
    super.key,
    required this.club,
    required this.tournaments,
    required this.isLoading,
    this.error,
    required this.filter,
    required this.isClubOwner,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onDeleteTournament,
    required this.onHideTournament,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter tournaments based on selected filter
    final filteredTournaments = filter == 'Tất cả'
        ? tournaments
        : tournaments.where((t) {
            switch (filter) {
              case 'Sắp tới':
                return t.status == 'upcoming';
              case 'Đang diễn ra':
                return t.status == 'ongoing';
              case 'Đã kết thúc':
                return t.status == 'completed' || t.status == 'done';
              default:
                return true;
            }
          }).toList();

    // Show loading state
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Không thể tải giải đấu',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Thử lại',
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
                icon: Icons.refresh,
                iconTrailing: false,
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', filter == 'Tất cả', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Sắp tới', filter == 'Sắp tới', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip(
                  'Đang diễn ra', filter == 'Đang diễn ra', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip(
                  'Đã kết thúc', filter == 'Đã kết thúc', colorScheme),
            ],
          ),
        ),

        // Tournaments list
        Expanded(
          child: filteredTournaments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter == 'Tất cả'
                              ? 'Chưa có giải đấu nào'
                              : 'Không có giải đấu $filter',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: filteredTournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = filteredTournaments[index];
                    final cardData = _convertTournamentToCardData(tournament);

                    // Show delete button if user is club owner
                    return Stack(
                      children: [
                        TournamentCardWidget(
                          tournamentMap: cardData,
                          onTap: () {
                            ProductionLogger.info(
                                '🎯 Tournament tapped: ${tournament.id} - ${tournament.title}',
                                tag: 'club_detail_section');
                            // Navigate to tournament detail (tap on card)
                            Navigator.pushNamed(
                              context,
                              AppRoutes.tournamentDetailScreen,
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                              },
                            );
                          },
                          onDetailTap: () {
                            ProductionLogger.info(
                                '🎯 Tournament detail button tapped: ${tournament.id}',
                                tag: 'club_detail_section');
                            // Navigate to tournament detail (tap on Detail button)
                            Navigator.pushNamed(
                              context,
                              AppRoutes.tournamentDetailScreen,
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                              },
                            );
                          },
                          onResultTap: () {
                            ProductionLogger.info(
                                '🎯 Tournament result button tapped: ${tournament.id}',
                                tag: 'club_detail_section');
                            // Navigate to tournament results (tap on Kết quả button)
                            Navigator.pushNamed(
                              context,
                              AppRoutes.tournamentDetailScreen,
                              arguments: {
                                'tournamentId': tournament.id,
                                'tournament': tournament,
                                'showResults': true,
                              },
                            );
                          },
                          onShareTap: () {
                            // TODO: Implement share tournament
                          },
                          onDelete: isClubOwner
                              ? () => onDeleteTournament(tournament)
                              : null,
                          onHide: isClubOwner
                              ? () => onHideTournament(tournament)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(label);
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color:
            isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }

  /// Convert Tournament model to TournamentCardWidget format
  Map<String, dynamic> _convertTournamentToCardData(Tournament tournament) {
    // Determine icon number from game format (8-ball, 9-ball, 10-ball)
    String iconNumber = '9'; // Default
    final gameFormat = tournament.format.toLowerCase();
    if (gameFormat.contains('8')) {
      iconNumber = '8';
    } else if (gameFormat.contains('9')) {
      iconNumber = '9';
    } else if (gameFormat.contains('10')) {
      iconNumber = '10';
    }

    // Format date
    String dateStr = '';
    final weekday = [
      'CN',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7'
    ][tournament.startDate.weekday % 7];
    dateStr = '${DateFormat('dd/MM').format(tournament.startDate)} - $weekday';

    // Format time
    String timeStr = DateFormat('HH:mm').format(tournament.startDate);

    // Format players count
    String playersCount =
        '${tournament.currentParticipants}/${tournament.maxParticipants}';

    // Prize pool (convert double to formatted string)
    String prizePool = tournament.prizePool > 0
        ? '${(tournament.prizePool / 1000000).toStringAsFixed(1)}M VNĐ'
        : 'Chưa có';

    // Rating/Rank requirement - use minRank/maxRank
    String rating;
    if (tournament.minRank != null && tournament.maxRank != null) {
      if (tournament.minRank == tournament.maxRank) {
        rating = 'Hạng ${tournament.minRank}';
      } else {
        rating = 'Hạng ${tournament.minRank} - ${tournament.maxRank}';
      }
    } else if (tournament.minRank != null) {
      rating = 'Hạng ${tournament.minRank}+';
    } else if (tournament.maxRank != null) {
      rating = 'Hạng ${tournament.maxRank}-';
    } else {
      rating = tournament.skillLevelRequired ?? 'Tất cả';
    }

    // Mạng count (use 2 as default since not in model)
    int mangCount = 2;

    // Is live?
    bool isLive = tournament.status == 'ongoing';

    // ✅ Get prize breakdown from prize_distribution
    Map<String, String>? prizeBreakdown;
    final prizeDistribution = tournament.prizeDistribution;
    if (prizeDistribution != null) {
      // Check for text-based format (first, second, third keys)
      if (prizeDistribution.containsKey('first') &&
          prizeDistribution['first'] is String) {
        prizeBreakdown = {
          'first': prizeDistribution['first'] as String,
          if (prizeDistribution['second'] != null)
            'second': prizeDistribution['second'] as String,
          if (prizeDistribution['third'] != null)
            'third': prizeDistribution['third'] as String,
        };
      }
    }

    return {
      'name': tournament.title,
      'date': dateStr,
      'startTime': timeStr,
      'playersCount': playersCount,
      'prizePool': prizePool,
      'prizeBreakdown': prizeBreakdown,
      'rating': rating,
      'iconNumber': iconNumber,
      'clubLogo': club.logoUrl,
      'clubName': club.name,
      'mangCount': mangCount,
      'isLive': isLive,
      'status': tournament.status,
      'tournamentType': tournament.tournamentType,
      // 🚀 ELON STYLE: Pass missing fields for smart badge logic
      'registrationDeadline': tournament.registrationDeadline.toIso8601String(),
      'entryFee':
          tournament.entryFee > 0 ? '${tournament.entryFee} VNĐ' : 'Miễn phí',
      'venue': tournament.venueAddress ?? club.address,
    };
  }
}
