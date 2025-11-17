import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../widgets/lawyer_bottom_nav.dart';
import '../services/api_client.dart';
import '../services/session.dart';

/// فتح ملف PDF داخل التطبيق باستخدام open_file
Future<void> openPdfInsideApp(String fileName) async {
  try {
    final url = "${ApiClient.base}/uploads/$fileName";

    // تحميل الملف من السيرفر
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("فشل تحميل الملف");
    }

    // تخزينه مؤقتاً في مجلد الـ temp
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$fileName");
    await file.writeAsBytes(response.bodyBytes);

    // فتحه عن طريق open_file (عارض داخلي للنظام)
    await OpenFile.open(file.path);
  } catch (e) {
    debugPrint("PDF ERROR: $e");
  }
}

// ================== MODEL ==================

class LawyerAppointment {
  final int id;
  final int clientId;
  final String clientName;
  final String status;
  final String date;
  final String time;
  final String requestNo;
  final String consultationType;
  final String details;
  final String file;

  LawyerAppointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.date,
    required this.time,
    required this.requestNo,
    required this.consultationType,
    required this.details,
    required this.file,
  });

  /// تحويل القيمة من السيرفر إلى نص عربي
  String get typeLabel {
    switch (consultationType) {
      case 'contract':
      case 'contractreview':
      case 'contract_review':
        return 'مراجعة عقد';
      case 'consultation':
      default:
        return 'استشارة قانونية';
    }
  }

  factory LawyerAppointment.fromJson(Map<String, dynamic> json) {
    final raw = (json['DateTime'] ?? '').toString();
    String date = '';
    String time = '';

    if (raw.isNotEmpty) {
      final parts = raw.split(' ');
      if (parts.isNotEmpty) date = parts[0];
      if (parts.length > 1 && parts[1].length >= 5) {
        time = parts[1].substring(0, 5);
      }
    }

    return LawyerAppointment(
      id: int.parse(json['AppointmentID'].toString()),
      clientId: int.parse(json['ClientID'].toString()),
      clientName: (json['ClientName'] ?? 'عميل').toString(),
      status: (json['Status'] ?? 'Upcoming').toString(),
      date: date,
      time: time,
      requestNo: json['AppointmentID'].toString(),
      consultationType: (json['consultation_type'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      file: (json['file'] ?? '').toString(),
    );
  }
}

// ================== PAGE ==================

class LawyerRequestsPage extends StatefulWidget {
  const LawyerRequestsPage({super.key});

  @override
  State<LawyerRequestsPage> createState() => _LawyerRequestsPageState();
}

class _LawyerRequestsPageState extends State<LawyerRequestsPage> {
  String _currentTab = 'Upcoming';
  List<LawyerAppointment> _all = [];
  bool _loading = true;

  List<LawyerAppointment> get _filtered =>
      _all.where((ap) => ap.status == _currentTab).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final user = await Session.getUser(); // المحامي
      if (user == null || !user.isLawyer) {
        throw Exception('المستخدم الحالي ليس محاميًا');
      }

      final res = await http.post(
        Uri.parse('${ApiClient.base}/get_lawyer_appointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lawyerId': user.id}),
      );

      final body = jsonDecode(res.body);
      print('API RESPONSE: $body');
      final list = (body['appointments'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map((m) => LawyerAppointment.fromJson(m))
          .toList();

      setState(() => _all = list);
    } catch (e) {
      debugPrint('ERROR loading lawyer appointments: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0B5345);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8FC),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        bottomNavigationBar:
            const LawyerBottomNav(currentRoute: '/lawyer/requests'),
      ),
    );
  }

  // ================== TABS ==================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _tab('Upcoming', 'قادمة'),
            _tab('Active', 'نشطة'),
            _tab('Past', 'منتهية'),
          ],
        ),
      ),
    );
  }

  Widget _tab(String value, String label) {
    final selected = _currentTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B5345) : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF0B5345),
            ),
          ),
        ),
      ),
    );
  }

  // ================== BODY ==================

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_filtered.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد طلبات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _buildCard(_filtered[i]),
      ),
    );
  }

  // ================== CARD ==================

  Widget _buildCard(LawyerAppointment ap) {
    const primaryGreen = Color(0xFF0B5345);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // السطر العلوي: اسم العميل يمين + رقم الطلب يسار
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'اسم العميل: ',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        ap.clientName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '#${ap.requestNo}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFE9EDF2)),
          const SizedBox(height: 12),

          // السطر السفلي
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // زر اليسار
                _buildMainActionButton(ap),

                const Spacer(),

                // نوع الاستشارة في المنتصف
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '"${ap.typeLabel}"',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // التاريخ والوقت يمين
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ap.date,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: primaryGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ap.time,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: primaryGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  /// Active -> محادثة العميل
  /// Upcoming/Past -> عرض التفاصيل
  Widget _buildMainActionButton(LawyerAppointment ap) {
    const primaryGreen = Color(0xFF0B5345);

    if (ap.status == 'Active') {
      return InkWell(
        onTap: () => _openChatWithClient(ap.clientId),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'محادثة العميل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: () => _showDetails(ap),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'عرض التفاصيل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
        ),
      );
    }
  }

  // ================== LOGIC ==================

  void _openChatWithClient(int clientId) {
    debugPrint('فتح الشات مع العميل: $clientId');
  }

    /// عرض تفاصيل الموعد    
  void _showDetails(LawyerAppointment ap) {
    if (ap.details.trim().isEmpty && ap.file.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تفاصيل لهذا الموعد')),
      );
      return;
    }

    const primaryGreen = Color(0xFF0B5345);
    final typeTitle = ap.typeLabel; // استشارة قانونية / مراجعة عقد

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx).size;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: media.height * 0.70,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // الهاندل الصغير فوق
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // الهيدر: عنوان + إكس
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const Spacer(),
                      Text(
                        typeTitle,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // المحتوى
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // سطر معلومات بسيط فوق
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'العميل: ${ap.clientName}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '#${ap.requestNo}',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // كارد التفاصيل
                        if (ap.details.trim().isNotEmpty) ...[
                          const Text(
                            'وصف الحالة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E3EB),
                              ),
                            ),
                            child: Text(
                              ap.details,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        // كارد الملف
                        if (ap.file.trim().isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'الملف المرفق',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => openPdfInsideApp(ap.file),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD0D7FF),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ap.file,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.open_in_new,
                                    size: 18,
                                    color: primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
