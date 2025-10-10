import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'استشارة قانونية',
        'icon': Iconsax.message_question, 
        'route': '/consultation',
      },
      {
        'title': 'مراجعة عقد',
        'icon': Iconsax.document_text, 
        'route': '/contractReview',
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
        //fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  ],
),

        const SizedBox(height: 16),

        // (الكروت)
        GridView.builder(
          itemCount: services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,         // عمودين
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 140,       // ارتفاع موحد للكروت
          ),
          itemBuilder: (context, i) {
            final s = services[i];
            return Card(
              color: Color.fromARGB(255, 255, 255, 255),
              elevation: 1.5,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pushNamed(context, s['route'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          style: const TextStyle(fontSize: 15, height: 1.2),
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
