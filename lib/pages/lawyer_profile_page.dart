import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/session.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class LawyerProfilePage extends StatefulWidget {
  const LawyerProfilePage({super.key});

  @override
  State<LawyerProfilePage> createState() => _LawyerProfilePageState();
}

class _LawyerProfilePageState extends State<LawyerProfilePage> {
  // Controllers
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl    = TextEditingController();
  final TextEditingController _passCtrl     = TextEditingController();
  final TextEditingController _expCtrl      = TextEditingController(); // سنوات الخبرة
  final TextEditingController _confirmPassCtrl = TextEditingController();


  // قوائم الإختيارات (Dropdown)
  String? _selectedMainSpec;
  String? _selectedSubSpec1;
  String? _selectedSubSpec2;
  String? _selectedDegree;
  String? _selectedAcademicMajor;

  bool _obscurePassword = true;
  bool _isSaving = false;
  User? _user;

  // القيم المتاحة للتخصصات والمؤهل
  final List<String> _mainSpecializations = [
    'عقاري',
    'قضايا العمالة',
    'جنائي',
    'تجاري',
    'اسري',
    'عمل',
    'أحوال شخصية',
    'اداري',
    'ملكية فكرية',
  ];

  final List<String> _subSpecializations = [
    'عقاري',
    'قضايا العمالة',
    'جنائي',
    'تجاري',
    'اسري',
    'عمل',
    'أحوال شخصية',
    'اداري',
    'ملكية فكرية',
  ];

  final List<String> _educationLevels = [
    'بكالوريوس',
    'ماجستير',
    'دكتوراه',
    'دبلوم',
  ];

  final List<String> _academicMajors = [
    'شريعة',
    'قانون',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await Session.getUser();
    if (!mounted) return;

    setState(() {
      _user = u;

      if (u != null) {
        // 🟢 بيانات عامة
        _usernameCtrl.text = u.username;
        _phoneCtrl.text    = u.phoneNumber;

        // 🟣 بيانات المحامي الإضافية
        _expCtrl.text            = u.yearsOfExp?.toString() ?? '';
        _selectedMainSpec       = u.mainSpecialization;
        _selectedSubSpec1       = u.fSubSpecialization;
        _selectedSubSpec2       = u.sSubSpecialization;
        _selectedDegree         = u.educationQualification;
        _selectedAcademicMajor  = u.academicMajor;
      } else {
        _usernameCtrl.clear();
        _phoneCtrl.clear();
        _expCtrl.clear();
        _selectedMainSpec      = null;
        _selectedSubSpec1      = null;
        _selectedSubSpec2      = null;
        _selectedDegree        = null;
        _selectedAcademicMajor = null;
      }

      _passCtrl.clear(); // ما نعرض الباسوورد أبداً
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _save() async {
    if (_user == null) {
      _showError('لا يوجد مستخدم مسجل حالياً');
      return;
    }

    final username = _usernameCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final expText  = _expCtrl.text.trim();

    if (username.isEmpty) {
      _showError('اسم المستخدم مطلوب');
      return;
    }

    if (phone.isEmpty || !RegExp(r'^05\d{8}$').hasMatch(phone)) {
      _showError('رقم الجوال يجب أن يبدأ بـ 05 ويتكون من 10 أرقام');
      return;
    }

    if (_selectedMainSpec == null) {
      _showError('يرجى اختيار التخصص الرئيسي');
      return;
    }

    if (_selectedDegree == null) {
      _showError('يرجى اختيار المؤهل العلمي');
      return;
    }

    if (_selectedAcademicMajor == null) {
      _showError('يرجى اختيار التخصص الأكاديمي');
      return;
    }

    int? yearsOfExp;
    if (expText.isNotEmpty) {
      final parsed = int.tryParse(expText);
      if (parsed == null) {
        _showError('سنوات الخبرة يجب أن تكون رقم صحيح');
        return;
      }
      yearsOfExp = parsed;
    }

    // تجهيز البيانات للإرسال
    final Map<String, dynamic> payload = {
      'userId'               : _user!.id,
      'username'             : username,
      'phoneNumber'          : phone,
      'yearsOfExp'           : yearsOfExp,
      'mainSpecialization'   : _selectedMainSpec,
      'fSubSpecialization'   : _selectedSubSpec1,
      'sSubSpecialization'   : _selectedSubSpec2,
      'educationQualification': _selectedDegree,
      'academicMajor'        : _selectedAcademicMajor,
    };

    // لو الباسوورد مو فاضي → نضيفه
    final newPass = _passCtrl.text.trim();
    if (newPass.isNotEmpty) {
      payload['password'] = newPass;
    }

    // نحذف الحقول الفاضية/null عشان PHP يحدث بس اللي نرسله
    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('${ApiClient.base}/update_lawyer_profile.php');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('UPDATE RESPONSE status: ${res.statusCode}');
      print('UPDATE RESPONSE body: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _showError('حدث خطأ في الاتصال بالسيرفر: ${res.statusCode}');
        return;
      }

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        // نحدّث الـ Session باليوزر الجديد
        if (body['user'] != null) {
          final updatedUser = User.fromJson(body['user']);
          await Session.saveUser(updatedUser);
          setState(() {
            _user = updatedUser;
          });
        }

        _showSuccess(body['message'] ?? 'تم تحديث البيانات بنجاح');
        // اختياري: نرجع لصفحة more
        // Navigator.pop(context);
      } else {
        _showError(body['message'] ?? 'فشل في تحديث البيانات');
      }
    } catch (e) {
      _showError('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


void _toast(String msg, {bool success = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
      backgroundColor: success ? Colors.green : Colors.red,
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

  // 1) أول Dialog يطلب كلمة المرور
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تأكيد حذف الحساب',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
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
                      content: Text('يجب إدخال كلمة المرور لحذف الحساب'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5345),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (ok != true) return;

  try {
    // 2) نرسل طلب الحذف للسيرفر
    final body = await ApiClient.deleteAccount(
      userId: u.id,
      userType: u.userType, // "lawyer"
      password: _confirmPassCtrl.text,
    );

    if (!mounted) return;

    final success = body['success'] == true;
    final code = body['code'] as String?;
    final msg = (body['message'] ?? '').toString();

    // --- مجموعات الأكواد عشان نغطي client + lawyer لو استخدمتي نفس الأسماء ---
    const activeCodes = ['HAS_ACTIVE', 'LAWYER_HAS_ACTIVE'];
    const upcomingCodes = ['HAS_UPCOMING', 'LAWYER_HAS_UPCOMING'];
    const pointsCodes = ['HAS_POINTS', 'LAWYER_HAS_POINTS'];

    // ===== مواعيد نشطة =====
    if (!success && activeCodes.contains(code)) {
      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'لا يمكن حذف الحساب (موعد نشط)',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Text(
                msg.isNotEmpty
                    ? msg
                    : 'لديك مواعيد نشطة، قم بإكمالها أو إلغائها قبل إيقاف الحساب.',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // ===== مواعيد قادمة =====
    if (!success && upcomingCodes.contains(code)) {
      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'لا يمكن حذف الحساب (موعد قادم)',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Text(
                msg.isNotEmpty
                    ? msg
                    : 'لديك مواعيد قادمة، قم بإلغائها أو انتظار انتهائها قبل إيقاف الحساب.',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // ===== حالة وجود نقاط في المحفظة =====
    if (!success && pointsCodes.contains(code)) {
      final points = body['points']?.toString() ?? '0';

      final confirmForce = await showDialog<bool>(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'رصيد غير مسترد في المحفظة',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Text(
                'لديك نقاط في محفظتك بقيمة ($points نقطة).\n'
                'عند حذف الحساب سيتم فقدان هذه النقاط نهائياً، هل ما زلت متأكداً من حذف الحساب؟',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'تراجع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'حذف ',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (confirmForce != true) return;

      // إعادة الطلب مع force = true
      final body2 = await ApiClient.deleteAccount(
        userId: u.id,
        userType: u.userType,
        password: _confirmPassCtrl.text,
        force: true,
      );

      if (!mounted) return;

      if (body2['success'] == true) {
        await Session.clear();
        await showDialog(
          context: context,
          builder: (_) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'تم حذف الحساب (مع فقدان النقاط)',
                  style:
                      TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                content: Text(
                  (body2['message'] ?? 'تم حذف الحساب بنجاح').toString(),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/welcome', (_) => false);
        return;
      } else {
        await showDialog(
          context: context,
          builder: (_) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'خطأ في حذف الحساب',
                  style:
                      TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                content: Text(
                  (body2['message'] ?? 'فشل حذف الحساب').toString(),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        return;
      }
    }

    // ===== نجاح الحذف العادي =====
    if (success) {
      await Session.clear();

      await showDialog(
        context: context,
        builder: (_) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'تم حذف الحساب',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Text(
                msg.isNotEmpty ? msg : 'تم حذف الحساب بنجاح.',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      Navigator.of(context)
          .pushNamedAndRemoveUntil('/welcome', (_) => false);
    } else {
      // أي خطأ آخر عام
      await showDialog(
        context: context,
        builder: (_) {
          String title = 'خطأ في الحذف';

          if (activeCodes.contains(code)) {
            title = 'لا يمكن حذف الحساب (موعد نشط)';
          } else if (upcomingCodes.contains(code)) {
            title = 'لا يمكن حذف الحساب (موعد قادم)';
          } else if (pointsCodes.contains(code)) {
            title = 'رصيد غير مسترد في المحفظة';
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                title,
                style: const TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Text(
                msg.isNotEmpty ? msg : 'فشل حذف الحساب، حاول مرة أخرى.',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  } catch (e) {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'خطأ غير متوقع',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
            content: Text(
              e.toString(),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            'الملف الشخصي (محامي)',
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

              // 🟢 اسم المستخدم
              TextField(
                controller: _usernameCtrl,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('اسم المستخدم'),
              ),
              const SizedBox(height: 16),

              // 🟢 رقم الجوال
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('رقم الجوال').copyWith(
                  hintText: '05XXXXXXXX',
                ),
              ),
              const SizedBox(height: 16),

              // 🟢 كلمة المرور (اختياري للتغيير)
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('كلمة المرور (اختياري)').copyWith(
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

              const SizedBox(height: 24),

              // 🟣 سنوات الخبرة
              TextField(
                controller: _expCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('سنوات الخبرة'),
              ),
              const SizedBox(height: 16),

              // 🟣 التخصص الرئيسي (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedMainSpec,
                items: _mainSpecializations.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMainSpec = value);
                },
                decoration: _inputDecoration('التخصص الرئيسي'),
              ),
              const SizedBox(height: 16),

              // 🟣 التخصص الفرعي الأول (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedSubSpec1,
                items: _subSpecializations.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubSpec1 = value);
                },
                decoration: _inputDecoration('التخصص الفرعي الأول'),
              ),
              const SizedBox(height: 16),

              // 🟣 التخصص الفرعي الثاني (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedSubSpec2,
                items: _subSpecializations.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubSpec2 = value);
                },
                decoration: _inputDecoration('التخصص الفرعي الثاني'),
              ),
              const SizedBox(height: 16),

              // 🟣 المؤهل العلمي
              DropdownButtonFormField<String>(
                value: _selectedDegree,
                items: _educationLevels.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDegree = value);
                },
                decoration: _inputDecoration('المؤهل العلمي'),
              ),
              const SizedBox(height: 16),

              // 🟣 التخصص الأكاديمي
              DropdownButtonFormField<String>(
                value: _selectedAcademicMajor,
                items: _academicMajors.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(fontFamily: 'Tajawal')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAcademicMajor = value);
                },
                decoration: _inputDecoration('التخصص الأكاديمي'),
              ),

              const SizedBox(height: 40),

              // زر حفظ
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
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
