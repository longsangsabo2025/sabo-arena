import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/club_service.dart';

class ClubRegistrationController extends ChangeNotifier {
  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController clubNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _selectedCity;
  String? get selectedCity => _selectedCity;

  final List<String> _selectedAmenities = [];
  List<String> get selectedAmenities => List.unmodifiable(_selectedAmenities);

  final Map<String, String> _operatingHours = {
    'Thứ 2 - Thứ 6': '08:00 - 22:00',
    'Thứ 7 - Chủ nhật': '07:00 - 23:00',
  };
  Map<String, String> get operatingHours => Map.unmodifiable(_operatingHours);

  void updateOperatingHours(String day, String newHours) {
    _operatingHours[day] = newHours;
    notifyListeners();
  }

  // Image Files
  XFile? _businessLicenseImage;
  XFile? get businessLicenseImage => _businessLicenseImage;

  XFile? _identityCardImage;
  XFile? get identityCardImage => _identityCardImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickBusinessLicenseImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _businessLicenseImage = image;
      notifyListeners();
    }
  }

  Future<void> pickIdentityCardImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _identityCardImage = image;
      notifyListeners();
    }
  }

  Future<String?> _uploadImage(XFile file, String path) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('Error uploading image: User not logged in');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      // 🚀 MUSK: Use user-images bucket which is known to work and has proper policies
      final fullPath = 'club_registration/${user.id}/$path/$fileName';
      
      final bytes = await file.readAsBytes();
      
      // Use user-images bucket
      await Supabase.instance.client.storage.from('user-images').uploadBinary(
        fullPath, 
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final imageUrl = Supabase.instance.client.storage.from('user-images').getPublicUrl(fullPath);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Mock Data (Could be moved to a repository or constant file)
  final List<String> cities = [
    'Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Bình Dương',
    'Đồng Nai',
  ];

  final List<String> allAmenities = [
    'WiFi miễn phí',
    'Bãi đỗ xe',
    'Quầy bar',
    'Phòng VIP',
    'Điều hòa',
    'Camera an ninh',
    'Nhà vệ sinh',
    'Khu vực hút thuốc',
    'Dịch vụ đồ ăn',
    'Máy lạnh',
  ];

  @override
  void dispose() {
    clubNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  void setCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    if (_selectedAmenities.contains(amenity)) {
      _selectedAmenities.remove(amenity);
    } else {
      _selectedAmenities.add(amenity);
    }
    notifyListeners();
  }

  Future<bool> submitForm({
    required Function(String) onError,
    required VoidCallback onSuccess,
  }) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedAmenities.isEmpty) {
      onError('Vui lòng chọn ít nhất một tiện ích');
      return false;
    }

    if (_businessLicenseImage == null) {
      onError('Vui lòng tải lên Giấy phép kinh doanh');
      return false;
    }

    if (_identityCardImage == null) {
      onError('Vui lòng tải lên CCCD/CMND');
      return false;
    }

    // Check authentication
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      onError('Bạn chưa đăng nhập. Vui lòng đăng nhập để đăng ký CLB.');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Upload images
      final businessLicenseUrl = await _uploadImage(_businessLicenseImage!, 'licenses');
      if (businessLicenseUrl == null) {
        throw Exception('Lỗi tải lên Giấy phép kinh doanh. Vui lòng thử lại.');
      }

      final identityCardUrl = await _uploadImage(_identityCardImage!, 'identities');
      if (identityCardUrl == null) {
        throw Exception('Lỗi tải lên CCCD/CMND. Vui lòng thử lại.');
      }

      final clubService = ClubService.instance;

      await clubService.createClub(
        name: clubNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: '${addressController.text.trim()}, ${_selectedCity ?? ""}',
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        email: emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : null,
        websiteUrl: websiteController.text.trim().isNotEmpty
            ? websiteController.text.trim()
            : null,
        amenities: _selectedAmenities,
        openingHours: _operatingHours,
        businessLicenseUrl: businessLicenseUrl,
        identityCardUrl: identityCardUrl,
        totalTables: 1, // Default value
      );

      // Clear pending flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_club_registration', false);
      await prefs.setBool('dismissed_club_reminder', false);

      onSuccess();
      return true;
    } catch (error) {
      onError('Có lỗi xảy ra: ${error.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
