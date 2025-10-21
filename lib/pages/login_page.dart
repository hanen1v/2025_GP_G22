import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/user.dart';
import 'requests_management_page.dart';
import '../services/session.dart';


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
              // زر العودة
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 20),
              
              // العنوان
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
              
              // حقل اسم المستخدم
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
              
              // حقل كلمة المرور
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
              
              // نسيت كلمة المرور
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    _showComingSoon(context, 'استعادة كلمة المرور');
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
              
              // زر تسجيل الدخول
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
              
              // رابط التسجيل الجديد
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
                      Navigator.pop(context);
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

  // دالة تسجيل الدخول
  void _login() async {
    // 1. التحقق من صحة البيانات
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('الرجاء تعبئة جميع الحقول');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. الاتصال الحقيقي بالسيرفر
      final user = await ApiClient.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      await Session.saveUser(user);     // ← حفظ الجلسة

      // 3. التحقق من نوع المستخدم والتوجيه للصفحة المناسبة
      _redirectBasedOnUserType(user);
      
    } catch (e) {
      // 4. معالجة الأخطاء
      _showError('فشل تسجيل الدخول: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
    // دالة توجيه المستخدم للصفحة المناسبة حسب نوعه
void _redirectBasedOnUserType(User user) {
  // التوجيه للصفحة المناسبة حسب نوع المستخدم
  if (user.isAdmin) {
    // الأدمن يروح لصفحة إدارة الطلبات
    Navigator.pushReplacementNamed(context, '/requestsManagement');
  } else if (user.isLawyer) {
    // المحامي يروح للصفحة الرئيسية
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // العميل يروح للصفحة الرئيسية
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  // عرض رسالة ترحيب أنيقة بعد الانتقال
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
              user.isAdmin ? Icons.admin_panel_settings : 
              user.isLawyer ? Icons.gavel : Icons.person,
              color: user.isAdmin ? Color(0xFF8B0000) : Color(0xFF0B5345),
            ),
            SizedBox(width: 8),
            Text(
              user.isAdmin ? 'مرحباً أيها المشرف' : 
              user.isLawyer ? 'مرحباً أيها المحامي' : 'مرحباً',
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
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.black87,
          ),
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
  

  // دالة مساعدة لتحويل نوع المستخدم للعربية
  String _getUserTypeArabic(String userType) {
    switch (userType) {
      case 'client': return 'عميل';
      case 'lawyer': return 'محامي';
      case 'admin': return 'مشرف';
      default: return 'مستخدم';
    }
  }

  // عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // رسالة "قريباً" للميزات غير الجاهزة
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قريباً'),
        content: Text('$feature سيكون متاحاً قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
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