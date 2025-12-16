import 'package:flutter/material.dart';
import '../../models/admin_guide_models.dart';
import '../../services/admin_guide_service.dart';
import '../../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Guide Viewer - Interactive step-by-step guide
class AdminGuideViewerScreen extends StatefulWidget {
  final AdminGuide guide;

  const AdminGuideViewerScreen({super.key, required this.guide});

  @override
  State<AdminGuideViewerScreen> createState() => _AdminGuideViewerScreenState();
}

class _AdminGuideViewerScreenState extends State<AdminGuideViewerScreen> {
  final _guideService = AdminGuideService();
  final _pageController = PageController();

  int _currentStep = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final progress = await _guideService.getGuideProgress(
      userId,
      widget.guide.id,
    );
    if (progress != null && mounted) {
      setState(() {
        _currentStep = progress.currentStep;
        _isCompleted = progress.isCompleted;
      });
      _pageController.jumpToPage(_currentStep);
    }
  }

  Future<void> _saveProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _guideService.updateProgress(
      userId: userId,
      guideId: widget.guide.id,
      currentStep: _currentStep,
      isCompleted: _isCompleted,
    );
  }

  void _nextStep() {
    if (_currentStep < widget.guide.steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _saveProgress();
    } else {
      _completeGuide();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _saveProgress();
    }
  }

  Future<void> _completeGuide() async {
    setState(() => _isCompleted = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _guideService.completeGuide(userId, widget.guide.id);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text('Hoàn thành!'),
            ],
          ),
          content: Text(
            'Bạn đã hoàn thành hướng dẫn "${widget.guide.title}".\n\nChúc mừng! 🎉',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guide.title),
        backgroundColor: AppTheme.primaryLight,
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentStep + 1}/${widget.guide.steps.length}', overflow: TextOverflow.ellipsis, style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / widget.guide.steps.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            minHeight: 4,
          ),

          // Step content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.guide.steps.length,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemBuilder: (context, index) {
                return _buildStepContent(widget.guide.steps[index]);
              },
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent(GuideStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step type badge and icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStepTypeColor(step.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStepTypeColor(step.type),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStepTypeIcon(step.type),
                      size: 16,
                      color: _getStepTypeColor(step.type),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStepTypeName(step.type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStepTypeColor(step.type),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Icon if provided
          if (step.icon != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 64, color: AppTheme.primaryLight),
              ),
            ),
          const SizedBox(height: 24),

          // Title
          Text(
            step.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description, style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Key points
          if (step.keyPoints != null && step.keyPoints!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Điểm chính', overflow: TextOverflow.ellipsis, style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...step.keyPoints!.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point, style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Target route button
          if (step.targetRoute != null)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, step.targetRoute!);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở màn hình này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),

          // Next/Complete button
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              icon: Icon(
                _currentStep < widget.guide.steps.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
              ),
              label: Text(
                _currentStep < widget.guide.steps.length - 1
                    ? 'Tiếp theo'
                    : 'Hoàn thành',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepTypeColor(GuideStepType type) {
    switch (type) {
      case GuideStepType.info:
        return Colors.blue;
      case GuideStepType.action:
        return Colors.green;
      case GuideStepType.tip:
        return Colors.orange;
      case GuideStepType.warning:
        return Colors.red;
      case GuideStepType.success:
        return Colors.purple;
    }
  }

  IconData _getStepTypeIcon(GuideStepType type) {
    switch (type) {
      case GuideStepType.info:
        return Icons.info;
      case GuideStepType.action:
        return Icons.touch_app;
      case GuideStepType.tip:
        return Icons.tips_and_updates;
      case GuideStepType.warning:
        return Icons.warning;
      case GuideStepType.success:
        return Icons.check_circle;
    }
  }

  String _getStepTypeName(GuideStepType type) {
    switch (type) {
      case GuideStepType.info:
        return 'THÔNG TIN';
      case GuideStepType.action:
        return 'HÀNH ĐỘNG';
      case GuideStepType.tip:
        return 'MẸO';
      case GuideStepType.warning:
        return 'CẢNH BÁO';
      case GuideStepType.success:
        return 'THÀNH CÔNG';
    }
  }
}
