import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/app_bottom_nav.dart';
import '../pages/profile_page.dart';
import '../services/session.dart';
import '../models/user.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
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
  try {
    // مسح الجلسة لو فيه مستخدم محفوظ
    await Session.clear();
  } catch (_) {
    // لو ما فيه جلسة (ضيف) تجاهل الخطأ
  }

  if (!mounted) return;

  // Welcome توجيه  لصفحة 
  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  
}


  @override
  Widget build(BuildContext context) {
    final username = _user?.username ?? 'ضيف';
    final points = _user?.points ?? 0; // ← رصيد النقاط

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المزيد')),
        backgroundColor: const Color(0xFFF8F9FA),

        // الملف الشخصي + تسجيل الخروج
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
  color: const Color.fromARGB(255, 255, 255, 255),
  child: ListTile(
    leading: const Icon(
      Iconsax.profile_remove, // الأيقونة نفسها بمكانها القديم
      color: Color(0xFF0B5345), // اللون الأخضر
    ),
    title: const Text(
      'الملف الشخصي',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: Color.fromARGB(255, 0, 0, 0), // نفس الأخضر
      ),
    ),
    subtitle: Text(
      username,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
    trailing: const Icon(Icons.chevron_right),
  onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfilePage(username: username)),
  );
  if (!mounted) return;
  _loadUser(); // ← يحدث البيانات بعد الرجوع من الملف الشخصي
},

  ),
),

 const SizedBox(height: 16),

// بطاقة المحفظة 
Card(
  color: Colors.white,
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(
              Iconsax.wallet_2, // ← أيقونة المحفظة من Iconsax
              color: Color(0xFF0B5345), 
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'المحفظة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          '${points} نقطة', // ← المتغير اللي فيه نقاط المستخدم
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    ),
  ),
),



            const SizedBox(height: 24),
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
      Text(
        'تسجيل الخروج',
        style: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0), // أخضر غامق
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
          fontSize: 16,
        ),
      ),
      SizedBox(width: 8),
      Icon(Iconsax.logout, color: Color(0xFF0B5345))
 // الأيقونة بعد النص
    ],
  ),
),

            const SizedBox(height: kBottomNavigationBarHeight + 24),
          ],
        ),

        //  البار والزر العائم  
        bottomNavigationBar: const AppBottomNav(currentRoute: '/more'),
        floatingActionButton: _buildFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // القديم تماماً
  Widget _buildFab(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 6, 61, 65),
            Color.fromARGB(255, 8, 65, 69)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 31, 79, 83),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
