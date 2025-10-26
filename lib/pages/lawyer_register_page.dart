import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'otp_screen.dart';
import '../services/session.dart';
import '../models/user.dart';

class LawyerRegisterPage extends StatefulWidget {
  const LawyerRegisterPage({super.key});

  @override
  State<LawyerRegisterPage> createState() => _LawyerRegisterPageState();
}

class _LawyerRegisterPageState extends State<LawyerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // controllers للحقول النصية
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  
  // للملفات
  String? _licenseFileName;
  String? _profileImageName;
  PlatformFile? _licenseFile;
  PlatformFile? _profileImage;
  
  // للتخصصات (قوائم محددة)
  String? _selectedGender;
  String? _selectedMainSpecialization;
  String? _selectedSubSpecialization1;
  String? _selectedSubSpecialization2;
  String? _selectedEducationLevel;
  String? _selectedAcademicMajor;
  
  // لإظهار/إخفاء كلمة المرور
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // القوائم المحددة
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

  bool _isLoading = false;

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

  // قسم المعلومات الأساسية
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
            _buildTextFormField(
              controller: _usernameController,
              label: 'اسم المستخدم *',
              validator: (value) {
                if (value!.isEmpty) return 'اسم المستخدم مطلوب';
                if (value.length < 3) return 'اسم المستخدم يجب أن يحتوي على 3 أحرف على الأقل';
                if (value.contains(' ')) return 'اسم المستخدم لا يمكن أن يحتوي على مسافات';
                return null;
              },
            ),
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
            _buildTextFormField(
              controller: _phoneController,
              label: 'رقم الجوال *',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value!.isEmpty) return 'رقم الجوال مطلوب';
                if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                  return 'رقم الجوال يجب أن يبدأ بـ 05 ويحتوي 10 أرقام';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // قسم التخصصات
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
            _buildTextFormField(
              controller: _licenseController,
              label: 'رقم الرخصة *',
              validator: (value) => value!.isEmpty ? 'رقم الرخصة مطلوب' : null,
            ),
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

  // قسم رفع الملفات
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

  // زر التسجيل
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

  // ========== الدوال المساعدة ==========

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

  // اختيار ملف الرخصة
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

  // اختيار الصورة الشخصية
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
  //تسجيل المحامي
  Future<void> _registerLawyer() async {
  // التحقق من البيانات الأساسية
  if (!_formKey.currentState!.validate()) {
    _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
    return;
  }

  if (_licenseFile == null) {
    _showError('يرجى رفع رخصة المحاماة');
    return;
  }

  // استدعاء OTP أولاً والانتظار للنتيجة
  bool? otpVerified = await _navigateToOTP();
  
  // إذا التحقق نجح، أرسل البيانات للسيرفر
  if (otpVerified == true) {
    await _sendLawyerToServer();
  } else {
    _showError('فشل التحقق من رقم الجوال');
  }
}
  // التوجيه إلى صفحة OTP
  Future<bool?> _navigateToOTP() async {
  String phoneNumber = '+966${_phoneController.text.substring(1)}';

  // انتظار نتيجة التحقق من OTP
  bool? verified = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OTPScreen(phoneNumber: phoneNumber),
    ),
  );

  return verified; // ترجع true أو false أو null
}
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

    print('📤 إرسال بيانات المحامي بعد التحقق الناجح: $requestData');

    String baseUrl = 'http://192.168.3.10:8888/mujeer_api';
    
    var response = await http.post(
      Uri.parse('$baseUrl/register_lawyer.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    ).timeout(const Duration(seconds: 60));

    var result = json.decode(response.body);
    
    if (result['success'] == true) {
      // رفع الملفات بعد التسجيل الناجح
      if (_licenseFile != null && _licenseFile!.path != null) {
        await _uploadFile(_licenseFile!, result['licenseFileName'], baseUrl);
      }
      
      if (_profileImage != null && _profileImage!.path != null) {
        await _uploadFile(_profileImage!, result['photoFileName'], baseUrl);
      }
      
      _showSuccess('تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك من قبل الإدارة.');
      Navigator.pop(context);
    } else {
      _showError(result['message']);
    }
    
  } catch (e) {
    _showError('فشل في التسجيل: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
  // دالة مساعدة لرفع الملفات
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
      
      print('📤 رفع الملف: $fileName');
      print('📥 استجابة رفع الملف: $responseData');
      
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}