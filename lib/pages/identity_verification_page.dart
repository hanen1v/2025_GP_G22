import 'package:flutter/material.dart';
import 'otp_screen.dart';
import '../services/api_client.dart';

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() => _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  void _verifyUsername() async {
  if (_usernameController.text.isEmpty) {
    _showError('يرجى إدخال اسم المستخدم');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // استخدام الدالة الجديدة
    final user = await ApiClient.getUserByUsername(_usernameController.text.trim());
    
    if (user == null) {
      _showError('لم يتم العثور على اسم المستخدم');
      return;
    }

    // تحويل الرقم للتنسيق الدولي
    String formattedNumber = _convertToInternationalFormat(user.phoneNumber);
    
    if (formattedNumber.isEmpty || !formattedNumber.startsWith('+966')) {
      _showError('رقم الجوال غير صالح لإرسال الرمز');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: formattedNumber,
          isPasswordReset: true,
          username: _usernameController.text.trim(),
        ),
      ),
    );
  } catch (e) {
    _showError('فشل في التحقق من اسم المستخدم: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  String _convertToInternationalFormat(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    // إزالة أي مسافات أو أحرف خاصة
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // إذا الرقم يبدأ بـ 05 (سعودي)
    if (cleanNumber.startsWith('05') && cleanNumber.length == 10) {
      return '+966${cleanNumber.substring(1)}';
    }
    
    // إذا الرقم يبدأ بـ 5 (بدون صفر)
    else if (cleanNumber.startsWith('5') && cleanNumber.length == 9) {
      return '+966$cleanNumber';
    }
    
    // إذا الرقم يبدأ بـ +966 (محول مسبقاً)
    else if (cleanNumber.startsWith('966') && cleanNumber.length == 12) {
      return '+$cleanNumber';
    }
    
    // إذا الرقم غير معروف
    else {
      return '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'استعادة كلمة المرور',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة التحقق
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التحقق من الهوية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B5345),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل اسم المستخدم الخاص بك للتحقق وإعادة تعيين كلمة المرور',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0B5345)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // زر التحقق
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5345),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تحقق',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}