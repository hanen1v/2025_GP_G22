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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.003),
                    child: Icon(
                      Iconsax.profile_2user,
                      color: const Color(0xFF0B5345),
                      size: screenWidth * 0.048,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.012),
                  Text(
                    'محامونا',
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // زر "شاهد المزيد"
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/search');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B5345),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.005,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'شاهد الجميع',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.chevron_right,
                      size: screenWidth * 0.045,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.025),

          FutureBuilder<List<Lawyer>>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: screenHeight * 0.16,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: screenWidth * 0.008,
                    ),
                  ),
                );
              }
              
              if (s.hasError) {
                return Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Text(
                    'فشل التحميل: ${s.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                );
              }
              
              final list = s.data ?? [];
              if (list.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Text(
                    'لا يوجد محامون متاحون الآن',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                );
              }
              
              return SizedBox(
                height: screenHeight * 0.175,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.04),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final photo = lawyer.photoUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LawyerDetailsPage(lawyerId: lawyer.id),
          ),
        );
      },
      child: SizedBox(
        width: screenWidth * 0.25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.125,
                  backgroundColor: const Color(0xFFE8F3F2),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isNotEmpty
                      ? null
                      : Icon(
                          Icons.person,
                          color: const Color(0xFF0B5345),
                          size: screenWidth * 0.07,
                        ),
                ),

                // التقييم
                Positioned(
                  top: -screenWidth * 0.02,
                  right: -screenWidth * 0.02,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.004,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 3),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.star1,
                          size: screenWidth * 0.04,
                          color: lawyer.rating > 0
                              ? const Color(0xFFFFC107)
                              : Colors.grey,
                        ),
                        SizedBox(width: screenWidth * 0.005),
                        Text(
                          lawyer.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Approved
                Positioned(
                  bottom: -screenWidth * 0.005,
                  right: screenWidth * 0.01,
                  child: Container(
                    width: screenWidth * 0.045,
                    height: screenWidth * 0.045,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 3),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF26C281),
                      ),
                      child: Icon(
                        Icons.check,
                        size: screenWidth * 0.03,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.025),

            Text(
              lawyer.fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: screenWidth * 0.034,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}