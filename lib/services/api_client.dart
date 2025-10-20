import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';
import '../models/user.dart';
import '../models/lawyer_request.dart';
class ApiClient {
  // مهم:
  // على Android Emulator نستخدم 10.0.2.2 بدل localhost
  static const String base = 'http://192.168.3.10:8888/mujeer_api/login.php';
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
    final response = await http.post(
      Uri.parse('$base/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      
      if (body['success'] == true) {
        return User.fromJson(body['user']);
      }
      throw Exception(body['message'] ?? 'فشل تسجيل الدخول');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
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
}
