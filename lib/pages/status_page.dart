import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
  final String consultationType; // consultation / contract_review
  final String details;          // وصف الحالة
  final String file;             // اسم الملف المرفق

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
    required this.consultationType,
    required this.details,
    required this.file,
  });


  // label عربي لنوع الاستشارة
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
      consultationType: (json['consultation_type'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      file: (json['file'] ?? '').toString(),
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
  bool _notClientOrGuest = false;


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
      _notClientOrGuest = false;
    });

    try {
      final user = await Session.getUser();
      
      if (user == null) {
      setState(() {
        _notClientOrGuest = true;
        _allAppointments = [];
      });
      return;
    }

    // مسجّل لكن مو عميل
    if (!user.isClient) {
      setState(() {
        _notClientOrGuest = true;
        _allAppointments = [];
      });
      return;
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
if (_notClientOrGuest) {
    return const Center(
      child: Text(
        'يبدو أنك غير مسجّل دخول كعميل.\nقم بتسجيل الدخول لعرض طلباتك.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
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

    /// الأزرار (إلغاء / محادثة / قيّم الآن / عرض التفاصيل)
  Widget _buildActionsForStatus(Appointment ap, String statusFilter) {
    const primaryGreen = Color(0xFF0B5345);

    if (statusFilter == 'Upcoming') {
        return _pillButton(
        label: 'عرض التفاصيل',
        textColor: primaryGreen,
        bgColor: primaryGreen.withOpacity(0.08),
        onTap: () => _showDetails(ap),
      );
    } else if (statusFilter == 'Active') {
      // محادثة
      return _pillButton(
        label: 'محادثة المحامي',
        textColor: primaryGreen,
        bgColor: primaryGreen.withOpacity(0.08),
        onTap: () => _openChatWithLawyer(ap),
      );
    } else {
      // Past
return _pillButton(
  label: 'عرض التفاصيل',
  textColor: primaryGreen,
  bgColor: primaryGreen.withOpacity(0.08),
  onTap: () => _showDetails(ap),
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


Future<void> _openAttachment(Appointment ap) async {
  // لو ما فيه اسم ملف نطلع
  if (ap.file.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد ملف مرفق')),
    );
    return;
  }

  // 1) رابط الملف من السيرفر
  // عدّلي المسار حسب المكان الفعلي للملفات عندك في الـ PHP
  final url = '${ApiClient.base}/uploads/${ap.file}';

  // نعرض شاشة تحميل صغيرة
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 2) تحميل الملف من السيرفر
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    // 3) حفظ الملف في مسار مؤقت داخل الجهاز
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${ap.file}';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    // قفل شاشة التحميل
    Navigator.of(context, rootNavigator: true).pop();

    // 4) فتح الملف بتطبيق النظام (داخل الجهاز)
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الملف: ${result.message}')),
      );
    }
  } catch (e) {
    // لو صار خطأ نقفل الديالوج لو كان مفتوح
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ أثناء فتح الملف: $e')),
    );
  }
}


//navigate to chat screen
void _openChatWithLawyer(Appointment ap) async {
  final user = await Session.getUser();
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
    );
    return;
  }
  
  Navigator.pushNamed(
    context,
    '/ChatScreen',
    arguments: {
      'senderID': 'C${user.id}',         
      'receiverID': 'L${ap.lawyerId}',   
      'appointmentID': ap.id,
    },
  );
}


void _openFinishedChat(Appointment ap) async {
  final user = await Session.getUser();
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
    );
    return;
  }

  Navigator.pushNamed(
    context,
    '/PastChatScreen',         
    arguments: {
      'senderID': 'C${user.id}',    
      'receiverID': 'L${ap.lawyerId}',
      'appointmentID': ap.id,
    },
  );
}

//navigate to feedback page
void _openRatingPage(Appointment ap) {
  Navigator.pushNamed(
    context,
    '/FeedbackPage', //  اسم صفحة التقييم  
    arguments: {
      'lawyerId': ap.lawyerId,
      'appointmentId': ap.id,
      
      
    },
  );
}



  /// عرض تفاصيل الموعد (تتصرف حسب الحالة: قادمة / منتهية)
  void _showDetails(Appointment ap) {
    // لو ما فيه لا تفاصيل ولا ملف، نعرض رسالة ونطلع
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
                // الهاندل الصغير
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // الهيدر
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
                        // معلومات بسيطة
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'المحامي: ${ap.lawyerName}',
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

                        // وصف الحالة
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
                              border: const Border(
                                top: BorderSide(color: Color(0xFFE0E3EB)),
                                bottom: BorderSide(color: Color(0xFFE0E3EB)),
                                left: BorderSide(color: Color(0xFFE0E3EB)),
                                right: BorderSide(color: Color(0xFFE0E3EB)),
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

                        
// الملف المرفق
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
    onTap: () => _openAttachment(ap),   // <-- هنا الفتح
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          top: BorderSide(color: Color(0xFFD0D7FF)),
          bottom: BorderSide(color: Color(0xFFD0D7FF)),
          left: BorderSide(color: Color(0xFFD0D7FF)),
          right: BorderSide(color: Color(0xFFD0D7FF)),
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
        ],
      ),
    ),
  ),
],


                        const SizedBox(height: 24),

                        // ===== لو الموعد منتهي (Past): زر رؤية المحادثة + التقييم =====
                        if (ap.status == 'Past') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _openFinishedChat(ap);
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text(
                                'رؤية المحادثة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // التقييم
                          if (ap.hasFeedback)
                            const Center(
                              child: Text(
                                'تم التقييم',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            Center(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(ctx).pop(); // نقفل التفاصيل
                                  _openRatingPage(ap); // نروح للتقييم
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    'قيّم الموعد',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 14,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],

                        // ===== لو الموعد قادم (Upcoming): زر إلغاء الموعد =====
                        if (ap.status == 'Upcoming') ...[
                        Center(
                         child: InkWell(
                          onTap: () async {
                           Navigator.of(ctx).pop(); // نقفل التفاصيل
                           await _cancelAppointment(ap.id); // إلغاء الموعد
                          },
                          borderRadius: BorderRadius.circular(30),
                         child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                           color: Colors.red.withOpacity(0.10),
                           borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                           'إلغاء الموعد',
                           style: TextStyle(
                             fontFamily: 'Tajawal',
                             fontSize: 14,
                             color: Colors.red,
                             fontWeight: FontWeight.w600,
                             ),
                          ),
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
