import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/plus_page.dart';
import 'pages/status_page.dart';
import 'pages/more_page.dart';
import 'pages/consultation_page.dart';
import 'pages/contract_review_page.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/lawyer_register_page.dart';
import 'pages/client_register_page.dart'; 
import 'pages/requests_management_page.dart';
import 'pages/lawyer_requests_page.dart';
import 'pages/lawyer_availability_page.dart';
import 'pages/lawyer_more_page.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mujeer',
      theme: ThemeData(
        fontFamily: 'Tajawal', // ←   الخط موحد في كل التطبيق
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4FE8)),
        textTheme: const TextTheme().apply(
          bodyColor: Colors.black, // لون النصوص العادية
          displayColor: Colors.black, // لون العناوين
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl, // ← اتجاه عربي
        child: child!,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/lawyer_register': (context) => const LawyerRegisterPage(),
        '/client_register': (context) => const ClientRegisterPage(),
        '/search': (context) => const SearchPage(),
        '/plus': (context) => const PlusPage(),
        '/status': (context) => const StatusPage(),
        '/more': (context) => const MorePage(),
        '/consultation': (context) => const ConsultationPage(),
        '/contractReview': (context) => const ContractReviewPage(),
        '/requestsManagement': (context) => const RequestManagementPage(),
        '/lawyer/requests':     (_) => const LawyerRequestsPage(),
        '/lawyer/availability': (_) => const LawyerAvailabilityPage(),
        '/lawyer/more':         (_) => const LawyerMorePage(),


      },
    );
  }
}
