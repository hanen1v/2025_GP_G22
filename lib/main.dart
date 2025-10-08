import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/plus_page.dart';
import 'pages/status_page.dart';
import 'pages/more_page.dart';

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
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchPage(),
        '/plus': (context) => const PlusPage(),
        '/status': (context) => const StatusPage(),
        '/more': (context) => const MorePage(),
      },
    );
  }
}
