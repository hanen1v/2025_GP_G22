import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/app_bottom_nav.dart';
import '../services/session.dart';
import '../services/api_client.dart';
import '../models/user.dart';

// ================== MODEL ==================

class Appointment {
  final int id;            // AppointmentID
  final int lawyerId;      // LawyerID
  final String lawyerName; // اسم المحامي
  final String status;     // Upcoming / Active / Past
  final String date;       // تاريخ جاهز للعرض
  final String time;       // وقت جاهز للعرض
  final String requestNo;  // رقم الطلب (نفس الـ ID)
  final bool hasFeedback;  // من الـ PHP (0/1)
  final String lawyerPhoto; // اسم ملف الصورة من الـ DB (LawyerPhoto)

  Appointment({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.status,
    required this.date,
    required this.time,
    required this.requestNo,
    required this.hasFeedback,
    required this.lawyerPhoto,
  });

  // رابط الصورة الجاهز للاستخدام
  String get lawyerPhotoUrl {
    if (lawyerPhoto.isEmpty) return '';
    return '${ApiClient.base}/uploads/$lawyerPhoto';
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final rawDateTime = (json['DateTime'] ?? '').toString();
    String date = '';
    String time = '';

    if (rawDateTime.isNotEmpty) {
      final parts = rawDateTime.split(' ');
      if (parts.isNotEmpty) date = parts[0];
      if (parts.length > 1 && parts[1].length >= 5) {
        time = parts[1].substring(0, 5); // HH:MM
      }
    }

    return Appointment(
      id: int.tryParse('${json['AppointmentID']}') ?? 0,
      lawyerId: int.tryParse('${json['LawyerID']}') ?? 0,
      lawyerName: (json['LawyerName'] ?? '').toString(),
      status: (json['Status'] ?? 'Upcoming').toString(),
      date: date,
      time: time,
      requestNo: '${json['AppointmentID']}',
      hasFeedback: '${json['HasFeedback']}' == '1',
      lawyerPhoto: (json['LawyerPhoto'] ?? '').toString(), // <-- مهم
    );
  }
}

// ================== PAGE ==================

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  String _currentTab = 'Upcoming';

  List<Appointment> _allAppointments = [];
  bool _loading = true;
  String? _error;

  List<Appointment> get _filteredAppointments =>
      _allAppointments.where((ap) => ap.status == _currentTab).toList();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await Session.getUser();
      if (user == null || !user.isClient) {
        throw Exception('المستخدم الحالي ليس عميلًا');
      }

      final res = await http.post(
        Uri.parse('${ApiClient.base}/get_client_appointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'clientId': user.id}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final body = jsonDecode(res.body);

      if (body is! Map || body['success'] != true) {
        throw Exception(
            'شكل الرد غير متوقع: success: ${body['success']}, message: ${body['message']}');
      }

      final list = (body['appointments'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final apps = list.map((m) => Appointment.fromJson(m)).toList();

      setState(() {
        _allAppointments = apps;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _buildBodyContent()),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentRoute: '/status'),
        floatingActionButton: _buildFab(context),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // ================== BODY ==================

  Widget _buildBodyContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'حدث خطأ أثناء جلب الطلبات\n$_error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: Colors.red,
          ),
        ),
      );
    }

    if (_filteredAppointments.isEmpty) {
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
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredAppointments.length,
        itemBuilder: (context, index) {
          final ap = _filteredAppointments[index];
          return _buildAppointmentCard(ap);
        },
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
            _buildTabItem('Upcoming', 'قادمة'),
            _buildTabItem('Active', 'نشطة'),
            _buildTabItem('Past', 'منتهية'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String value, String label) {
    final bool isSelected = _currentTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B5345) : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF0B5345),
            ),
          ),
        ),
      ),
    );
  }

  // ================== CARD ==================

  Widget _buildAppointmentCard(Appointment ap) {
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
        // ===== السطر العلوي: صورة + اسم المحامي + رقم الطلب =====
        Row(
          children: [
            // صورة المحامي
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ap.lawyerPhoto.isNotEmpty
                    ? Image.network(
                        '${ApiClient.profileImageBase}/${ap.lawyerPhoto}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                      ),
              ),
            ),

            const SizedBox(width: 10),

            // اسم المحامي
            Expanded(
              child: Text(
                ap.lawyerName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // بادج رقم الطلب
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

// ===== السطر السفلي: يمين (تاريخ + وقت) / يسار (زر) =====
const SizedBox(height: 8),
Directionality(
  textDirection: TextDirection.ltr,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // زر الإجراء (إلغاء / محادثة / تقييم)
      _buildActionsForStatus(ap, _currentTab),

      const Spacer(),

      // التاريخ و الوقت 
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // التاريخ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ap.date,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B5345),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: Color(0xFF0B5345),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // الوقت
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ap.time,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B5345),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.access_time,
                size: 18,
                color: Color(0xFF0B5345),
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





  Widget _buildLawyerAvatar(Appointment ap) {
    if (ap.lawyerPhotoUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFFE8F6F3),
        ),
        child: const Icon(
          Icons.person_outline,
          color: Color(0xFF0B5345),
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        ap.lawyerPhotoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          // لو فيه مشكلة بالصورة نرجع للأيقونة
          return Container(
            width: 64,
            height: 64,
            color: const Color(0xFFE8F6F3),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF0B5345),
              size: 32,
            ),
          );
        },
      ),
    );
  }

  /// الأزرار (إلغاء / محادثة / قيّم الآن)
  Widget _buildActionsForStatus(Appointment ap, String statusFilter) {
  const primaryGreen = Color(0xFF0B5345);

  if (statusFilter == 'Upcoming') {
    // إلغاء الموعد
    return _pillButton(
      label: 'إلغاء الموعد',
      textColor: Colors.red,
      bgColor: Colors.red.withOpacity(0.06),
      onTap: () => _cancelAppointment(ap.id),
    );
  } else if (statusFilter == 'Active') {
    // محادثة
    return _pillButton(
      label: 'محادثة المحامي',
      textColor: primaryGreen,
      bgColor: primaryGreen.withOpacity(0.08),
      onTap: () => _openChatWithLawyer(ap.lawyerId),
    );
  } else {
    // Past
    if (ap.hasFeedback) {
      return const Text(
        'تم التقييم',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          color: Colors.grey,
        ),
      );
    }
    return _pillButton(
      label: 'قيّم الموعد',
      textColor: primaryGreen,
      bgColor: primaryGreen.withOpacity(0.08),
      onTap: () => _openRatingPage(ap.lawyerId),
    );
  }
}

//  (chip)
Widget _pillButton({
  required String label,
  required Color textColor,
  required Color bgColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(30),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    ),
  );
}


  // ================== FAB ==================

  Widget _buildFab(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 6, 61, 65),
            Color.fromARGB(255, 8, 65, 69),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 31, 79, 83),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ================== LOGIC ==================

/// إلغاء الموعد من السيرفر + تحديث الليست
Future<void> _cancelAppointment(int appointmentId) async {
  // نعرض رسالة تأكيد قبل تنفيذ الإلغاء
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'تأكيد الإلغاء',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'هل أنت متأكد من إلغاء الموعد؟',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text(
                'لا',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.grey,
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text(
                ' إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.red,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    },
  );

  // إذا المستخدم اختار "لا" نوقف
  if (confirm != true) return;

  // نبدأ الإلغاء الآن
  try {
    final res = await http.post(
      Uri.parse('${ApiClient.base}/cancel_appointment.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'appointmentId': appointmentId}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        body is Map &&
        body['success'] == true) {
      // نجاح الإلغاء
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الموعد بنجاح'),
        ),
      );

      _loadAppointments(); // تحديث الطلبات
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر إلغاء الموعد: ${body['message'] ?? ''}'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('خطأ أثناء إلغاء الموعد: $e'),
      ),
    );
  }
}



/// فتح صفحة الشات)
void _openChatWithLawyer(int lawyerId) {
  // Navigator.pushNamed(context, '/chatPage', arguments: {'lawyerId': lawyerId});
  debugPrint('فتح الشات مع المحامي: $lawyerId');
}

/// فتح صفحة التقييم وتمرير ID المحامي
void _openRatingPage(int lawyerId) {
  Navigator.pushNamed(
    context,
    '/', //  اسم صفحة التقييم  
    arguments: {
      'lawyerId': lawyerId,
    },
  );
}

}
