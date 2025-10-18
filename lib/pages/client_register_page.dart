
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // controllers للحقول النصية
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                    const SizedBox(height: 40), // مسافة لأزرار التنقل
                  ],
                ),
              ),
            ),
    );
  }

  // نموذج التسجيل
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
                if (value.length < 3) return 'الاسم يجب أن يحتوي على 3 أحرف على الأقل';
                return null;
              },
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

  // زر التسجيل
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

  // تسجيل العميل
  void _registerClient() async {
    if (!_formKey.currentState!.validate()) {
      _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // إعداد البيانات للإرسال
      Map<String, dynamic> requestData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
      };

      print('📤 إرسال بيانات العميل: $requestData');

      // غيري الرابط حسب سيرفرك
      String baseUrl = 'http://192.168.3.10:8888/mujeer_api';
      
      var response = await http.post(
        Uri.parse('$baseUrl/register_client.php'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      print('📥 استجابة السيرفر: ${response.statusCode}');
      print('📦 محتوى الاستجابة: ${response.body}');

      var result = json.decode(response.body);
      
      if (result['success'] == true) {
        _showSuccess(result['message']);
        await Future.delayed(const Duration(seconds: 2));
       Navigator.pushReplacementNamed(
    context, 
    '/home',
    arguments: {
      'userType': 'client',
      'userName': _fullNameController.text,
      'username': _usernameController.text,
    }
  );
      } else {
        _showError(result['message']);
      }
      
    } catch (e) {
      print('❌ خطأ في الاتصال: $e');
      _showError('فشل في الاتصال بالسيرفر: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
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
    super.dispose();
  }
}