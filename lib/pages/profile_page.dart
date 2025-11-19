import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.username});
  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('حفظ التعديلات (قريباً)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24), // ←   مساحة فوق حقل الاسم
              // حقل الاسم   
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  labelStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    gapPadding: 4,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                    gapPadding: 4,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF0B5345), width: 1.5),
                    gapPadding: 4,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // زر حفظ
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // حذف حسابي (عرض فقط)
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حذف الحساب (قريباً)')),
                    );
                  },
                  child: const Text(
                    'حذف حسابي',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
