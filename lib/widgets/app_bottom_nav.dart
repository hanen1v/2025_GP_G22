import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AppBottomNav extends StatelessWidget {
  final String currentRoute; // '/home', '/search', '/status', '/more'
  const AppBottomNav({super.key, required this.currentRoute});

  void _go(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route) {
    final isSelected = currentRoute == route;
    final color = isSelected ? const Color.fromARGB(255, 6, 61, 65) : Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () => _go(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: screenWidth * 0.065, // 6.5% من عرض الشاشة
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: screenWidth * 0.03, // 3% من عرض الشاشة
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: Colors.white,
          elevation: 0,
          child: SizedBox(
            // ارتفاع ديناميكي يتناسب مع جميع الأجهزة
            height: kBottomNavigationBarHeight + bottomPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // الترتيب: من اليمين لليسار (للتطبيقات العربية)
                _navItem(context, Iconsax.home, 'الرئيسية', '/home'),
                _navItem(context, Iconsax.search_normal, 'بحث', '/search'),
                
                // مساحة الـ FAB في الوسط (نسبة من عرض الشاشة)
                SizedBox(width: screenWidth * 0.12),
                
                _navItem(context, Iconsax.note_2, 'طلباتي', '/status'),
                _navItem(context, Iconsax.more, 'المزيد', '/more'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}