import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminBottomNav extends StatelessWidget {
  final String currentRoute; 
  const AdminBottomNav({super.key, required this.currentRoute});

  void _go(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route) {
    final isSelected = currentRoute == route;
    final color = isSelected ? const Color.fromARGB(255, 6, 61, 65) : Colors.grey;

    return InkWell(
      onTap: () => _go(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 27),
                Icon(icon, color: color, size: 26),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: BottomAppBar(
        // ما عندنا FAB هنا، لذلك ما نحتاج notch
        color: Colors.white,
        elevation: 0,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(context, Iconsax.trash, 'المحامين', '/DeleteLawyerPage'),
                _navItem(context, Iconsax.document, 'الطلبات', '/requestsManagement'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
