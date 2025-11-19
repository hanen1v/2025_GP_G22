import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';
import '../models/user.dart';
import '../models/lawyer_request.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';

class ApiClient {
  // مهم:
  // على Android Emulator نستخدم 10.0.2.2 بدل localhost
  static const String base = 'http://192.168.3.10:8888/mujeer_api';
  // على iOS Simulator أو Flutter Web على نفس الجهاز:
  // static const String base = 'http://localhost:8888/mujeer_api';

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

  // ✅ الدالة المصححة
  static Future<User?> getUserByUsername(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$base/verify_username.php'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return User.fromJson(data['user']);
        } else {
          print('❌ المستخدم غير موجود: ${data['message']}');
          return null;
        }
      } else {
        print('❌ خطأ في السيرفر: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ فشل في جلب بيانات المستخدم: $e');
      return null;
    }
  }

  static Future<bool> resetPassword(String username, String otp, String newPassword) async {
  try {
    final response = await http.post(
      Uri.parse('$base/reset_password.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      print('❌ خطأ في السيرفر: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ فشل في إعادة تعيين كلمة المرور: $e');
    return false;
  }
}


  // ✅ دالة حذف المحامي المضافة
  static Future<void> deleteLawyer({required int lawyerId}) async {
    try {
      final response = await http.post(
        Uri.parse('$base/delete_lawyer.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'lawyer_id': lawyerId}),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body);
      if (data is! Map || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete lawyer');
      }
    } catch (e) {
      print('❌ فشل في حذف المحامي: $e');
      rethrow;
    }
  }
 /// تحديث سعر المحامي
static Future<bool> updateLawyerPrice(int lawyerId, double price) async {
  try {
    final response = await http.post(
      Uri.parse('$base/lawyer_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lawyer_id': lawyerId,
        'price': price,
        'action': 'update_price'
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    print('Error updating lawyer price: $e');
    return false;
  }
}

/// حفظ الأوقات المتاحة للمحامي
static Future<bool> saveAvailability(int lawyerId, List<Map<String, dynamic>> availabilityData) async {
  try {
    final response = await http.post(
      Uri.parse('$base/lawyer_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lawyer_id': lawyerId,
        'availability': availabilityData,
        'action': 'save_availability'
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    print('Error saving availability: $e');
    return false;
  }
}

/// جلب الأوقات المتاحة الحالية للمحامي
static Future<Map<String, dynamic>> getCurrentAvailability(int lawyerId) async {
  try {
    final response = await http.post(
      Uri.parse('$base/lawyer_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lawyer_id': lawyerId,
        'action': 'get_availability'
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'data': data['data'] ?? [],
      };
    }
    return {'success': false, 'data': []};
  } catch (e) {
    print('Error getting availability: $e');
    return {'success': false, 'data': []};
  }
}

/// جلب سعر المحامي الحالي
static Future<double> getLawyerPrice(int lawyerId) async {
  try {
    final response = await http.post(
      Uri.parse('$base/lawyer_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lawyer_id': lawyerId,
        'action': 'get_price'
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['price'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  } catch (e) {
    print('Error getting lawyer price: $e');
    return 0.0;
  }
}

/// حذف الأوقات المتاحة
static Future<bool> deleteAvailability(int lawyerId) async {
  try {
    final response = await http.post(
      Uri.parse('$base/lawyer_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'lawyer_id': lawyerId,
        'action': 'delete_all'
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  } catch (e) {
    print('Error deleting availability: $e');
    return false;
  }
}
}