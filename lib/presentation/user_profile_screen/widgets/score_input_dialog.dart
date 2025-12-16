import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog để CLB owner nhập tỷ số cho trận đấu
class ScoreInputDialog extends StatefulWidget {
  final Map<String, dynamic> match;

  const ScoreInputDialog({
    super.key,
    required this.match,
  });

  @override
  State<ScoreInputDialog> createState() => _ScoreInputDialogState();
}

class _ScoreInputDialogState extends State<ScoreInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _player1ScoreController;
  late TextEditingController _player2ScoreController;
  bool _isLoading = false;
  String? _winnerId;
  
  // Debounce timer để tránh lag khi nhập
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with current scores if any
    final p1Score = widget.match['player1_score'] ?? widget.match['player1Score'] ?? 0;
    final p2Score = widget.match['player2_score'] ?? widget.match['player2Score'] ?? 0;
    
    _player1ScoreController = TextEditingController(text: p1Score.toString());
    _player2ScoreController = TextEditingController(text: p2Score.toString());
    
    // Dùng listener thay vì onChanged để tránh rebuild liên tục
    _player1ScoreController.addListener(_onScoreChanged);
    _player2ScoreController.addListener(_onScoreChanged);
    
    _calculateWinner();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _player1ScoreController.removeListener(_onScoreChanged);
    _player2ScoreController.removeListener(_onScoreChanged);
    _player1ScoreController.dispose();
    _player2ScoreController.dispose();
    super.dispose();
  }
  
  // Debounce để chỉ update sau 300ms không nhập
  void _onScoreChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _calculateWinner());
      }
    });
  }

  void _calculateWinner() {
    final p1Score = int.tryParse(_player1ScoreController.text) ?? 0;
    final p2Score = int.tryParse(_player2ScoreController.text) ?? 0;

    if (p1Score > p2Score) {
      _winnerId = widget.match['player1_id'] ?? widget.match['player1Id'];
    } else if (p2Score > p1Score) {
      _winnerId = widget.match['player2_id'] ?? widget.match['player2Id'];
    } else {
      _winnerId = null; // Draw
    }
  }

  Future<void> _submitScore() async {
    if (!_formKey.currentState!.validate()) return;

    final p1Score = int.parse(_player1ScoreController.text);
    final p2Score = int.parse(_player2ScoreController.text);

    // Validate scores
    if (p1Score == 0 && p2Score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tỷ số không thể là 0-0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Return result to parent
      Navigator.pop(context, {
        'player1Score': p1Score,
        'player2Score': p2Score,
        'winnerId': _winnerId,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Helper function to get player name with intelligent fallback
    String _getPlayerName(Map<String, dynamic>? playerData, String fallbackLabel) {
      if (playerData == null) return fallbackLabel;
      
      // Try display_name first (preferred)
      if (playerData['display_name'] != null && playerData['display_name'].toString().trim().isNotEmpty) {
        return playerData['display_name'];
      }
      
      // Try full_name
      if (playerData['full_name'] != null && playerData['full_name'].toString().trim().isNotEmpty) {
        return playerData['full_name'];
      }
      
      // Try username
      if (playerData['username'] != null && playerData['username'].toString().trim().isNotEmpty) {
        return '@${playerData['username']}';
      }
      
      // Try email (show first part before @)
      if (playerData['email'] != null) {
        final email = playerData['email'].toString();
        if (email.contains('@')) {
          return email.split('@')[0];
        }
      }
      
      // Last resort: show partial ID
      if (playerData['id'] != null) {
        final id = playerData['id'].toString();
        return 'User ${id.substring(0, 8)}...';
      }
      
      return fallbackLabel;
    }
    
    // Try multiple field names for player 1 (with cascading fallback)
    String player1Name = widget.match['player1Name']?.toString() ?? '';
    if (player1Name.isEmpty) {
      final player1Data = widget.match['player1'] ?? widget.match['challenger'];
      player1Name = _getPlayerName(player1Data, 'Player 1');
    }
    
    // Try multiple field names for player 2 (with cascading fallback)
    String player2Name = widget.match['player2Name']?.toString() ?? '';
    if (player2Name.isEmpty) {
      final player2Data = widget.match['player2'] ?? widget.match['challenged'];
      player2Name = _getPlayerName(player2Data, 'Player 2');
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF00695C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập tỷ số',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cập nhật kết quả trận đấu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF757575),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // Player 1 Score
              _buildScoreInput(
                label: player1Name,
                controller: _player1ScoreController,
              ),
              const SizedBox(height: 16),

              // VS Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Player 2 Score
              _buildScoreInput(
                label: player2Name,
                controller: _player2ScoreController,
              ),
              const SizedBox(height: 24),

              // Winner indicator
              if (_winnerId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Người thắng: ${_winnerId == (widget.match['player1_id'] ?? widget.match['player1Id']) ? player1Name : player2Name}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.handshake,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kết quả: Hòa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitScore,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF00695C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Lưu tỷ số',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Decrement button
            _buildCounterButton(
              icon: Icons.remove,
              onTap: () {
                final current = int.tryParse(controller.text) ?? 0;
                if (current > 0) {
                  controller.text = (current - 1).toString();
                  // Listener sẽ tự động trigger update
                }
              },
            ),
            const SizedBox(width: 12),
            // Score input
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF00695C),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nhập tỷ số';
                  }
                  final score = int.tryParse(value);
                  if (score == null || score < 0) {
                    return 'Tỷ số không hợp lệ';
                  }
                  return null;
                },
                // Bỏ onChanged để tránh rebuild liên tục
              ),
            ),
            const SizedBox(width: 12),
            // Increment button
            _buildCounterButton(
              icon: Icons.add,
              onTap: () {
                final current = int.tryParse(controller.text) ?? 0;
                controller.text = (current + 1).toString();
                // Listener sẽ tự động trigger update
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF00695C).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00695C).withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00695C),
          size: 20,
        ),
      ),
    );
  }
}
