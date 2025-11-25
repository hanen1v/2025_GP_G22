import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/lawyer.dart';
import 'package:iconsax/iconsax.dart';
import '../pages/lawyer_details_page.dart';


class LawyersStripSimple extends StatefulWidget {
  const LawyersStripSimple({super.key, this.onSeeMore});
  final VoidCallback? onSeeMore;

  @override
  State<LawyersStripSimple> createState() => _LawyersStripSimpleState();
}

class _LawyersStripSimpleState extends State<LawyersStripSimple> {
  late Future<List<Lawyer>> _future;
  @override
  void initState() {
    super.initState();
    _future = ApiClient.getLatestLawyers();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
  children: [
  
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Icon(
            Iconsax.profile_2user, 
            color: Color(0xFF0B5345),
            size: 19,
          ),
        ),
        SizedBox(width: 5),
        Text(
          'محامونا',
          style: TextStyle(
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
      ],
    ),
    const Spacer(),

    // زر "شاهد المزيد"
    TextButton(
  onPressed: () {
    Navigator.pushNamed(context, '/search'); // ← يفتح صفحة البحث
  },
  style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF0B5345),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Text('شاهد الجميع'),
      SizedBox(width: 4),
      Icon(Icons.chevron_right, size: 18),
    ],
  ),
),


  ],
),

          const SizedBox(height: 20),
          FutureBuilder<List<Lawyer>>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 128, child: Center(child: CircularProgressIndicator()));
              }
              if (s.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('فشل التحميل: ${s.error}', textAlign: TextAlign.center),
                );
              }
              final list = s.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا يوجد محامون متاحون الآن'),
                );
              }
              return SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) => _LawyerChip(lawyer: list[i]),
                  clipBehavior: Clip.none,                      
                  physics: const BouncingScrollPhysics(), 
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LawyerChip extends StatelessWidget {
  const _LawyerChip({required this.lawyer});
  final Lawyer lawyer;

  @override
  Widget build(BuildContext context) {
    final photo = lawyer.photoUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LawyerDetailsPage(
              lawyerId: lawyer.id, // ← نمرّر ID الصحيح
            ),
          ),
        );
      },
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE8F3F2),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isNotEmpty
                      ? null
                      : const Icon(Icons.person, color: Color(0xFF0B5345), size: 28),
                ),

                // التقييم
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                    ),
                    child: Row(
                      children: [
                        Icon(
                         Iconsax.star1,
                         size: 16,
                         color: lawyer.rating > 0 
                           ? const Color(0xFFFFC107)   // أصفر لو فيه تقييم
                          : Colors.grey,              // رمادي لو مافيه تقييم
                        ),

                        const SizedBox(width: 2),
                        Text(
                          lawyer.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Approved
                Positioned(
                  bottom: -2,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF26C281),
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              lawyer.fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
