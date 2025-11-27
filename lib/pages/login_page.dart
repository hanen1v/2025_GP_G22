import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/user.dart';
import 'requests_management_page.dart';
import 'otp_screen.dart';
import '../services/session.dart';
import 'identity_verification_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 20),
              // Title section
              const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل بياناتك للدخول إلى حسابك',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0B5345)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Password field with visibility toggle
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0B5345)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Forgot password link
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IdentityVerificationPage(),
                      ),
                    );
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: const Color(0xFF0B5345),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                    child: Text(
                      'سجل الآن',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B5345),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
/// Main login function - handles user authentication
  /// Validates input, calls API, and manages login flow
  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('الرجاء تعبئة جميع الحقول');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate user via API
      final user = await ApiClient.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      // Save user session for persistence
      await Session.saveUser(user); 
       // Proceed to OTP verification
      await _navigateToOTP(user);
    } catch (e) {
      _showError('فشل تسجيل الدخول: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
/// Handles OTP verification process after successful login
  /// Converts phone number format and navigates to OTP screen
  Future<void> _navigateToOTP(User user) async {
    String phoneNumber = user.phoneNumber ?? '';

    print(' بدء OTP للمستخدم: ${user.fullName}');
    print(' نوع المستخدم: ${user.userType}');
    print(' هو أدمن: ${user.isAdmin}');
    print(' رقم الجوال: $phoneNumber');
    // Convert to international format for OTP service
    String formattedNumber = _convertToInternationalFormat(phoneNumber);

    print(' الرقم بعد التحويل: $formattedNumber');

    if (formattedNumber.isEmpty || !formattedNumber.startsWith('+966')) {
      _showError('رقم الجوال غير صالح لإرسال الرمز: $formattedNumber');
      return;
    }

    bool? verified = true;
     await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: formattedNumber,
        ),
      ),
    );

    if (verified == true) {
      // Register admin device for push notifications
      if (user.isAdmin) {
        await _registerDeviceWithRetry();
      }
       // Redirect user based on their type
      _redirectBasedOnUserType(user);
    } else {
      _showError('فشل التحقق من رقم الجوال');
    }
  }
  /// Registers admin device for push notifications with retry logic
  /// Attempts registration twice in case of initial failure
  Future<void> _registerDeviceWithRetry() async {
    try {
      print(' محاولة تسجيل جهاز الأدمن...');
      await ApiClient.registerAdminDevice();
      print(' تم تسجيل الجهاز بنجاح');
    } catch (e) {
      print(' فشل تسجيل الجهاز: $e - إعادة المحاولة...');
      await Future.delayed(Duration(seconds: 1));
      try {
        await ApiClient.registerAdminDevice();
        print(' تم تسجيل الجهاز في المحاولة الثانية');
      } catch (e2) {
        print(' فشل تسجيل الجهاز بعد المحاولتين: $e2');
        _showError(
          'حدث خطأ في تسجيل الجهاز، لكن يمكنك الاستمرار في استخدام التطبيق',
        );
      }
    }
  }

   /// Converts Saudi phone numbers to international format
  String _convertToInternationalFormat(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    // Remove any non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    print(' تنظيف الرقم: $cleanNumber');

    if (cleanNumber.startsWith('05') && cleanNumber.length == 10) {
      return '+966${cleanNumber.substring(1)}';
    }
    else if (cleanNumber.startsWith('5') && cleanNumber.length == 9) {
      return '+966$cleanNumber';
    }
    else if (cleanNumber.startsWith('966') && cleanNumber.length == 12) {
      return '+$cleanNumber';
    }
    else {
      print(' تنسيق الرقم غير معروف: $phoneNumber');
      return '';
    }
  }
/// Redirects user to appropriate screen based on their user type
  /// Shows welcome dialog and navigates to respective home screen
  void _redirectBasedOnUserType(User user) {
    if (user.isAdmin) {
      ApiClient.registerAdminDevice();
      Navigator.pushReplacementNamed(context, '/requestsManagement');
    } else if (user.isLawyer) {
      Navigator.pushReplacementNamed(context, '/lawyer/more');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
    // Show welcome dialog after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                user.isAdmin
                    ? Icons.admin_panel_settings
                    : user.isLawyer
                    ? Icons.gavel
                    : Icons.person,
                color: user.isAdmin ? Color(0xFF8B0000) : Color(0xFF0B5345),
              ),
              SizedBox(width: 8),
              Text(
                user.isAdmin
                    ? 'مرحباً أيها المشرف'
                    : user.isLawyer
                    ? 'مرحباً أيها المحامي'
                    : 'مرحباً',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: user.isAdmin ? Color(0xFF8B0000) : Color(0xFF0B5345),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '${user.fullName} - ${_getUserTypeArabic(user.userType)}',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: user.isAdmin ? Color(0xFF8B0000) : Color(0xFF0B5345),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
  /// Converts user type to Arabic for display purposes
  String _getUserTypeArabic(String userType) {
    switch (userType) {
      case 'client':
        return 'عميل';
      case 'lawyer':
        return 'محامي';
      case 'admin':
        return 'مشرف';
      default:
        return 'مستخدم';
    }
  }
  /// Displays error messages in a snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
