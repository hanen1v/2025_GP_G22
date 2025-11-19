import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/api_client.dart';
import '../models/user.dart';

class LawyerUpdateLicensePage extends StatefulWidget {
  const LawyerUpdateLicensePage({super.key});

  @override
  State<LawyerUpdateLicensePage> createState() =>
      _LawyerUpdateLicensePageState();
}

class _LawyerUpdateLicensePageState extends State<LawyerUpdateLicensePage> {
  final TextEditingController _licenseCtrl = TextEditingController();
  PlatformFile? _licenseFile;
  String? _licenseFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _licenseFile = result.files.single;
          _licenseFileName = _licenseFile!.name;
        });
      }
    } catch (e) {
      _showError('حدث خطأ أثناء اختيار الملف: $e');
    }
  }

  Future<void> _submit() async {
    final user = await Session.getUser();
    if (user == null || !user.isLawyer) {
      _showError('يجب تسجيل الدخول كمحامي لاستخدام هذه الميزة');
      return;
    }

    if (_licenseFile == null) {
      _showError('يرجى رفع ملف الرخصة الجديدة');
      return;
    }

    if (_licenseCtrl.text.trim().isEmpty) {
      _showError('يرجى إدخال رقم الرخصة الجديد');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) إرسال طلب التحديث (بدون الملف)
      final result = await ApiClient.requestLicenseUpdate(
        lawyerId: user.id,
        fullName: user.fullName,
        newLicenseNumber: _licenseCtrl.text.trim(),
      );

      final licenseFileName = result['licenseFileName'] as String?;

      if (licenseFileName == null || licenseFileName.isEmpty) {
        throw Exception('لم يتم إرجاع اسم ملف الرخصة من السيرفر');
      }

      // 2) رفع الملف باسم محدد من السيرفر
      await ApiClient.uploadLicenseUpdateFile(
        lawyerId: user.id,
        filePath: _licenseFile!.path!,
        fileName: licenseFileName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال طلب تحديث الرخصة بنجاح، سيتم مراجعته من قبل المشرف',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('فشل إرسال الطلب: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.red,
      ),
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
            'طلب تحديث الرخصة',
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
              const SizedBox(height: 12),
              const Text(
                'قم برفع نسخة من رخصتك الجديدة وأدخل رقم الرخصة بعد التجديد.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // رفع ملف الرخصة
              const Text(
                'ملف الرخصة الجديدة *',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isLoading ? null : _pickLicenseFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0B5345),
                  side: const BorderSide(color: Color(0xFF0B5345)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _licenseFileName ?? 'اختر ملف (PDF / صورة)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: _licenseFileName != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.attach_file),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الملفات المسموحة: PDF, JPG, PNG (الحجم الأقصى 10MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),

              const SizedBox(height: 24),

              // رقم الرخصة الجديد
              TextField(
                controller: _licenseCtrl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'رقم الرخصة الجديد *',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0B5345)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5345),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'إرسال الطلب',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
