import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../pages/legal_consult_page.dart';   
import '../models/request_type.dart';


class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'استشارة قانونية',
        'icon': Iconsax.message_question,
      'action': () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LegalConsultPage(),
      settings: RouteSettings(
        arguments: RequestType.consultation,
      ),
    ),
  );
},

      },
      {
        'title': 'مراجعة عقد',
        'icon': Iconsax.document_text,
        'action': () {
        Navigator.pushNamed(
  context,
  '/search',
  arguments: RequestType.contractReview,
);

        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Icon(
                Iconsax.category,
                color: Color(0xFF0B5345),
                size: 19,
              ),
            ),
            SizedBox(width: 5),
            Text(
              'الخدمات',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        GridView.builder(
          itemCount: services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, i) {
            final s = services[i];
            return Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              elevation: 1.5,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: s['action'] as VoidCallback,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        s['icon'] as IconData,
                        size: 36,
                        color: const Color(0xFF0B5345),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
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
