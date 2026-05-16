import 'package:flutter/material.dart';
import '../models/request_type.dart';
import 'lawyer_details_page.dart';

class RecommendedLawyersPage extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> lawyers;

  const RecommendedLawyersPage({
    super.key,
    required this.category,
    required this.lawyers,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 9, 44, 36);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "المحامون المقترحون",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: lawyers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "لا يوجد لدينا محامين مناسبين لنوع القضية",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          :  ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    itemCount: lawyers.length + 1,
    itemBuilder: (context, index) {
      if (index == lawyers.length) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 9, 44, 36),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }
      final lawyer = lawyers[index];
      return _buildLawyerCard(context, lawyer, index);
    },
  ),
    );
  }

  Widget _buildLawyerCard(BuildContext context, Map<String, dynamic> lawyer, int index) {
    final imageUrl = _getImageUrl(lawyer);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 147, 147, 147).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (index < 3) ...[
  Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: [
            const Color(0xFFFFD700),
            const Color(0xFFAAAAAA),
            const Color(0xFFCD7F32),
            const Color(0xFF4CAF50),
            const Color(0xFF2196F3),
          ][index],
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ['🥇 الأفضل', '🥈 الثاني', '🥉 الثالث', '4️⃣ الرابع', '5️⃣ الخامس'][index],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: [
            const Color(0xFFFFD700),
            const Color(0xFFAAAAAA),
            const Color(0xFFCD7F32),
            const Color(0xFF4CAF50),
            const Color(0xFF2196F3),
          ][index],
        ),
      ),
    ),
  ),
],
    Row(
      children: [
        ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              color: const Color.fromARGB(255, 230, 230, 230),
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: const Color.fromARGB(255, 230, 230, 230),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer['FullName']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: ((lawyer['Rating'] ?? 0) == 0)
                                ? Colors.grey
                                : Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (lawyer['Rating'] ?? 0).toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    if (lawyer['YearsOfExp'] != null)
      _infoChip(Icons.work_outline, '${lawyer['YearsOfExp']} سنوات خبرة'),
    if ((lawyer['EducationQualification'] ?? '').toString().trim().isNotEmpty)
      _infoChip(Icons.school_outlined, lawyer['EducationQualification'].toString()),

    // التخصص الأساسي
    if ((lawyer['MainSpecialization'] ?? '').toString().trim().isNotEmpty)
      _infoChipHighlighted(Icons.balance, lawyer['MainSpecialization'].toString(), 'أساسي'),

    // التخصص الفرعي الأول
    if ((lawyer['FSubSpecialization'] ?? '').toString().trim().isNotEmpty)
      _infoChipHighlighted(Icons.balance_outlined, lawyer['FSubSpecialization'].toString(), 'فرعي'),

    // التخصص الفرعي الثاني
    if ((lawyer['SSubSpecialization'] ?? '').toString().trim().isNotEmpty)
      _infoChipHighlighted(Icons.balance_outlined, lawyer['SSubSpecialization'].toString(), 'فرعي'),
  ],
),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lawyer['price'] ?? 0} ر.س',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 6, 61, 65),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LawyerDetailsPage(
                          lawyerId: int.parse(lawyer['LawyerID'].toString()),
                          requestType: RequestType.consultation,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 6, 61, 65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(Map<String, dynamic> lawyer) {
    final directImage = (lawyer['image'] ?? '').toString().trim();
    if (directImage.isNotEmpty) return directImage;

    final photoName = (lawyer['LawyerPhoto'] ?? '').toString().trim();
    if (photoName.isNotEmpty) {
      return 'https://res.cloudinary.com/dmhrba99m/image/upload/$photoName';
    }

    return '';
  }

  Widget _infoChip(IconData icon, String? label) {
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF374151)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
  Widget _infoChipHighlighted(IconData icon, String label, String badge) {
  final isMain = badge == 'أساسي';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isMain
          ? const Color.fromARGB(255, 6, 61, 65).withOpacity(0.08)
          : Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
      border: isMain
          ? Border.all(color: const Color.fromARGB(255, 6, 61, 65), width: 1)
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18,
            color: isMain
                ? const Color.fromARGB(255, 6, 61, 65)
                : const Color(0xFF374151)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isMain
                ? const Color.fromARGB(255, 6, 61, 65)
                : const Color(0xFF374151),
            fontSize: 14,
            fontWeight: isMain ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isMain
                ? const Color.fromARGB(255, 6, 61, 65)
                : Colors.grey[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
}