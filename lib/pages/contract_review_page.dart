import 'package:flutter/material.dart';

class ContractReviewPage extends StatelessWidget {
  const ContractReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مراجعة عقد')),
        body: const Center(
          child: Text('صفحة مراجعة العقود  (قريبا)', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
