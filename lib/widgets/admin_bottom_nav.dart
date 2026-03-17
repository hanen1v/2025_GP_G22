import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminBottomNav extends StatelessWidget {
  final String currentRoute;
  const AdminBottomNav({super.key, required this.currentRoute});

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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _navItem(
                context,
                Iconsax.trash,
                'المحامين',
                '/DeleteLawyerPage',
              ),
              _navItem(
                context,
                Iconsax.document,
                'الطلبات',
                '/requestsManagement',
              ),
            ],
          ),
        ),
      ),
    );
  }
}