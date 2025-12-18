import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../services/tournament_service.dart';
import '../../services/club_service.dart';
import '../../services/tournament_prize_voucher_service.dart';
import 'widgets/enhanced_basic_info_step.dart';
import 'widgets/enhanced_schedule_step.dart';
import 'widgets/enhanced_prizes_step_v2.dart';
import 'widgets/enhanced_rules_review_step.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentCreationWizard extends StatefulWidget {
  final String? clubId;
  final Map<String, dynamic>? draftData;

  const TournamentCreationWizard({
    super.key,
    this.clubId,
    this.draftData,
  });

  @override
  _TournamentCreationWizardState createState() =>
      _TournamentCreationWizardState();
}

class _TournamentCreationWizardState extends State<TournamentCreationWizard>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;
  bool _isCreating = false;

  // Text controllers (most are now handled by individual steps)
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _rulesController = TextEditingController();
  final _contactInfoController = TextEditingController();

  // Services
  final _supabase = Supabase.instance.client;
  final _tournamentService = TournamentService.instance;
  final _prizeVoucherService = TournamentPrizeVoucherService();

  // Validation errors
  final Map<String, String> _errors = {};

  // Tournament data with comprehensive fields
  final Map<String, dynamic> _tournamentData = {
    // Basic Info
    'name': '',
    'description': '',
    'gameType': '8-ball', // 8-ball, 9-ball, 10-ball, straight-pool
    'format':
        'single_elimination', // single_elimination, double_elimination, round_robin, swiss
    'maxParticipants': 16, // 4,6,8,12,16,24,32,64
    'hasThirdPlaceMatch': true,

    // Schedule & Venue
    'registrationStartDate': null,
    'registrationEndDate': null,
    'tournamentStartDate': null,
    'tournamentEndDate': null,
    'venue': '', // Auto-fill from club or custom

    // Financial & Requirements
    'entryFee': 0.0,
    'prizePool': 0.0,
    'minRank': '', // K, K+, I, I+, H, H+, G, G+, F, F+, E, D, C
    'maxRank': '', // Empty = no limit

    // Additional Info
    'rules': '',
    'contactInfo': '', // Auto-fill from club
    'bannerUrl': '',

    // System fields (auto-filled)
    'clubId': '',
    'creatorId': '',
    'status': 'registration_open',
    'currentParticipants': 0,
    'isClubVerified': false,
  };

  final List<String> _stepTitles = [
    'Thông tin cơ bản',
    'Thời gian & Địa điểm',
    'Tài chính & Giải thưởng',
    'Quy định & Xem lại',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeTournamentData();
  }

  void _initializeTournamentData() {
    // Auto-fill club information
    if (widget.clubId != null) {
      _tournamentData['clubId'] = widget.clubId!;
      // TODO: Load club data and auto-fill venue, contact info
      _loadClubData();
    }

    // Set default dates (registration starts tomorrow, tournament in 7 days)
    final now = DateTime.now();
    _tournamentData['registrationStartDate'] = now.add(Duration(days: 1));
    _tournamentData['registrationEndDate'] = now.add(Duration(days: 6));
    _tournamentData['tournamentStartDate'] = now.add(Duration(days: 7));
    _tournamentData['tournamentEndDate'] = now.add(Duration(days: 8));
  }

  void _loadClubData() async {
    if (widget.clubId == null) return;

    try {
      final club = await ClubService.instance.getClubById(widget.clubId!);
      setState(() {
        if (_tournamentData['venue'] == null || _tournamentData['venue'].isEmpty) {
          _tournamentData['venue'] = club.address;
        }
        if (_tournamentData['venueContact'] == null || _tournamentData['venueContact'].isEmpty) {
          _tournamentData['venueContact'] = club.name; // Default contact is club name
        }
        if (_tournamentData['venuePhone'] == null || _tournamentData['venuePhone'].isEmpty) {
          _tournamentData['venuePhone'] = club.phone;
        }
      });
      ProductionLogger.info('✅ Auto-filled club data: ${club.name}', tag: 'tournament_creation_wizard');
    } catch (e) {
      ProductionLogger.info('⚠️ Failed to load club data: $e', tag: 'tournament_creation_wizard');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _rulesController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin bắt buộc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onDataChanged(Map<String, dynamic> data) {
    setState(() {
      _tournamentData.addAll(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardShortcutsWrapper(
      onSave: () {
        if (_currentStep == 3 && !_isCreating) {
          _validateAndPublish();
        }
      },
      onClose: () => Navigator.of(context).pop(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tạo giải đấu mới'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // Step Indicator
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: isCompleted || isActive
                                          ? theme.colorScheme.primary
                                          : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? Icon(Icons.check, size: 16, color: Colors.white)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: isActive ? Colors.white : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (index < 3)
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: index < _currentStep
                                            ? theme.colorScheme.primary
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _stepTitles[index],
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            
            // Step content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // Step 1: Enhanced Basic Info (Full version)
                  EnhancedBasicInfoStep(
                    data: _tournamentData,
                    onDataChanged: _onDataChanged,
                  ),

                  // Step 2: Enhanced Schedule & Venue
                  EnhancedScheduleStep(
                    data: _tournamentData,
                    onDataChanged: _onDataChanged,
                  ),

                  // Step 3: Enhanced Prizes Step V2
                  EnhancedPrizesStepV2(
                    data: _tournamentData,
                    onDataChanged: _onDataChanged,
                  ),

                  // Step 4: Enhanced Rules & Review (Theme fixed)
                  EnhancedRulesReviewStep(
                    data: _tournamentData,
                    onDataChanged: _onDataChanged,
                    onCreateTournament: _validateAndPublish,
                    isCreating: _isCreating,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: EdgeInsets.all(20.h),
              child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text(
                        'Quay lại',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating
                        ? null
                        : (_currentStep < _stepTitles.length - 1
                            ? _nextStep
                            : _validateAndPublish),
                    child: _isCreating
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text('Đang tạo...'),
                            ],
                          )
                        : Text(_currentStep < _stepTitles.length - 1
                            ? 'Tiếp theo'
                            : 'Tạo giải đấu'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _validateAndPublish() async {

    // First sync final data from controllers to ensure _tournamentData is up to date
    // Note: Controllers might be empty if using enhanced steps,
    // so only sync if controllers have data
    if (_nameController.text.isNotEmpty) {
      _tournamentData['name'] = _nameController.text;
    }
    if (_descriptionController.text.isNotEmpty) {
      _tournamentData['description'] = _descriptionController.text;
    }
    if (_venueController.text.isNotEmpty) {
      _tournamentData['venue'] = _venueController.text;
    }

    // Validate all forms
    bool isValid = true;
    _errors.clear();

    // Validate current step form
    if (!_validateCurrentStep()) {
      isValid = false;
    }

    // Manual validation of required fields - check from tournamentData

    final name = _tournamentData['name'] ?? '';
    final venue = _tournamentData['venue'] ?? '';

    if (name.isEmpty) {
      _errors['name'] = 'Vui lòng nhập tên giải đấu';
      isValid = false;
    }

    if (venue.isEmpty) {
      _errors['venue'] = 'Vui lòng nhập địa chỉ tổ chức';
      isValid = false;
    }

    // Validate participant count matches format requirements
    final format = _tournamentData['format'];
    final maxParticipants = _tournamentData['maxParticipants'];

    if (format == 'sabo_de16' && maxParticipants != 16) {
      _errors['maxParticipants'] =
          'SABO DE16 yêu cầu đúng 16 người tham gia (hiện tại: $maxParticipants)';
      isValid = false;
    }

    if (format == 'sabo_de32' && maxParticipants != 32) {
      _errors['maxParticipants'] =
          'SABO DE32 yêu cầu đúng 32 người tham gia (hiện tại: $maxParticipants)';
      isValid = false;
    }

    if (format == 'double_elimination' && maxParticipants != 16) {
      _errors['maxParticipants'] =
          'Double Elimination yêu cầu 16 người tham gia (hiện tại: $maxParticipants)';
      isValid = false;
    }

    if (_tournamentData['registrationStartDate'] == null) {
      _errors['registrationStartDate'] = 'Vui lòng chọn thời gian mở đăng ký';
      isValid = false;
    }

    if (_tournamentData['tournamentStartDate'] == null) {
      _errors['tournamentStartDate'] = 'Vui lòng chọn thời gian bắt đầu giải';
      isValid = false;
    }

    if (!isValid) {
      _showValidationErrors();
      return;
    }


    /// Setup prize vouchers for tournament
    Future<void> setupPrizeVouchers(String tournamentId) async {
      try {
        final prizes = _tournamentData['prizes'] as List?;
        if (prizes == null || prizes.isEmpty) {
          ProductionLogger.info('ℹ️ No prizes configured, skipping voucher setup', tag: 'tournament_creation_wizard');
          return;
        }

        // Filter prizes with prize vouchers (voucherType == 'prize')
        final prizeVouchers = prizes.where((p) {
          final voucherType = p['voucherType'] as String?;
          return voucherType == 'prize' && p['voucherValueVnd'] != null;
        }).toList();

        if (prizeVouchers.isEmpty) {
          ProductionLogger.info('ℹ️ No prize vouchers configured, skipping', tag: 'tournament_creation_wizard');
          return;
        }

        ProductionLogger.info('🎁 Setting up ${prizeVouchers.length} prize vouchers...', tag: 'tournament_creation_wizard');

        // Convert to TournamentPrizeConfig format
        final prizeConfigs = prizeVouchers.map((p) {
          final position = p['position'] as int;
          final value = p['voucherValueVnd'] as int;
          final validDays = p['voucherValidDays'] as int? ?? 30;
          
          String positionLabel;
          String codePrefix;
          
          switch (position) {
            case 1:
              positionLabel = 'Nhất';
              codePrefix = 'PRIZE1';
              break;
            case 2:
              positionLabel = 'Nhì';
              codePrefix = 'PRIZE2';
              break;
            case 3:
              positionLabel = 'Ba';
              codePrefix = 'PRIZE3';
              break;
            default:
              positionLabel = 'Top $position';
              codePrefix = 'PRIZE$position';
          }

          return TournamentPrizeConfig(
            position: position,
            positionLabel: positionLabel,
            voucherValue: value.toDouble(),
            codePrefix: codePrefix,
            description: 'Prize voucher $positionLabel - ${value ~/ 1000}K VNĐ',
            validDays: validDays,
          );
        }).toList();

        // Setup prize vouchers in database
        await _prizeVoucherService.setupTournamentPrizeVouchers(
          tournamentId: tournamentId,
          prizes: prizeConfigs,
        );

        ProductionLogger.info('✅ Prize vouchers setup complete: ${prizeConfigs.length} configs saved', tag: 'tournament_creation_wizard');
      } catch (e) {
        ProductionLogger.info('⚠️ Failed to setup prize vouchers: $e', tag: 'tournament_creation_wizard');
        // Don't throw - tournament creation should still succeed
      }
    }

    // Set loading state
    setState(() => _isCreating = true);

    try {
      // Upload cover image first if provided
      String? uploadedCoverUrl;
      if (_tournamentData['coverImageBytes'] != null &&
          _tournamentData['coverImageFileName'] != null) {
        try {
          ProductionLogger.info('📤 Pre-uploading tournament cover image...', tag: 'tournament_creation_wizard');
          final fileName = _tournamentData['coverImageFileName'] as String;
          final tempPath = 'temp_covers/${DateTime.now().millisecondsSinceEpoch}_$fileName';
          
          // Determine content type
          String contentType = 'image/jpeg';
          final ext = fileName.split('.').last.toLowerCase();
          if (ext == 'png') contentType = 'image/png';
          else if (ext == 'webp') contentType = 'image/webp';

          await _supabase.storage
              .from('tournament-covers')
              .uploadBinary(
                tempPath,
                _tournamentData['coverImageBytes'],
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                ),
              );
          uploadedCoverUrl = _supabase.storage
              .from('tournament-covers')
              .getPublicUrl(tempPath);
          ProductionLogger.info('✅ Cover image pre-uploaded: $uploadedCoverUrl', tag: 'tournament_creation_wizard');
        } catch (uploadError) {
          ProductionLogger.info('⚠️ Cover image upload failed, will create tournament without cover: $uploadError', tag: 'tournament_creation_wizard');
        }
      }

      // Create tournament using service with proper parameters
      final tournament = await _tournamentService.createTournament(
        clubId: widget.clubId ?? '',
        title: _tournamentData['name'] ?? '',
        description: _tournamentData['description'] ?? '',
        startDate: _tournamentData['tournamentStartDate'] ?? DateTime.now(),
        registrationDeadline:
            _tournamentData['registrationEndDate'] ?? DateTime.now(),
        maxParticipants: _tournamentData['maxParticipants'] ?? 16,
        entryFee: _tournamentData['entryFee'] ?? 0.0,
        prizePool: _tournamentData['prizePool'] ?? 0.0,
        format: _tournamentData['format'] ??
            'single_elimination', // Tournament elimination format
        gameType: _tournamentData['gameType'] ?? '8-ball', // Game type
        rules: _tournamentData['rules'],
        requirements: _buildRequirements(),
        coverImageUrl: uploadedCoverUrl, // Pass uploaded cover URL
        // Enhanced prize configuration
        prizeSource: _tournamentData['prizeSource'] ?? 'entry_fees',
        distributionTemplate: _tournamentData['prizeTemplate'] ?? _tournamentData['prizeDistribution'] ?? 'top_3',
        organizerFeePercent: _tournamentData['organizerFeePercent'] ?? 10.0,
        sponsorContribution: _tournamentData['sponsorContribution'] ?? 0.0,
        customDistribution: _tournamentData['customDistribution'],
        // Rank restrictions
        minRank: _tournamentData['minRank'],
        maxRank: _tournamentData['maxRank'],
        // Venue and contact information
        venueAddress: _tournamentData['venue'],
        venueContact: _tournamentData['venueContact'],
        venuePhone: _tournamentData['venuePhone'],
        // Additional rules
        specialRules: _tournamentData['specialRules'],
        registrationFeeWaiver:
            _tournamentData['registrationFeeWaiver'] ?? false,
      );

      // 🔍 VERIFY TOURNAMENT WAS ACTUALLY CREATED
      if (tournament.id.isEmpty) {
        throw Exception('Tournament creation failed - no tournament ID returned');
      }

      ProductionLogger.info('✅ Tournament created successfully with ID: ${tournament.id}', tag: 'tournament_creation_wizard');
      ProductionLogger.info('📋 Tournament details: ${tournament.title}', tag: 'tournament_creation_wizard');

      // 🎁 Setup prize vouchers if configured
      await setupPrizeVouchers(tournament.id);

      /* REMOVED: Cover image now uploaded BEFORE tournament creation
      // Upload cover image if selected
      if (_tournamentData['coverImageBytes'] != null &&
          _tournamentData['coverImageFileName'] != null) {
        try {
          ProductionLogger.info('� Uploading tournament cover image...', tag: 'tournament_creation_wizard');
          final updatedTournament = await _tournamentService
              .uploadAndUpdateTournamentCover(
            tournament.id,
            _tournamentData['coverImageBytes'],
            _tournamentData['coverImageFileName'],
          );
          ProductionLogger.info('✅ Tournament cover uploaded successfully', tag: 'tournament_creation_wizard');
          
          // �🔍 DOUBLE-CHECK: Try to fetch the updated tournament
          try {
            final fetchedTournament = await _tournamentService.getTournamentById(updatedTournament.id);
            if (fetchedTournament == null) {
              throw Exception('Tournament was not saved to database properly');
            }
            ProductionLogger.info('✅ Tournament verification successful - found in database', tag: 'tournament_creation_wizard');
          } catch (verifyError) {
            ProductionLogger.info('❌ Tournament verification failed: $verifyError', tag: 'tournament_creation_wizard');
            throw Exception('Tournament creation failed during verification: $verifyError');
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Giải đấu "${updatedTournament.title}" đã được tạo thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Return updated tournament data to parent
          Navigator.of(context).pop(updatedTournament);
        } catch (uploadError) {
          ProductionLogger.info('⚠️ Failed to upload cover image: $uploadError', tag: 'tournament_creation_wizard');
          // Continue without cover image
          
          // Show success message with warning
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Giải đấu "${tournament.title}" đã được tạo (không có ảnh bìa)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(tournament);
        }
      } else {
        // No cover image to upload
        
        // 🔍 DOUBLE-CHECK: Try to fetch the created tournament
        try {
          final fetchedTournament = await _tournamentService.getTournamentById(tournament.id);
          if (fetchedTournament == null) {
            throw Exception('Tournament was not saved to database properly');
          }
          ProductionLogger.info('✅ Tournament verification successful - found in database', tag: 'tournament_creation_wizard');
        } catch (verifyError) {
          ProductionLogger.info('❌ Tournament verification failed: $verifyError', tag: 'tournament_creation_wizard');
          throw Exception('Tournament creation failed during verification: $verifyError');
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Giải đấu "${tournament.title}" đã được tạo thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Return tournament data to parent
        Navigator.of(context).pop(tournament);
      }
      */

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giải đấu "${tournament.title}" đã được tạo thành công!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Return tournament data to parent
      if (mounted) {
        Navigator.of(context).pop(tournament);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo giải đấu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  String _buildRequirements() {
    List<String> requirements = [];

    if (_tournamentData['minRank']?.isNotEmpty == true) {
      requirements.add('Hạng tối thiểu: ${_tournamentData['minRank']}');
    }

    if (_tournamentData['maxRank']?.isNotEmpty == true) {
      requirements.add('Hạng tối đa: ${_tournamentData['maxRank']}');
    }

    if (_tournamentData['gameType']?.isNotEmpty == true) {
      requirements.add('Môn thi đấu: ${_tournamentData['gameType']}');
    }

    if (_tournamentData['format']?.isNotEmpty == true) {
      requirements.add('Hình thức: ${_tournamentData['format']}');
    }

    return requirements.join('; ');
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Enhanced basic info step validation
        final name = _tournamentData['name'] ?? '';
        final gameType = _tournamentData['gameType'] ?? '';
        final format = _tournamentData['format'] ?? '';
        final maxParticipants = _tournamentData['maxParticipants'] ?? 0;

        return name.isNotEmpty &&
            name.length >= 3 &&
            gameType.isNotEmpty &&
            format.isNotEmpty &&
            maxParticipants >= 4;
      case 1:
        // Enhanced schedule step validation
        final venue = _tournamentData['venue'] ?? '';
        final regStartDate =
            _tournamentData['registrationStartDate'] as DateTime?;
        final regEndDate = _tournamentData['registrationEndDate'] as DateTime?;
        final tournamentStartDate =
            _tournamentData['tournamentStartDate'] as DateTime?;
        final tournamentEndDate =
            _tournamentData['tournamentEndDate'] as DateTime?;

        return venue.isNotEmpty &&
            regStartDate != null &&
            regEndDate != null &&
            tournamentStartDate != null &&
            tournamentEndDate != null;
      case 2:
        // Combined requirements step validation - always true since it's optional
        return true;
      case 3:
        // Enhanced rules review step validation - check if basic tournament data is complete
        final name = _tournamentData['name'] ?? '';
        final venue = _tournamentData['venue'] ?? '';
        return name.isNotEmpty && venue.isNotEmpty;
      default:
        return true;
    }
  }

  void _showValidationErrors() {
    final errorMessages = _errors.values.join('\n');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi validation'),
        content: Text(errorMessages),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

