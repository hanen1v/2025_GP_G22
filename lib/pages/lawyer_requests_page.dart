import 'package:flutter/material.dart';
import '../widgets/lawyer_bottom_nav.dart';

class LawyerRequestsPage extends StatelessWidget {
  const LawyerRequestsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('طلبات المحامي')),
      body: const Center(child: Text('قريباً')),
      bottomNavigationBar: const LawyerBottomNav(currentRoute: '/lawyer/requests'),
    );
  }
}
