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
import 'pages/otp_screen.dart';
import 'pages/lawyer_requests_page.dart';
import 'pages/lawyer_availability_page.dart';
import 'pages/lawyer_more_page.dart';
import 'pages/delete_lawyer_page.dart';
import 'pages/identity_verification_page.dart';
import 'pages/reset_password_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('✅ Firebase already initialized');
    } else {
      print('❌ Firebase initialization error: $e');
      rethrow;
    }
  }
  
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  
  // انتظر قليلاً قبل تهيئة OneSignal
  await Future.delayed(const Duration(seconds: 1));
  
  OneSignal.initialize("52e7af05-5276-4ccd-9715-1cb9820f4361");
  
  // انتظر أكثر قبل طلب الإذن
  await Future.delayed(const Duration(seconds: 2));
  
  OneSignal.Notifications.requestPermission(true);
  
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
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4FE8)),
        textTheme: const TextTheme().apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
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
        '/DeleteLawyerPage': (context) => const DeleteLawyerPage(),
        '/identity_verification': (context) => const IdentityVerificationPage(),
        '/reset_password': (context) => const ResetPasswordPage(username: ''),
      },
    );
  }
}