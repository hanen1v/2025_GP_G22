import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class LawyerBottomNav extends StatelessWidget {
  final String currentRoute;

  const LawyerBottomNav({
    super.key,
    required this.currentRoute,
  });

  void _go(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final isSelected = currentRoute == route;
    final color =
        isSelected ? const Color.fromARGB(255, 6, 61, 65) : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => _go(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: 1.0, // 🔥 يمنع التكبير الزائد
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _navItem(
              context,
              Iconsax.note_2,
              'الطلبات',
              '/lawyer/requests',
            ),
            _navItem(
              context,
              Iconsax.video_time,
              'الإتاحة',
              '/lawyer/availability',
            ),
            _navItem(
              context,
              Iconsax.more,
              'المزيد',
              '/lawyer/more',
            ),
          ],
        ),
      ),
    );
  }
}
