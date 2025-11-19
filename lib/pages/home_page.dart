import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/services_section.dart';
import '../widgets/lawyers_strip_simple.dart';

class HomePage extends StatelessWidget {
  final String? userName;
  final String? userType;

  const HomePage({super.key, this.userName, this.userType});

  @override
  Widget build(BuildContext context) {
    // رسالة ترحيب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userName != null && userName!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مرحباً بعودتك $userName! 👋',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF0B5345),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      body: SafeArea(
  child: Stack(
    alignment: Alignment.bottomCenter,
    children: [
      //  شعار المشروع أعلى اليمين 
      Positioned(
        top: 14,
        right: -20,
        child: Image.asset(
          'assets/logo/mujeer_logo.png',
          width: 185, 
          height: 75, 
          fit: BoxFit.contain,
        ),
      ),

      //  شريط المحامين 
      Positioned(
        left: 0,
        right: 0,
        top: 115, 
        bottom: 10,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LawyersStripSimple(),
        ),
      ),

      // قسم الخدمات  
      Positioned(
        left: 16,
        right: 16,
        bottom: kBottomNavigationBarHeight + 185,
        child: const ServicesSection(),
      ),
    ],
  ),
),


      // البار السفلي
      bottomNavigationBar: const AppBottomNav(currentRoute: '/home'),

      // الزر العائم في المنتصف
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
        onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
