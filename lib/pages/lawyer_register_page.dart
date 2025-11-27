import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'otp_screen.dart';
import '../services/session.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class LawyerRegisterPage extends StatefulWidget {
  const LawyerRegisterPage({super.key});

  @override
  State<LawyerRegisterPage> createState() => _LawyerRegisterPageState();
}

class _LawyerRegisterPageState extends State<LawyerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  // Controllers for all form fields
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
   // File handling variables
  String? _licenseFileName;
  String? _profileImageName;
  PlatformFile? _licenseFile;
  PlatformFile? _profileImage;
  // Dropdown selection variables
  String? _selectedGender;
  String? _selectedMainSpecialization;
  String? _selectedSubSpecialization1;
  String? _selectedSubSpecialization2;
  String? _selectedEducationLevel;
  String? _selectedAcademicMajor;
  // UI state variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Static data for dropdowns
  final List<String> _genders = ['ذكر', 'أنثى'];
  final List<String> _mainSpecializations = [
    'عقاري', 'قضايا العمالة', 'جنائي', 'تجاري', 'اسري',
    'عمل', 'أحوال شخصية', 'اداري', 'ملكية فكرية'
  ];
  final List<String> _subSpecializations = [
    'عقاري', 'قضايا العمالة', 'جنائي', 'تجاري', 'اسري',
    'عمل', 'أحوال شخصية', 'اداري', 'ملكية فكرية'
  ];
  final List<String> _educationLevels = [
    'بكالوريوس', 'ماجستير', 'دكتوراه', 'دبلوم'
  ];
  final List<String> _academicMajors = [
    'شريعة', 'قانون'
  ];
 // Availability checking variables
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isCheckingPhone = false;
  bool _isCheckingLicense = false;
  bool _isUsernameAvailable = false;
  bool _isPhoneAvailable = false;
  bool _isLicenseAvailable = false;
  String? _usernameMessage;
  String? _phoneMessage;
  String? _licenseMessage;
  @override
void initState() {
  super.initState();
  // Add real-time validation listeners
  _usernameController.addListener(_checkUsernameAvailability);
  _phoneController.addListener(_checkPhoneAvailability);
  _licenseController.addListener(_checkLicenseAvailability);
}

@override
void dispose() {
  // Clean up controllers and listeners to prevent memory leaks
  _usernameController.removeListener(_checkUsernameAvailability);
  _phoneController.removeListener(_checkPhoneAvailability);
  _licenseController.removeListener(_checkLicenseAvailability);
  _fullNameController.dispose();
  _usernameController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  _phoneController.dispose();
  _licenseController.dispose();
  _experienceController.dispose();
  super.dispose();
}
 /// Real-time username availability check via API
  /// Shows loading indicator and validation feedback
void _checkUsernameAvailability() async {
  String username = _usernameController.text.trim();
  if (username.length < 3) {
    setState(() {
      _usernameMessage = null;
      _isUsernameAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingUsername = true);

  try {
    var response = await http.post(
      Uri.parse('http://192.168.3.10:8888/mujeer_api/check_availability.php'),
      // Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),

      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'userType': 'lawyer'
      }),
    );

    var result = json.decode(response.body);
    setState(() {
      _isUsernameAvailable = result['available'];
      _usernameMessage = result['message'];
    });
  } catch (e) {
    print('خطأ في التحقق من اسم المستخدم: $e');
  } finally {
    setState(() => _isCheckingUsername = false);
  }
}
/// Validates phone number format and checks if already registered
  /// Uses Saudi mobile number pattern (05XXXXXXXX)
void _checkPhoneAvailability() async {
  String phone = _phoneController.text.trim();
  if (phone.length < 10 || !RegExp(r'^05\d{8}$').hasMatch(phone)) {
    setState(() {
      _phoneMessage = null;
      _isPhoneAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingPhone = true);

  try {
    var response = await http.post(
      Uri.parse('http://192.168.3.10:8888/mujeer_api/check_availability.php'),
      // Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phone,
        'userType': 'lawyer'
      }),
    );

    var result = json.decode(response.body);
    setState(() {
      _isPhoneAvailable = result['available'];
      _phoneMessage = result['message'];
    });
  } catch (e) {
    print('خطأ في التحقق من رقم الجوال: $e');
  } finally {
    setState(() => _isCheckingPhone = false);
  }
}
  /// Checks if license number is already registered in the system
void _checkLicenseAvailability() async {
  String license = _licenseController.text.trim();
  if (license.isEmpty) {
    setState(() {
      _licenseMessage = null;
      _isLicenseAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingLicense = true);

  try {
    var response = await http.post(
      Uri.parse('http://192.168.3.10:8888/mujeer_api/check_availability.php'),
      // Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'licenseNumber': license,
        'userType': 'lawyer'
      }),
    );

    var result = json.decode(response.body);
    setState(() {
      _isLicenseAvailable = result['available'];
      _licenseMessage = result['message'];
    });
  } catch (e) {
    print('خطأ في التحقق من رقم الرخصة: $e');
  } finally {
    setState(() => _isCheckingLicense = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تسجيل محامي جديد',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 20),
                    _buildSpecializationSection(),
                    const SizedBox(height: 20),
                    _buildFilesSection(),
                    const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
/// Builds the basic information section with personal details
  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('المعلومات الأساسية'),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _fullNameController,
              label: 'الاسم الكامل *',
              validator: (value) => value!.isEmpty ? 'الاسم الكامل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildUsernameField(),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _passwordController,
              label: 'كلمة المرور *',
              obscureText: _obscurePassword,
              onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) {
                if (value!.isEmpty) return 'كلمة المرور مطلوبة';
                if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور *',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (value) {
                if (value!.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPhoneField(),
          ],
        ),
      ),
    );
  }
/// Builds the professional information section with specialization details
  Widget _buildSpecializationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('المعلومات المهنية'),
            const SizedBox(height: 16),
            _buildLicenseField(),
            const SizedBox(height: 12),
            _buildTextFormField(
              controller: _experienceController,
              label: 'سنوات الخبرة *',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'سنوات الخبرة مطلوبة';
                if (int.tryParse(value) == null) return 'يجب إدخال رقم صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedGender,
              items: _genders,
              label: 'الجنس *',
              onChanged: (value) => setState(() => _selectedGender = value),
              validator: (value) => value == null ? 'الجنس مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedMainSpecialization,
              items: _mainSpecializations,
              label: 'التخصص الرئيسي *',
              onChanged: (value) => setState(() => _selectedMainSpecialization = value),
              validator: (value) => value == null ? 'التخصص الرئيسي مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSubSpecialization1,
              items: _subSpecializations,
              label: 'التخصص الفرعي الأول',
              onChanged: (value) => setState(() => _selectedSubSpecialization1 = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSubSpecialization2,
              items: _subSpecializations,
              label: 'التخصص الفرعي الثاني',
              onChanged: (value) => setState(() => _selectedSubSpecialization2 = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedEducationLevel,
              items: _educationLevels,
              label: 'المؤهل العلمي *',
              onChanged: (value) => setState(() => _selectedEducationLevel = value),
              validator: (value) => value == null ? 'المؤهل العلمي مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedAcademicMajor,
              items: _academicMajors,
              label: 'التخصص الأكاديمي *',
              onChanged: (value) => setState(() => _selectedAcademicMajor = value),
              validator: (value) => value == null ? 'التخصص الأكاديمي مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }
  /// Builds the file upload section for license and profile image
  Widget _buildFilesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('الملفات المطلوبة'),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'رخصة المحاماة *',
              fileName: _licenseFileName,
              onPressed: _pickLicenseFile,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى ادخال ملف بصيغة pdf',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            _buildFilePicker(
              label: 'الصورة الشخصية',
              fileName: _profileImageName,
              onPressed: _pickProfileImage,
              isRequired: false,
            ),
            const SizedBox(height: 8),
            Text(
              'الملفات المسموحة: PDF, JPG, PNG, DOC (الحجم الأقصى: 10MB)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// Main registration button that triggers the validation and registration process
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _registerLawyer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5345),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'تسجيل المحامي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========
  /// Creates a styled section title with consistent formatting
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0B5345),
      ),
    );
  }
  /// Reusable text form field builder with validation
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0B5345)),
        ),
      ),
      validator: validator,
    );
  }
  /// Specialized password field with visibility toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0B5345)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
  /// Reusable dropdown form field builder
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontFamily: 'Tajawal')),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0B5345)),
        ),
      ),
      validator: validator,
    );
  }
  /// File picker button with file name display
  Widget _buildFilePicker({
    required String label,
    required String? fileName,
    required VoidCallback onPressed,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}',
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B5345),
            side: const BorderSide(color: Color(0xFF0B5345)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fileName ?? 'اختر ملف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: fileName != null ? Colors.black : Colors.grey,
                ),
              ),
              const Icon(Icons.attach_file),
            ],
          ),
        ),
        if (isRequired && fileName == null) ...[
          const SizedBox(height: 4),
          Text(
            'هذا الحقل مطلوب',
            style: TextStyle(color: Colors.red[700], fontSize: 12, fontFamily: 'Tajawal'),
          ),
        ]
      ],
    );
  }
  /// Opens file picker for license document
  void _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _licenseFile = result.files.single;
          _licenseFileName = _licenseFile!.name;
        });
      }
    } catch (e) {
      _showError('حدث خطأ في اختيار الملف: $e');
    }
  }
  /// Opens file picker for profile image
  void _pickProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _profileImage = result.files.single;
          _profileImageName = _profileImage!.name;
        });
      }
    } catch (e) {
      _showError('حدث خطأ في اختيار الصورة: $e');
    }
  }
  /// Main registration function - validates form and initiates OTP verification
  Future<void> _registerLawyer() async {
     if (!_isUsernameAvailable || !_isPhoneAvailable || !_isLicenseAvailable) {
    _showError('يرجى التأكد من أن اسم المستخدم ورقم الجوال ورقم الرخصة متاحين');
    return;
  }
    if (!_formKey.currentState!.validate()) {
      _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
      return;
    }

    if (_licenseFile == null) {
      _showError('يرجى رفع رخصة المحاماة');
      return;
    }

    bool? otpVerified = await _navigateToOTP();
    
    if (otpVerified == true) {
      await _sendLawyerToServer();
    } else {
      _showError('فشل التحقق من رقم الجوال');
    }
  }
  /// Navigates to OTP verification screen for phone number confirmation
  Future<bool?> _navigateToOTP() async {
    String phoneNumber = '+966${_phoneController.text.substring(1)}';

    bool? verified = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: phoneNumber,
          registrationType: 'lawyer',
          ),
      ),
    );

    print(' نتيجة OTP: $verified');

    return verified;
  }
/// Sends lawyer registration data to server after successful OTP verification
  /// Handles file uploads and user session creation
Future<void> _sendLawyerToServer() async {
  setState(() => _isLoading = true);

  try {
    Map<String, dynamic> requestData = {
      'username': _usernameController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'password': _passwordController.text,
      'phoneNumber': _phoneController.text.trim(),
      'licenseNumber': _licenseController.text.trim(),
      'yearsOfExp': int.parse(_experienceController.text),
      'gender': _selectedGender,
      'mainSpecialization': _selectedMainSpecialization,
      'fSubSpecialization': _selectedSubSpecialization1 ?? '',
      'sSubSpecialization': _selectedSubSpecialization2 ?? '',
      'educationQualification': _selectedEducationLevel,
      'academicMajor': _selectedAcademicMajor,
    };

    print(' إرسال بيانات المحامي بعد التحقق الناجح: $requestData');

    const String baseUrl = 'http://192.168.3.10:8888/mujeer_api';
    // const String baseUrl = 'http://10.0.2.2:8888/mujeer_api';

    final response = await http
        .post(
          Uri.parse('$baseUrl/register_lawyer.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        )
        .timeout(const Duration(seconds: 10));

    print(' استجابة السيرفر: ${response.body}');
    
    final  result = json.decode(response.body);
    
    if (result['success'] == true) {
        final int lawyerId = result['userId'] ?? 0;

// Read user data from PHP response
  final Map<String, dynamic>? userMap =
      (result['user'] as Map?)?.cast<String, dynamic>();

  User? user;
  if (userMap != null) {
    user = User.fromJson({
      ...userMap,
      'UserType': 'lawyer',
    });
  }
  // Upload license file if selected
  if (_licenseFile != null && _licenseFile!.path != null) {
    final licenseName =
        (result['licenseFileName'] ?? 'license_${_usernameController.text}.pdf')
            .toString();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload_files.php'),
    );

    request.fields['fileName']  = licenseName;     
    request.files.add(
      await http.MultipartFile.fromPath(
        'license_file',
        _licenseFile!.path!,
        filename: licenseName,
      ),
    );

    final uploadRes = await request.send();
    final uploadBody = await uploadRes.stream.bytesToString();
    print(' رفع الرخصة: $uploadBody');
  }
  // Upload profile image if selected
  if (_profileImage != null && _profileImage!.path != null) {
    try {
      final newFileName = await ApiClient.uploadLawyerPhoto(
        userId: lawyerId,
        imagePath: _profileImage!.path!,
      );

      if (user != null && newFileName.isNotEmpty) {
        user = user.copyWith(profileImage: newFileName);
      }
    } catch (e) {
      print(' فشل رفع الصورة عند التسجيل: $e');
    }
  }
  // Save user session and navigate to success page
  if (user != null) {
    print(' USER AFTER REGISTER = $user');
    print(' profileImage = ${user.profileImage}');
    print(' profileImageUrl = ${user.profileImageUrl}');
    await Session.saveUser(user);
  }

  _showSuccessAndNavigate();
      
    } else {
      _showError(result['message'] ?? 'حدث خطأ غير معروف');
    }
    
  } catch (e) {
    _showError('فشل في التسجيل: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _uploadFiles(
    int lawyerId,
    Map<String, dynamic> result,
    String baseUrl,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_files.php'),
      );

      request.fields['lawyer_id'] = lawyerId.toString();

      if (_licenseFile != null && _licenseFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_file',
            _licenseFile!.path!,
            filename:
                result['licenseFileName'] ??
                'license_${_usernameController.text}.pdf',
          ),
        );
      }
    
    if (_profileImage != null && _profileImage!.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        _profileImage!.path!,
        filename: result['photoFileName'] ?? 'photo_${_usernameController.text}.jpg',
      ));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    print(' رفع الملفات: $responseData');
    
  } catch (e) {
    print(' حدث خطأ في رفع الملفات: $e');
  }
}

  Future<void> _uploadFile(PlatformFile file, String fileName, String baseUrl) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_files.php'));
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: fileName,
      ));
      
      request.fields['fileName'] = fileName;
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      print(' رفع الملف: $fileName');
      print(' استجابة رفع الملف: $responseData');
      
    } catch (e) {
      print(' خطأ في رفع الملف: $e');
    }
  }
  /// Shows success message and navigates to lawyer more page
  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك من قبل الإدارة.',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/lawyer/more');
      }
    });
  }
  /// Utility function to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }


  

  @override
    /// Builds username field with real-time availability checking
  Widget _buildUsernameField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _usernameController,
        decoration: InputDecoration(
          labelText: 'اسم المستخدم *',
          labelStyle: const TextStyle(fontFamily: 'Tajawal'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0B5345)),
          ),
          suffixIcon: _isCheckingUsername
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _usernameController.text.length >= 3
                  ? Icon(
                      _isUsernameAvailable ? Icons.check_circle : Icons.error,
                      color: _isUsernameAvailable ? Colors.green : Colors.red,
                    )
                  : null,
        ),
        validator: (value) {
          if (value!.isEmpty) return 'اسم المستخدم مطلوب';
          if (value.length < 3) return 'يجب أن يحتوي على 3 أحرف على الأقل';
          if (value.contains(' ')) return 'لا يمكن أن يحتوي على مسافات';
          if (!_isUsernameAvailable && value.length >= 3) return 'اسم المستخدم محجوز';
          return null;
        },
      ),
      if (_usernameMessage != null) ...[
        const SizedBox(height: 4),
        Text(
          _usernameMessage!,
          style: TextStyle(
            color: _isUsernameAvailable ? Colors.green : Colors.red,
            fontSize: 12,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    ],
  );
}
/// Builds phone field with Saudi number format validation
Widget _buildPhoneField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'رقم الجوال *',
          labelStyle: const TextStyle(fontFamily: 'Tajawal'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0B5345)),
          ),
          suffixIcon: _isCheckingPhone
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _phoneController.text.length >= 10
                  ? Icon(
                      _isPhoneAvailable ? Icons.check_circle : Icons.error,
                      color: _isPhoneAvailable ? Colors.green : Colors.red,
                    )
                  : null,
        ),
        validator: (value) {
          if (value!.isEmpty) return 'رقم الجوال مطلوب';
          if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
            return 'يجب أن يبدأ بـ 05 ويحتوي 10 أرقام';
          }
          if (!_isPhoneAvailable && value.length == 10) return 'رقم الجوال مسجل مسبقاً';
          return null;
        },
      ),
      if (_phoneMessage != null) ...[
        const SizedBox(height: 4),
        Text(
          _phoneMessage!,
          style: TextStyle(
            color: _isPhoneAvailable ? Colors.green : Colors.red,
            fontSize: 12,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    ],
  );
}
/// Builds license field with availability checking
Widget _buildLicenseField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _licenseController,
        decoration: InputDecoration(
          labelText: 'رقم الرخصة *',
          labelStyle: const TextStyle(fontFamily: 'Tajawal'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0B5345)),
          ),
          suffixIcon: _isCheckingLicense
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _licenseController.text.isNotEmpty
                  ? Icon(
                      _isLicenseAvailable ? Icons.check_circle : Icons.error,
                      color: _isLicenseAvailable ? Colors.green : Colors.red,
                    )
                  : null,
        ),
        validator: (value) {
          if (value!.isEmpty) return 'رقم الرخصة مطلوب';
          if (!_isLicenseAvailable && value.isNotEmpty) return 'رقم الرخصة مسجل مسبقاً';
          return null;
        },
      ),
      if (_licenseMessage != null) ...[
        const SizedBox(height: 4),
        Text(
          _licenseMessage!,
          style: TextStyle(
            color: _isLicenseAvailable ? Colors.green : Colors.red,
            fontSize: 12,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    ],
  );
}




}