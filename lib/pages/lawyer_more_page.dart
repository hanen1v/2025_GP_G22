import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/lawyer_bottom_nav.dart';
import '../services/session.dart';
import '../models/user.dart';
import 'profile_page.dart';
import 'dart:async'; //(Timer)
import '../services/api_client.dart';

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
    final username = _user?.username ?? 'ضيف';
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
              // بطاقة الملف الشخصي
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Iconsax.profile_remove, color: Color(0xFF0B5345)),
                  title: const Text('الملف الشخصي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 16, color: Colors.black)),
                  subtitle: Text(username, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.black54)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(username: username)));
                    if (!mounted) return;
                    _loadUser(); // يحدث بعد الرجوع (قد تتغيّر الحالة)
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
