import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../models/tournament.dart';
import '../../../../models/tournament_tab_status.dart';
import '../../../../services/tournament_service.dart';
import '../tournament_card_widget.dart';

class UserProfileTournamentsTab extends StatefulWidget {
  final String currentTab;
  final Function(String, {bool showResults}) onTournamentTap;
  final Function(Tournament) onShareTap;

  const UserProfileTournamentsTab({
    super.key,
    required this.currentTab,
    required this.onTournamentTap,
    required this.onShareTap,
  });

  @override
  State<UserProfileTournamentsTab> createState() =>
      _UserProfileTournamentsTabState();
}

class _UserProfileTournamentsTabState extends State<UserProfileTournamentsTab> {
  final TournamentService _tournamentService = TournamentService.instance;
  final PagingController<int, Tournament> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchTournamentsPage);
  }

  @override
  void didUpdateWidget(UserProfileTournamentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _pagingController.refresh();
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournamentsPage(int pageKey) async {
    try {
      final status = widget.currentTab == 'live'
          ? TournamentTabStatus.live
          : widget.currentTab == 'done'
              ? TournamentTabStatus.completed
              : TournamentTabStatus.upcoming;

      final tournaments = await _tournamentService.getTournaments(
        status: status,
        page: pageKey,
        pageSize: 15,
      );

      final isLastPage = tournaments.length < 15;
      if (isLastPage) {
        _pagingController.appendLastPage(tournaments);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(tournaments, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, Tournament>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<Tournament>(
        itemBuilder: (context, tournament, index) {
          final tournamentId = tournament.id;
          final status = tournament.status;

          return TournamentCardWidget(
            tournamentObj: tournament,
            onTap: () {
              if (tournamentId.isNotEmpty) {
                widget.onTournamentTap(tournamentId);
              }
            },
            onResultTap: () {
              if (tournamentId.isNotEmpty &&
                  (status == 'completed' || status == 'done')) {
                widget.onTournamentTap(tournamentId, showResults: true);
              }
            },
            onDetailTap: () {
              if (tournamentId.isNotEmpty &&
                  (status == 'upcoming' || status == 'ready')) {
                widget.onTournamentTap(tournamentId);
              }
            },
            onShareTap: () => widget.onShareTap(tournament),
          );
        },
        firstPageProgressIndicatorBuilder: (context) =>
            const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        newPageProgressIndicatorBuilder: (context) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        firstPageErrorIndicatorBuilder: (context) => SliverToBoxAdapter(
          child: Container(
            height: 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải giải đấu',
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        noItemsFoundIndicatorBuilder: (context) => SliverToBoxAdapter(
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
                  widget.currentTab == 'ready'
                      ? 'Không có giải đấu sắp diễn ra'
                      : widget.currentTab == 'live'
                          ? 'Không có giải đấu đang diễn ra'
                          : 'Không có giải đấu đã hoàn thành',
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
