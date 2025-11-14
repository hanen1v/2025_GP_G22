import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/lawyer_bottom_nav.dart';
import '../services/session.dart';
import '../models/user.dart';
import 'lawyer_profile_page.dart';
import 'dart:async'; //(Timer)
import '../services/api_client.dart';
import 'lawyer_update_license_page.dart';


class LawyerMorePage extends StatefulWidget {
  const LawyerMorePage({super.key});

  @override
  State<LawyerMorePage> createState() => _LawyerMorePageState();
}

class _LawyerMorePageState extends State<LawyerMorePage> {
  User? _user;
  String? _status;              // Approved / Pending / Rejected
  bool _loadingStatus = true;   // لعرض السبينر أثناء التحميل
  Timer? _pollTimer;            // مؤقت التحديث التلقائي


  @override
void initState() {
  super.initState();
  _loadUser();
}


@override
void dispose() {
  _pollTimer?.cancel();
  super.dispose();
}


  Future<void> _loadUser() async {
  final u = await Session.getUser();
  if (!mounted) return;
  setState(() => _user = u);

  // تحميل أولي للحالة
  await _loadStatus();

  // تحديث تلقائي كل 20 ثانية
  _pollTimer?.cancel();
  _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
    if (mounted) _loadStatus();
  });
}


Future<void> _loadStatus() async {
  final u = _user;
  if (u == null || !u.isLawyer) {
    setState(() { _status = null; _loadingStatus = false; });
    return;
  }
  try {
    final s = await ApiClient.getLawyerStatus(u.id);
    if (!mounted) return;
    setState(() {
      _status = s;
      _loadingStatus = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _status = null; // فشل الجلب
      _loadingStatus = false;
    });
  }
}


  Future<void> _logout() async {
    try { await Session.clear(); } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
  }


    void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changePhoto() async {
    if (_user == null) {
      _toast('لم يتم تحميل بيانات المستخدم');
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (picked == null || picked.files.single.path == null) return;

    final file = picked.files.single;

    try {
      // نرفع الصورة للسيرفر
      final newFileName = await ApiClient.uploadLawyerPhoto(
        userId: _user!.id,
        imagePath: file.path!,
      );

      // نحدّث اليوزر في السشن
      final updated = _user!.copyWith(profileImage: newFileName);
      await Session.saveUser(updated);

      setState(() => _user = updated);

      _toast('تم تحديث الصورة بنجاح', success: true);
    } catch (e) {
      _toast('حدث خطأ أثناء رفع الصورة: $e');
    }
  }


  // خريطة ألوان ونصوص للحالة (تستقبل القيمة المطبّعة)
  (String text, Color fg, Color bg, IconData icon) _style(String s) {
  const iconColor = Color(0xFF0B5345); 

  if (s == 'Approved') {
    return ('تم القبول', Colors.green.shade800, Colors.green.withOpacity(.12), Iconsax.verify5);
  } else if (s == 'Rejected') {
    return ('تم الرفض', Colors.red.shade800, Colors.red.withOpacity(.12), Iconsax.close_circle);
  } else {
    return ('قيد المراجعة', Colors.orange.shade800, Colors.orange.withOpacity(.15), Iconsax.clock);
  }
}


  @override
  Widget build(BuildContext context) {
    final fullName = _user?.fullName ?? 'ضيف';
    final username = _user?.username ?? '';
    final points   = _user?.points ?? 0;

    // الحالة المطبّعة من الموديل (User.statusNormalized)
    final (label, fg, bg, icon) = _style(_status ?? 'Pending');


    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
         title: const Text('المزيد'),
        automaticallyImplyLeading: false,
       ),

        backgroundColor: const Color(0xFFF8F9FA),

        body: RefreshIndicator(                 // اختياري: سحب للتحديث
          onRefresh: _loadUser,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
                          const SizedBox(height: 8),

            // صورة المحامي في الأعلى
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (_user != null &&
                            _user!.profileImageUrl.isNotEmpty)
                        ? NetworkImage(_user!.profileImageUrl)
                        : null,
                    child: (_user == null ||
                            _user!.profileImageUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _changePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Color(0xFF0B5345),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

              // بطاقة الملف الشخصي
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Iconsax.profile_remove, color: Color(0xFF0B5345)),
                  title: const Text('الملف الشخصي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 16, color: Colors.black)),
                  subtitle: Text(fullName, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.black54)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
  if (_user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سجّل دخول أولاً')),
    );
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LawyerProfilePage()),
  );
  if (!mounted) return;
  _loadUser(); // لو بعدين عدلنا ورجع من الصفحة نحدّث البيانات
},
                ),
              ),

              const SizedBox(height: 12),

              // بطاقة حالة الحساب (من الجلسة مباشرة)
              // بطاقة حالة الحساب (تتحدث لحظياً)
Card(
  color: Colors.white,
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: Color(0xFF0B5345)),
        const SizedBox(width: 12),
        const Text(
          'حالة الحساب',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),

        // ✅ هنا الفرق:
        if (_loadingStatus)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label, // تم القبول / تم الرفض / قيد المراجعة / غير معروف
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  ),
),


              const SizedBox(height: 16),

              // بطاقة المحفظة
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [
                        Icon(Iconsax.wallet_2, color: Color(0xFF0B5345), size: 26),
                        SizedBox(width: 10),
                        Text('المحفظة',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                      ]),
                      Text('$points نقطة',
                        style: const TextStyle(fontFamily: 'Tajawal', color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 12),

              // كرت طلب تحديث الرخصة
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Iconsax.document_upload,
                    color: Color(0xFF0B5345),
                  ),
                  title: const Text(
                    'طلب تحديث الرخصة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  /*subtitle: const Text(
                    'إرسال طلب تحديث رخصة للمشرف',              
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),*/
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (_user == null || !_user!.isLawyer) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('هذه الميزة متاحة للمحامين فقط'),
                        ),
                      );
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LawyerUpdateLicensePage(),
                      ),
                    );

                    // بعد الرجوع لو حابة تحدثي حالة الصفحة
                    if (!mounted) return;
                    _loadUser();
                  },
                ),
              ),

              const SizedBox(height: 24),

              // زر تسجيل الخروج
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color.fromARGB(255, 223, 224, 224), width: 1.5),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('تسجيل الخروج',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Iconsax.logout, color: Color(0xFF0B5345)),
                  ],
                ),
              ),

              const SizedBox(height: kBottomNavigationBarHeight + 24),
            ],
          ),
        ),

        bottomNavigationBar: const LawyerBottomNav(currentRoute: '/lawyer/more'),
      ),
    );
  }
}
