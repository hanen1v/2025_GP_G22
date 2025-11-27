import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_screen.dart';
import '../services/session.dart';
import '../models/user.dart';

class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isCheckingUsername = false;
  bool _isCheckingPhone = false;
  bool _isUsernameAvailable = false;
  bool _isPhoneAvailable = false;
  String? _usernameMessage;
  String? _phoneMessage;

  @override
  void initState() {
    super.initState();
     // Add listeners for real-time validation
    _usernameController.addListener(_checkUsernameAvailability);
    _phoneController.addListener(_checkPhoneAvailability);
  }

  @override
  void dispose() {
    // Clean up controllers and listeners
    _usernameController.removeListener(_checkUsernameAvailability);
    _phoneController.removeListener(_checkPhoneAvailability);

    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();

    super.dispose();
  }
 /// Checks username availability in real-time by making API call
  /// Shows loading indicator and validation messages
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
        body: json.encode({'username': username, 'userType': 'client'}),
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
/// Validates phone number format and checks if it's already registered
  /// Uses regex to ensure Saudi mobile number format (05XXXXXXXX)
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
        //Uri.parse('http://192.168.3.10:8888/mujeer_api/check_availability.php'),
        Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),

        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phone, 'userType': 'client'}),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تسجيل عميل جديد',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRegisterForm(),
                    const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
/// Builds the main registration form card with all input fields
  Widget _buildRegisterForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('معلومات التسجيل'),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _fullNameController,
              label: 'الاسم الكامل *',
              validator: (value) {
                if (value!.isEmpty) return 'الاسم الكامل مطلوب';
                if (value.length < 3)
                  return 'الاسم يجب أن يحتوي على 3 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildUsernameField(),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _passwordController,
              label: 'كلمة المرور *',
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) {
                if (value!.isEmpty) return 'كلمة المرور مطلوبة';
                if (value.length < 6)
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور *',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (value) {
                if (value!.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (value != _passwordController.text)
                  return 'كلمة المرور غير متطابقة';
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
 /// Builds username field with real-time availability checking
  /// Shows loading indicator and validation icons
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
            if (!_isUsernameAvailable && value.length >= 3)
              return 'اسم المستخدم محجوز';
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
/// Builds phone number field with Saudi format validation
  /// Shows real-time availability status
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
            if (!_isPhoneAvailable && value.length == 10)
              return 'رقم الجوال مسجل مسبقاً';
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
/// Builds the main registration button
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _registerClient,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5345),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'تسجيل العميل',
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

  // ========== HELPER FUNCTIONS  ==========
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
  /// Reusable text form field builder with consistent styling
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
/// Main registration validation and processing function
  /// Validates form and checks availability before proceeding to OTP
  void _registerClient() async {
    if (!_formKey.currentState!.validate()) {
      _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
      return;
    }

    if (!_isUsernameAvailable || !_isPhoneAvailable) {
      _showError('يرجى التأكد من أن اسم المستخدم ورقم الجوال متاحين');
      return;
    }

    _navigateToOTP();
  }/// Navigates to OTP verification screen
  /// Converts phone number to international format for OTP service

  void _navigateToOTP() async {
    String phoneNumber = '+966${_phoneController.text.substring(1)}';

    bool? verified = true;
    await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OTPScreen(
        phoneNumber: phoneNumber,
        registrationType: 'client',
      ),
    ),
  );

    if (verified == true) {
      await _registerInDatabase();
    } else {
      _showError('فشل التحقق من رقم الجوال');
    }
  }
/// Final registration step - sends data to server after OTP verification
  /// Creates user session on successful registration
  Future<void> _registerInDatabase() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> requestData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
      };

      print(' إرسال بيانات العميل بعد التحقق: $requestData');

      String baseUrl = 'http://10.0.2.2:8888/mujeer_api';
      //String baseUrl = 'http://192.168.3.10:8888/mujeer_api';

      var response = await http
          .post(
            Uri.parse('$baseUrl/register_client.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 10));

      var result = json.decode(response.body);

      if (result['success'] == true) {
        final Map<String, dynamic>? userMap = result['user'];

        if (userMap != null) {
          final user = User.fromJson(userMap);
          await Session.saveUser(user); 
        }

        _showSuccess('تم إنشاء الحساب بنجاح!');

        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'userType': 'client',
            'userName': _fullNameController.text,
            'username': _usernameController.text,
          },
        );
      } else {
        _showError(result['message'] ?? 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      _showError('فشل في التسجيل: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
/// Utility function to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
/// Utility function to show success messages
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
