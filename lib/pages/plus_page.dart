import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';

class PlusPage extends StatelessWidget {
  const PlusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('خدمات الذكاء الاصطناعي (قريبا)', style: TextStyle(fontSize: 24))),
      
      bottomNavigationBar: const AppBottomNav(currentRoute: '/plus'),
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
        gradient: const LinearGradient(colors: [Color.fromARGB(255, 6, 61, 65), Color.fromARGB(255, 8, 65, 69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color.fromARGB(255, 31, 79, 83), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: FloatingActionButton(
        onPressed: () {
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
