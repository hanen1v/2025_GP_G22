import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/services_section.dart';
import '../widgets/lawyers_strip_simple.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            //  شريط المحامين فوق
            Positioned(
              left: 0,
              right: 0,
              top: 110,
              bottom: 10,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LawyersStripSimple(),
              ),
            ),

            //  الخدمات مثبتة في الأسفل 
            Positioned(
              left: 16,
              right: 16,
              bottom: kBottomNavigationBarHeight + 180, // ← مسافة فوق FloatingButton
              child: const ServicesSection(),
            ),
          ],
        ),
      ),

      //  البار السفلي
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
