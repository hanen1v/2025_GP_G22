import 'package:flutter/material.dart';
import '../widgets/lawyer_bottom_nav.dart';

class LawyerAvailabilityPage extends StatelessWidget {
  const LawyerAvailabilityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('الإتاحة')),
      body: const Center(child: Text('قريباً')),
      bottomNavigationBar: const LawyerBottomNav(currentRoute: '/lawyer/availability'),
    );
  }
}
