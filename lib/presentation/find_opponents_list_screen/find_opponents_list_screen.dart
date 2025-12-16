import 'package:flutter/material.dart';
import '../../services/opponent_matching_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/loading_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import './widgets/opponent_user_card.dart';

/// Screen hiển thị danh sách đối thủ được đề xuất (Facebook style)
class FindOpponentsListScreen extends StatefulWidget {
  const FindOpponentsListScreen({super.key});

  @override
  State<FindOpponentsListScreen> createState() =>
      _FindOpponentsListScreenState();
}

class _FindOpponentsListScreenState extends State<FindOpponentsListScreen> {
  final OpponentMatchingService _matchingService =
      OpponentMatchingService.instance;
  List<UserProfile> _opponents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOpponents();
  }

  Future<void> _loadOpponents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final opponents = await _matchingService.findMatchedOpponents(
        radiusKm: 50, // Default 50km
        rankFilter: null, // All ranks
      );

      if (mounted) {
        setState(() {
          _opponents = opponents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF050505)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm đối thủ', overflow: TextOverflow.ellipsis, style: TextStyle(
            color: Color(0xFF050505),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tìm đối thủ phù hợp...');
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage,
        onRetry: _loadOpponents,
      );
    }

    if (_opponents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.person_search,
        message: 'Không tìm thấy đối thủ',
        subtitle: 'Thử mở rộng phạm vi tìm kiếm hoặc thử lại sau',
        actionLabel: 'Làm mới',
        onAction: _loadOpponents,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOpponents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _opponents.length,
        itemBuilder: (context, index) {
          final opponent = _opponents[index];
          return OpponentUserCard(user: opponent, onRefresh: _loadOpponents);
        },
      ),
    );
  }
}
