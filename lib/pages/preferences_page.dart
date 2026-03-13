import 'package:flutter/material.dart';

class PreferencesPage extends StatefulWidget {
  final String category;

  const PreferencesPage({super.key, required this.category});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final Color primaryColor = const Color.fromARGB(255, 9, 44, 36);

  // متغيرات لتخزين اختيارات المستخدم
  String? selectedGender;
  String? selectedDegree;
  String? selectedMajor;
  double selectedExperience = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("تفضيلاتك للمحامي", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مؤشر الخطوات (الخطوة 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepCircle("2", primaryColor, isActive: true),
                const SizedBox(width: 10),
                Container(height: 2, width: 30, color: primaryColor),
                const SizedBox(width: 10),
                _buildStepCircle("1", primaryColor.withOpacity(0.3), isActive: false),
              ],
            ),
            const SizedBox(height: 25),

            // عرض التصنيف المستلم
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.category,
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(" :تصنيف الحالة", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  Icon(Icons.gavel_rounded, color: primaryColor, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("حدد تفضيلاتك للمحامي المقترح", 
              textAlign: TextAlign.right, 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- اختيار الجنس ---
            _buildLabel("جنس المحامي"),
            _buildDropdown(
              hint: "اختر الجنس",
              value: selectedGender,
              items: ["ذكر", "أنثى", "لا يهم"],
              onChanged: (val) => setState(() => selectedGender = val),
            ),

            // --- اختيار الشهادة العلمية ---
            _buildLabel("الدرجة العلمية"),
            _buildDropdown(
              hint: "اختر الشهادة",
              value: selectedDegree,
              items: ["دبلوم", "بكالوريوس", "ماجستير", "دكتوراه"],
              onChanged: (val) => setState(() => selectedDegree = val),
            ),

            // --- اختيار التخصص ---
            _buildLabel("التخصص"),
            _buildDropdown(
              hint: "اختر التخصص",
              value: selectedMajor,
              items: ["قانون", "شريعة"],
              onChanged: (val) => setState(() => selectedMajor = val),
            ),

            // --- سنوات الخبرة (Slider) ---
            _buildLabel("سنوات الخبرة (أكثر من ${selectedExperience.toInt()} سنوات)"),
            Slider(
              value: selectedExperience,
              max: 30,
              divisions: 6,
              activeColor: primaryColor,
              inactiveColor: Colors.grey[200],
              label: selectedExperience.toInt().toString(),
              onChanged: (double value) {
                setState(() => selectedExperience = value);
              },
            ),

            const SizedBox(height: 40),

            // زر العرض النهائي
            ElevatedButton(
              onPressed: () {
                // هنا يتم الربط مع قاعدة البيانات مستقبلاً بناءً على الاختيارات
                print("Category: ${widget.category}, Gender: $selectedGender, Degree: $selectedDegree, Experience: $selectedExperience");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("عرض المحامين المقترحين", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت لبناء العناوين الجانبية
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Text(label, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ويدجت لبناء القوائم المنسدلة بتصميم موحد
  Widget _buildDropdown({required String hint, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        ),
        hint: Text(hint),
        items: items.map((String item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStepCircle(String text, Color color, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
    );
  }
}