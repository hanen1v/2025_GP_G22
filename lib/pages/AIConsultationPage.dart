import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'preferences_page.dart'; 

class AIConsultationPage extends StatefulWidget {
  @override
  _AIConsultationPageState createState() => _AIConsultationPageState();
}

class _AIConsultationPageState extends State<AIConsultationPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  
  final Color primaryColor = const Color.fromARGB(255, 9, 44, 36);

  Future<void> _analyzeAndNavigate() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى كتابة الاستشارة أولاً")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // رابط السيرفر (FastAPI)
      final url = Uri.parse('http://10.0.2.2:8000/predict');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String category = data['category']; // التصنيف من المودل

        // نروج للتفضيلات
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreferencesPage(category: category),
          ),
        );
      } else {
        _showError("حدث خطأ في السيرفر، يرجى المحاولة لاحقاً");
      }
    } catch (e) {
      _showError("فشل الاتصال: تأكد من تشغيل ملف بايثون (main.py)");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تنبيه", textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسنا"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("توصية ذكية للمحامي", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //  الخطوات
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepCircle("2", Colors.grey[300]!),
                const SizedBox(width: 10),
                Container(height: 2, width: 30, color: Colors.grey[300]),
                const SizedBox(width: 10),
                _buildStepCircle("1", primaryColor, isActive: true),
              ],
            ),
            const SizedBox(height: 30),
            
            const Text(
              "الخطوة الأولى: أدخل استشارتك",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 30),

            //  إدخال الاستشارة
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), 
                    blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: "اكتب هنا ...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), 
                    borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // زر التالي
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("التالي", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(String text, Color color, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: Colors.black12, width: 1) : null,
      ),
      child: Text(text, 
        style: TextStyle(color: isActive ? Colors.white : Colors.black54, 
        fontWeight: FontWeight.bold)),
    );
  }
} 