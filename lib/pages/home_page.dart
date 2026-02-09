import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/services_section.dart';
import '../widgets/lawyers_strip_simple.dart';
import 'ai_contract_drafting.dart';

class HomePage extends StatelessWidget {
  final String? userName;
  final String? userType;

  const HomePage({super.key, this.userName, this.userType});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userName != null && userName!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مرحباً بعودتك $userName! 👋',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF0B5345),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: screenHeight * 0.15,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشعار
              Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(
                  top: screenHeight * 0.02,
                  right: screenWidth * 0.04,
                  left: screenWidth * 0.04,
                ),
                child: Image.asset(
                  'assets/logo/mujeer_logo.png',
                  width: screenWidth * 0.46,
                  height: screenHeight * 0.1,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: const LawyersStripSimple(),
              ),
              
              SizedBox(height: screenHeight * 0.03),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: const ServicesSection(),
              ),
              
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/home'),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFab(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth * 0.16,
      height: screenWidth * 0.16,
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
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: screenWidth * 0.07,
        ),
      ),
    );
  }
}