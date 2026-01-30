import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../pages/legal_consult_page.dart';   

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final services = [
      {
        'title': 'استشارة قانونية',
        'icon': Iconsax.message_question,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LegalConsultPage()),
          );
        },
      },
      {
        'title': 'مراجعة عقد',
        'icon': Iconsax.document_text,
        'action': () {
          Navigator.pushNamed(context, '/contractReview');
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.005),
              child: Icon(
                Iconsax.category,
                color: const Color(0xFF0B5345),
                size: screenWidth * 0.05, // 5% من العرض
              ),
            ),
            SizedBox(width: screenWidth * 0.012),
            Text(
              'الخدمات',
              style: TextStyle(
                fontSize: screenWidth * 0.055, // 5.5% من العرض
                color: Colors.black87,
              ),
            ),
          ],
        ),

        SizedBox(height: screenHeight * 0.02), // 2% من الطول

        GridView.builder(
          itemCount: services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: screenHeight * 0.015, // 1.5% من الطول
            crossAxisSpacing: screenWidth * 0.03, // 3% من العرض
            mainAxisExtent: screenHeight * 0.18, // 18% من الطول
          ),
          itemBuilder: (context, i) {
            final s = services[i];
            return Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              elevation: 1.5,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                onTap: s['action'] as VoidCallback,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03, // 3% من العرض
                    vertical: screenHeight * 0.02, // 2% من الطول
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        s['icon'] as IconData,
                        size: screenWidth * 0.09, // 9% من العرض
                        color: const Color(0xFF0B5345),
                      ),
                      SizedBox(height: screenHeight * 0.01), // 1% من الطول
                      Flexible(
                        child: Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: screenWidth * 0.038, // 3.8% من العرض
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}