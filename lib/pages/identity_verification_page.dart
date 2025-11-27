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
 /// Verifies username existence and navigates to OTP screen for password reset
  /// Handles user lookup, phone number formatting, and error scenarios
  void _verifyUsername() async {
  if (_usernameController.text.isEmpty) {
    _showError('يرجى إدخال اسم المستخدم');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // API call to check if username exists in database
    final user = await ApiClient.getUserByUsername(_usernameController.text.trim());
    
    if (user == null) {
      _showError('لم يتم العثور على اسم المستخدم');
      return;
    }
// Convert local phone number to international format for OTP service
    String formattedNumber = _convertToInternationalFormat(user.phoneNumber);
    // Validate the formatted phone number
    if (formattedNumber.isEmpty || !formattedNumber.startsWith('+966')) {
      _showError('رقم الجوال غير صالح لإرسال الرمز');
      return;
    }
// Navigate to OTP screen with password reset context
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: formattedNumber,
          isPasswordReset: true, // Flag to indicate password reset flow
          username: _usernameController.text.trim(), // Pass username for the reset process
        ),
      ),
    );
  } catch (e) {
    _showError('فشل في التحقق من اسم المستخدم: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
/// Converts Saudi phone numbers to international format
  String _convertToInternationalFormat(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.startsWith('05') && cleanNumber.length == 10) {
      return '+966${cleanNumber.substring(1)}';
    }
    
    else if (cleanNumber.startsWith('5') && cleanNumber.length == 9) {
      return '+966$cleanNumber';
    }
    
    else if (cleanNumber.startsWith('966') && cleanNumber.length == 12) {
      return '+$cleanNumber';
    }
    // Invalid format
    else {
      return '';
    }
  }
/// Displays error messages to the user
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
            // Identity verification card with instructions
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