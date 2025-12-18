import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/auth_navigation_controller.dart';
import '../../services/notification_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  final String? userId;

  const ProfileSetupScreen({super.key, this.isFirstTime = true, this.userId});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  // Form data
  XFile? _selectedAvatar;
  String _selectedRole = 'player';
  final List<String> _selectedGames = [];
  String _skillLevel = 'beginner';
  bool _isPublicProfile = true;

  // Validation states
  bool _isDisplayNameValid = false;
  bool _isUsernameValid = false;
  bool _isUsernameChecking = false;
  bool _isLoading = false;

  final List<String> _availableGames = [
    'Billiards 8-Ball',
    'Billiards 9-Ball',
    'Snooker',
    'Pool',
    'Carom',
    'American Pool',
  ];

  final List<String> _skillLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'professional',
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Load existing user data if available
    _loadExistingUserData();

    // Start with first step animation
    _progressController.animateTo(1 / _totalSteps);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadExistingUserData() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _displayNameController.text =
          user.userMetadata?['display_name'] ??
          user.userMetadata?['full_name'] ??
          '';
      _usernameController.text = user.userMetadata?['username'] ?? '';
      _bioController.text = user.userMetadata?['bio'] ?? '';
      _selectedRole = user.userMetadata?['role'] ?? 'player';

      // Validate existing data
      _validateDisplayName();
      _validateUsername();
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / _totalSteps);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / _totalSteps);
    }
  }

  void _validateDisplayName() {
    setState(() {
      _isDisplayNameValid = _displayNameController.text.trim().length >= 2;
    });
  }

  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();

    if (username.length < 3) {
      setState(() => _isUsernameValid = false);
      return;
    }

    setState(() => _isUsernameChecking = true);

    try {
      final isAvailable = await AuthService.instance.checkUsernameAvailable(
        username,
      );
      setState(() {
        _isUsernameValid = isAvailable;
        _isUsernameChecking = false;
      });
    } catch (e) {
      setState(() {
        _isUsernameValid = false;
        _isUsernameChecking = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedAvatar = pickedFile;
        });
      }
    } catch (e) {
      _showMessage('Lỗi chọn ảnh: $e', true);
    }
  }

  Future<void> _completeProfileSetup() async {
    setState(() => _isLoading = true);

    try {
      // Upload avatar if selected
      if (_selectedAvatar != null) {
        final bytes = await _selectedAvatar!.readAsBytes();
        await AuthService.instance.uploadAvatar(_selectedAvatar!.path, bytes);
      }

      // Update user profile using existing method parameters
      await AuthService.instance.updateUserProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        skillLevel: _skillLevel,
      );

      // Update user record with additional info
      await AuthService.instance.upsertUserRecord(
        fullName: _displayNameController.text.trim(),
        role: _selectedRole,
        phone: null, // Phone can be added later
        email: AuthService.instance.currentUser?.email,
      );

      final uid = AuthService.instance.currentUser?.id;
      if (uid != null) {
        await NotificationService.instance.sendProfileCompletedNotification(
          userId: uid,
        );
      }

      if (!mounted) return;
      _showMessage('✅ Hồ sơ đã được cập nhật thành công!', false);

      // Navigate to next step in user journey
      if (widget.isFirstTime) {
        await AuthNavigationController.navigateAfterLogin(
          context,
          userId: widget.userId ?? AuthService.instance.currentUser!.id,
          isFirstLogin: true,
        );
      } else {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      _showMessage('Lỗi cập nhật hồ sơ: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _canContinueFromStep(int step) {
    switch (step) {
      case 0:
        return _isDisplayNameValid && _isUsernameValid;
      case 1:
        return true; // Avatar is optional
      case 2:
        return _selectedGames.isNotEmpty;
      case 3:
        return true; // Final review
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF007AFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildAvatarStep(),
                  _buildGamingPreferencesStep(),
                  _buildFinalReviewStep(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                )
              else
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              Expanded(
                child: Text(
                  widget.isFirstTime ? 'Thiết lập hồ sơ' : 'Cập nhật hồ sơ', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 48), // Balance
            ],
          ),

          SizedBox(height: 20),

          // Progress indicator
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bước ${_currentStep + 1} / $_totalSteps', overflow: TextOverflow.ellipsis, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            '👤 Thông tin cơ bản', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy cho chúng tôi biết về bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          SizedBox(height: 32),

          // Display Name
          _buildInputField(
            controller: _displayNameController,
            label: 'Tên hiển thị',
            hint: 'Nguyễn Văn A',
            icon: Icons.person,
            onChanged: (value) {
              _validateDisplayName();
            },
            isValid: _isDisplayNameValid,
            errorText:
                _displayNameController.text.isNotEmpty && !_isDisplayNameValid
                ? 'Tên hiển thị phải có ít nhất 2 ký tự'
                : null,
          ),

          SizedBox(height: 20),

          // Username
          _buildInputField(
            controller: _usernameController,
            label: 'Tên người dùng',
            hint: 'nguyen_van_a',
            icon: Icons.alternate_email,
            onChanged: (value) {
              _validateUsername();
            },
            isValid: _isUsernameValid,
            isLoading: _isUsernameChecking,
            errorText:
                _usernameController.text.isNotEmpty &&
                    !_isUsernameValid &&
                    !_isUsernameChecking
                ? 'Tên người dùng không khả dụng hoặc quá ngắn'
                : null,
          ),

          SizedBox(height: 20),

          // Bio
          _buildInputField(
            controller: _bioController,
            label: 'Giới thiệu (tùy chọn)',
            hint: 'Mô tả ngắn về bản thân...',
            icon: Icons.description,
            maxLines: 3,
          ),

          SizedBox(height: 20),

          // Role selection
          Text(
            'Vai trò của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRoleOption(
                  'player',
                  '🎮 Người chơi',
                  'Tham gia giải đấu',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildRoleOption(
                  'club_owner',
                  '🏢 Chủ câu lạc bộ',
                  'Quản lý CLB',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStep() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step title
          Text(
            '📸 Ảnh đại diện', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Thêm ảnh để mọi người dễ nhận ra bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 60),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _selectedAvatar != null
                    ? ClipOval(
                        child: kIsWeb
                            ? Image.network(_selectedAvatar!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedAvatar!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Chọn ảnh', overflow: TextOverflow.ellipsis, style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          SizedBox(height: 32),

          Text(
            _selectedAvatar != null
                ? '✅ Ảnh đại diện đã được chọn'
                : '⏭️ Bạn có thể bỏ qua bước này', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGamingPreferencesStep() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            '🎮 Sở thích gaming', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chọn các môn bạn yêu thích', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          SizedBox(height: 24),

          // Games selection
          Text(
            'Môn thể thao (chọn ít nhất 1)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableGames.map((game) {
              final isSelected = _selectedGames.contains(game);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGames.remove(game);
                    } else {
                      _selectedGames.add(game);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    game, style: TextStyle(
                      color: isSelected ? Color(0xFF007AFF) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 32),

          // Skill level
          Text(
            'Trình độ của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Column(
            children: _skillLevels.map((level) {
              final isSelected = _skillLevel == level;
              return GestureDetector(
                onTap: () => setState(() => _skillLevel = level),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Color(0xFF007AFF) : Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _getSkillLevelLabel(level),
                        style: TextStyle(
                          color: isSelected ? Color(0xFF007AFF) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalReviewStep() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            '✅ Xác nhận thông tin', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kiểm tra lại thông tin trước khi hoàn tất', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

          SizedBox(height: 32),

          // Review card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and basic info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF007AFF).withValues(alpha: 0.2),
                      ),
                      child: _selectedAvatar != null
                          ? ClipOval(
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedAvatar!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedAvatar!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Icon(
                              Icons.person,
                              color: Color(0xFF007AFF),
                              size: 30,
                            ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayNameController.text, style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          Text(
                            '@${_usernameController.text}', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_bioController.text.isNotEmpty)
                            Text(
                              _bioController.text, style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Role
                _buildReviewItem(
                  '👤 Vai trò',
                  _selectedRole == 'player' ? 'Người chơi' : 'Chủ câu lạc bộ',
                ),

                // Games
                _buildReviewItem('🎮 Môn thể thao', _selectedGames.join(', ')),

                // Skill level
                _buildReviewItem(
                  '⭐ Trình độ',
                  _getSkillLevelLabel(_skillLevel),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Privacy toggle
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hồ sơ công khai', overflow: TextOverflow.ellipsis, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cho phép người khác xem hồ sơ của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublicProfile,
                  onChanged: (value) =>
                      setState(() => _isPublicProfile = value),
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Quay lại'),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: 16),

          Expanded(
            flex: _currentStep > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canContinueFromStep(_currentStep)
                  ? (_currentStep == _totalSteps - 1
                        ? _completeProfileSetup
                        : _nextStep)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Hoàn tất' : 'Tiếp tục', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
    bool isValid = true,
    bool isLoading = false,
    String? errorText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: Colors.white),
            suffixIcon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : isValid
                ? Icon(Icons.check_circle, color: Colors.green)
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            errorText: errorText,
            errorStyle: TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(String value, String title, String subtitle) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Color(0xFF007AFF) : Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              title, style: TextStyle(
                color: isSelected ? Color(0xFF007AFF) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle, style: TextStyle(
                color: isSelected
                    ? Color(0xFF007AFF).withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label, style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value, style: TextStyle(
                fontSize: 14,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSkillLevelLabel(String level) {
    switch (level) {
      case 'beginner':
        return '🌱 Người mới bắt đầu';
      case 'intermediate':
        return '⚡ Trung bình';
      case 'advanced':
        return '🔥 Nâng cao';
      case 'professional':
        return '👑 Chuyên nghiệp';
      default:
        return level;
    }
  }
}
