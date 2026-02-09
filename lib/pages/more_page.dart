import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/app_bottom_nav.dart';
import '../pages/profile_page.dart';
import '../services/session.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  User? _user;
  Timer? _walletTimer;
  

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadWallet();
    _startWalletAutoRefresh();
  }


void _startWalletAutoRefresh() {
     _walletTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadWallet();
    });
  }

  @override
  void dispose() {
    _walletTimer?.cancel();
    super.dispose();
  }


  Future<void> _loadUser() async {
    final u = await Session.getUser();
    if (!mounted) return;
    setState(() => _user = u);
  }


Future<void> _loadWallet() async {
    final u = await Session.getUser();
    if (u == null) return;

    try {
      final refreshed = await ApiClient.refreshUserData(u.id, u.userType);

      await Session.saveUser(refreshed);

      if (!mounted) return;
      setState(() {
        _user = refreshed;
      });
    } catch (e) {
      debugPrint("Error refreshing user: $e");
    }
  }


  Future<void> _logout() async {
  try {
    await Session.clear();
  } catch (_) {
  }

  if (!mounted) return;

  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  
}


  @override
  Widget build(BuildContext context) {
    final fullName = _user?.fullName ?? 'ضيف';
    final username = _user?.username ?? '';
    final points = _user?.points ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المزيد'),
          automaticallyImplyLeading: false,
           ),
       backgroundColor: const Color(0xFFF8F9FA),

        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
  color: const Color.fromARGB(255, 255, 255, 255),
  child: ListTile(
    leading: const Icon(
      Iconsax.profile_remove, 
      color: Color(0xFF0B5345),  
    ),
    title: const Text(
      'الملف الشخصي',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: Color.fromARGB(255, 0, 0, 0),  
      ),
    ),
    subtitle: Text(
      fullName,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
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
    MaterialPageRoute(
      builder: (_) => ProfilePage(
        fullName: fullName,
        username: username,
      ),
    ),
  );
  if (!mounted) return;
  _loadUser();
  _loadWallet(); 
},

  ),
),

 const SizedBox(height: 16),

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
              Iconsax.wallet_2, 
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
          '${points} ريال',      
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
          color: Color.fromARGB(255, 0, 0, 0),  
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
          fontSize: 16,
        ),
      ),
      SizedBox(width: 8),
      Icon(Iconsax.logout, color: Color(0xFF0B5345))
    ],
  ),
),

            const SizedBox(height: kBottomNavigationBarHeight + 24),
          ],
        ),

        bottomNavigationBar: const AppBottomNav(currentRoute: '/more'),
        floatingActionButton: _buildFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

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
        onPressed: () {
  Navigator.pushNamed(context, '/ai-contract');
},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
