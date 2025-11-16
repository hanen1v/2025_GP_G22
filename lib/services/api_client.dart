import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';
import '../models/user.dart';
import '../models/lawyer_request.dart';
import '../models/appointment.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';


class ApiClient {
  // مهم:
  // على Android Emulator نستخدم 10.0.2.2 بدل localhost
  static const String base = 'http://10.0.2.2:8888/mujeer_api';
  // على iOS Simulator أو Flutter Web على نفس الجهاز:
  // static const String base = 'http://localhost:8888/mujeer_api';


  static const String profileImageBase = "$base/uploads";


  static Future<List<Lawyer>> getLatestLawyers() async {
    final res = await http.get(Uri.parse('$base/lawyers_latest.php'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is Map && body['ok'] == true) {
        final list = (body['data'] as List).cast<Map<String, dynamic>>();
        return list.map(Lawyer.fromJson).toList();
      }
      throw Exception('Bad response: $body');
    } else {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  static Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$base/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        
        if (body['success'] == true) {
          if (body['user'] != null) {
            return User.fromJson(body['user']);
          } else {
            throw Exception('بيانات المستخدم غير متوفرة في الاستجابة');
          }
        } else {
          throw Exception(body['message'] ?? 'فشل تسجيل الدخول');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in login: $e');
      rethrow;
    }
  }

  //get pending requests
  static Future<List<LawyerRequest>> getPendingRequests() async {
    final res = await http.get(Uri.parse('$base/get_pending_requests.php'));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = json.decode(res.body);

    if (decoded is List) {
      return decoded
          .cast<Map<String, dynamic>>()
          .map((j) => LawyerRequest.fromJson(j))
          .toList();
    } else if (decoded is Map && decoded['ok'] == true) {
      final list = (decoded['data'] as List).cast<Map<String, dynamic>>();
      return list.map((j) => LawyerRequest.fromJson(j)).toList();
    } else {
      throw Exception('Bad response: $decoded');
    }
  }

  static Future<void> updateRequestStatus({
    required int requestId,
    required String status, // 'Approved' أو 'Rejected'
  }) async {
    final res = await http
        .post(
          Uri.parse('$base/update_request_status.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'RequestID': requestId, 'Status': status}),
        );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = json.decode(res.body);
    if (body is! Map || body['ok'] != true) {
      throw Exception(body['message'] ?? 'Failed to update status');
    }
  }

  
//send playerID
  static Future<void> registerAdminDevice() async {
    final playerId = OneSignal.User.pushSubscription.id;

    if (playerId == null || playerId.isEmpty) {
      debugPrint('OneSignal playerId not ready yet.');
      return;
    }

    final res = await http.post(
      Uri.parse('$base/register_device.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'admin_id': 1,
        'player_id': playerId,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body);
    if (body is! Map || body['ok'] != true) {
      throw Exception(body['message'] ?? 'Failed to register admin device');
    }
  }


  static Future<String> getLawyerStatus(int lawyerId) async {
  try {
    final res = await http
        .post(
          Uri.parse('$base/lawyer_status.php'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'lawyer_id': '$lawyerId'},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final m = json.decode(res.body);
    if (m is Map && m['ok'] == true) {
      final raw = (m['status'] as String? ?? '').trim().toLowerCase();
      if (raw == 'approved') return 'Approved';
      if (raw == 'rejected') return 'Rejected';
      return 'Pending'; // أي قيمة غير معروفة نرجّعها Pending
    }

    throw Exception('Bad response: $m');
  } catch (e) {
    // في حالة الشبكة/التايم أوت: رجّع القيمة الحالية الافتراضية
    // تقدر تغيّرها لـ 'Pending' أو ترمي الاستثناء حسب رغبتك
    return 'Pending';
  }
}

static Future<User> updateProfile({
  required int userId,
  required String userType,   // 'client' | 'lawyer'
  required String username,
  required String phoneNumber,
  String? newPassword,        // اختياري
}) async {
  final res = await http.post(
    Uri.parse('$base/update_profile.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'userType': userType,
      'username': username,
      'phoneNumber': phoneNumber,
      if ((newPassword ?? '').isNotEmpty) 'newPassword': newPassword,
    }),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  final body = jsonDecode(res.body);
  if (body is Map && body['success'] == true && body['user'] != null) {
    return User.fromJson(body['user']);
  } else {
    throw Exception(body['message'] ?? 'فشل تحديث الملف');
  }
}


static Future<void> deleteAccount({
  required int userId,
  required String userType, // 'client' | 'lawyer'
  String? password,         // اختياري للتأكيد
  
}) async {
  final url = Uri.parse('$base/delete_account.php');
  final payload = {
    'userId': userId,
    'userType': userType,
    if ((password ?? '').isNotEmpty) 'password': password,
  };

  // (تطلع في الـ Run / Terminal)
  debugPrint('🔴 DELETE REQ → $url');
  debugPrint('🔴 DELETE BODY → ${jsonEncode(payload)}');

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  debugPrint('🟢 DELETE STATUS → ${res.statusCode}');
  debugPrint('🟢 DELETE RAW BODY → ${res.body}');

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  final body = jsonDecode(res.body);
  if (body is! Map || body['success'] != true) {
    throw Exception(body['message'] ?? 'Failed to delete account');
  }
}


  static Future<String> uploadLawyerPhoto({
    required int userId,
    required String imagePath,
  }) async {
    final uri = Uri.parse('$base/upload_lawyer_photo.php');

    final request = http.MultipartRequest('POST', uri);
    request.fields['lawyer_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('photo', imagePath));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    print('🟣 uploadLawyerPhoto status: ${response.statusCode}');
    print('🟣 uploadLawyerPhoto body: $resBody');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final jsonBody = jsonDecode(resBody);
    if (jsonBody is! Map || jsonBody['success'] != true) {
      throw Exception(jsonBody['message'] ?? 'Upload failed');
    }

    // نرجع اسم الملف اللي حفظناه في الداتابيس
    return jsonBody['fileName']?.toString() ?? '';
  }


static Future<Map<String, dynamic>> requestLicenseUpdate({
  required int lawyerId,
  required String fullName,
  required String newLicenseNumber,
}) async {
  final res = await http.post(
    Uri.parse('$base/request_update_license.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'lawyerId': lawyerId,
      'fullName': fullName,
      'licenseNumber': newLicenseNumber,
    }),
  );

  debugPrint('🟣 UPDATE STATUS → ${res.statusCode}');
  debugPrint('🟣 UPDATE RAW → ${res.body}');

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  final rawText = res.body.trim();

  dynamic decoded;
  try {
    decoded = jsonDecode(rawText);
  } catch (e) {
    // هنا لو PHP لسه يرجّع HTML راح تشوفينه في الرسالة
    throw Exception('رد غير صالح من السيرفر: $rawText');
  }

  if (decoded is! Map) {
    throw Exception('شكل الرد غير متوقّع: $decoded');
  }

  final body = Map<String, dynamic>.from(decoded as Map);

  if (body['success'] != true) {
    throw Exception(body['message'] ?? 'فشل في إرسال طلب تحديث الرخصة');
  }

  return body; // فيه requestId و licenseFileName
}



static Future<void> uploadLicenseUpdateFile({
  required int lawyerId,
  required String filePath,
  required String fileName,
}) async {
  final uri = Uri.parse('$base/upload_license_update.php');
  final request = http.MultipartRequest('POST', uri);

  request.fields['lawyer_id'] = lawyerId.toString();
  request.fields['fileName']  = fileName;

  request.files.add(
    await http.MultipartFile.fromPath(
      'license_file',
      filePath,
      filename: fileName,
    ),
  );

  final response = await request.send();
  final respBody = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('فشل رفع ملف الرخصة: HTTP ${response.statusCode}: $respBody');
  }
}

static Future<List<Appointment>> getClientAppointments(int clientId) async {
  final res = await http.post(
    Uri.parse('$base/get_client_appointments.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'clientId': clientId}),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  final body = jsonDecode(res.body);
  if (body is! Map || body['success'] != true) {
    throw Exception(body['message'] ?? 'فشل تحميل المواعيد');
  }

  final List list = body['appointments'] ?? [];
  return list
      .cast<Map<String, dynamic>>()
      .map((m) => Appointment.fromJson(m))
      .toList();
}


static Future<void> cancelAppointment(int appointmentId) async {
  final res = await http.post(
    Uri.parse('$base/cancel_appointment.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'appointmentId': appointmentId}),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  final body = jsonDecode(res.body);
  if (body is! Map || body['success'] != true) {
    throw Exception(body['message'] ?? 'فشل إلغاء الموعد');
  }
}


}

