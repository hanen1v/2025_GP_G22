import 'package:flutter/material.dart';

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('استشارة قانونية')),
        body: const Center(
          child: Text('صفحة استشارة قانونية (Placeholder)', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
