import 'package:flutter/material.dart';
import '../services/session.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.fullName,
    required this.username,
  });

  final String fullName;
  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers
  late final TextEditingController _usernameCtrl; // نعرض اليوزرنيم داخل البوكس
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscurePassword = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    // مبدئياً خليه من اللي وصل من MorePage
    _usernameCtrl = TextEditingController(text: widget.username);
    _loadUser(); // ← يسحب الاسم/الجوال الحقيقيين من الـ Session
  }

  Future<void> _loadUser() async {
    final u = await Session.getUser();
    if (!mounted) return;
    setState(() {
      _user = u;
      // نحدّث الحقول من الجلسة إذا متوفرة
      if ((u?.username ?? '').isNotEmpty) _usernameCtrl.text = u!.username;
      if ((u?.phoneNumber ?? '').isNotEmpty) _phoneCtrl.text = u!.phoneNumber;
      _passCtrl.clear(); // لا نخزن الباسوورد محليًا
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    final newUsername = _usernameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final newPass = _passCtrl.text; // ممكن يكون فاضي

    // فالديشن بسيط
    if (newUsername.isEmpty) {
      _toast('اسم المستخدم مطلوب');
      return;
    }
    if (!RegExp(r'^05\d{8}$').hasMatch(newPhone)) {
      _toast('رقم الجوال يجب أن يبدأ بـ 05 ويحتوي 10 أرقام');
      return;
    }

    final current = _user;
    if (current == null) {
      _toast('لم يتم تحميل بيانات المستخدم');
      return;
    }

    try {
      // استدعاء API
      final updated = await ApiClient.updateProfile(
        userId: current.id,
        userType: current.userType, // 'client' أو 'lawyer'
        username: newUsername,
        phoneNumber: newPhone,
        newPassword: newPass.isNotEmpty ? newPass : null,
      );

      // حدث الجلسة محليًا
      await Session.saveUser(updated);

      // نظّف حقل الباسوورد
      _passCtrl.clear();

      if (!mounted) return;
      _toast('تم حفظ التعديلات بنجاح', success: true);
      // اختياري: ارجعي شاشة وراء
      // Navigator.pop(context);
    } catch (e) {
      _toast('فشل حفظ التعديلات: $e');
    }
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmDelete() async {
  final u = _user;
  if (u == null) {
    _toast('لم يتم تحميل بيانات المستخدم');
    return;
  }

  _confirmPassCtrl.clear();

  // 1) نطلب من المستخدم كلمة المرور أولاً
  final passwordOk = await showDialog<bool>(
    context: context,
    builder: (_) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف الحساب',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'هل أنت متأكد من حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه.',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF0B5345),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_confirmPassCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'يجب إدخال كلمة المرور',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5345),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'متابعة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (passwordOk != true) return;

  try {
    // 2) محاولة حذف الحساب
    final result = await ApiClient.deleteAccount(
      userId: u.id,
      userType: u.userType,
      password: _confirmPassCtrl.text,
    );

    if (result['success'] == true) {
      // ✅ تم الحذف فعلاً
      await Session.clear();
      if (!mounted) return;
      _toast('تم حذف الحساب بنجاح', success: true);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/welcome', (_) => false);
      return;
    }

    final code = (result['code'] ?? '').toString();
    final message =
        (result['message'] ?? 'فشل حذف الحساب').toString();

    // 3) عنده موعد نشط
    if (code == 'HAS_ACTIVE') {
      await showDialog<void>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'لا يمكن حذف الحساب (موعد نشط)',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,),
            ),
            content: Text(
              message,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF0B5345),
                    fontWeight: FontWeight.bold,),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 4) عنده مواعيد قادمة
    if (code == 'HAS_UPCOMING') {
      await showDialog<void>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'لا يمكن حذف الحساب (موعد قادم)',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,),
            ),
            content: Text(
              message,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF0B5345),
                    fontWeight: FontWeight.bold,),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 5) عنده مبلغ في المحفظة (بوينتس)
    if (code == 'HAS_POINTS') {
      final confirmForce = await showDialog<bool>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'رصيد غير مسترد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color.fromARGB(255, 148, 148, 148),
                    fontWeight: FontWeight.bold,),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'نعم، حذف الحساب',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF0B5345),
                    fontWeight: FontWeight.bold,),
                ),
              ),
            ],
          ),
        ),
      );

      if (confirmForce == true) {
        final forceResult = await ApiClient.deleteAccount(
          userId: u.id,
          userType: u.userType,
          password: _confirmPassCtrl.text,
          force: true,
        );

        if (forceResult['success'] == true) {
          await Session.clear();
          if (!mounted) return;
          _toast('تم حذف الحساب بنجاح', success: true);
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/welcome', (_) => false);
        } else {
          final m =
              (forceResult['message'] ?? 'فشل حذف الحساب').toString();
          _toast(m);
        }
      }

      return;
    }

    // 6) أي خطأ آخر غير متوقع
    _toast(message);
  } catch (e) {
    _toast('فشل حذف الحساب: $e');
  }
}





  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Username
              TextField(
                controller: _usernameCtrl,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('اسم المستخدم'),
              ),
              const SizedBox(height: 16),

              // رقم الجوال
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: _inputDecoration(
                  'رقم الجوال',
                ).copyWith(hintText: '05XXXXXXXX'),
              ),
              const SizedBox(height: 16),

              // كلمة المرور (اختياري للتغيير)
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('كلمة المرور').copyWith(
                  hintText: 'اتركه فارغًا إذا لا تريد تغييره',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // زر حفظ (عرض فقط الآن)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // حذف حسابي ()
              Center(
                child: TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'حذف حسابي',
                    style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: FloatingLabelAlignment.start,
      labelStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 13,
        color: Colors.grey,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        gapPadding: 4,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
        gapPadding: 4,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0B5345), width: 1.5),
        gapPadding: 4,
      ),
    );
  }
}
