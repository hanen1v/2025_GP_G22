import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/lawyer_bottom_nav.dart';
import '../services/session.dart';
import '../models/user.dart';
import 'profile_page.dart';

class LawyerMorePage extends StatefulWidget {
  const LawyerMorePage({super.key});

  @override
  State<LawyerMorePage> createState() => _LawyerMorePageState();
}

class _LawyerMorePageState extends State<LawyerMorePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await Session.getUser();
    if (!mounted) return;
    setState(() => _user = u);
  }

  Future<void> _logout() async {
    try { await Session.clear(); } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final username = _user?.username ?? 'ضيف';
    final points   = _user?.points ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المزيد (محامي)')),
        backgroundColor: const Color(0xFFF8F9FA),

        body: ListView(
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
                  _loadUser(); // يحدث بعد الرجوع
                },
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

        // 👇 لاحظي اختلاف الناف بار هنا
        bottomNavigationBar: const LawyerBottomNav(currentRoute: '/lawyer/more'),
      ),
    );
  }
}
