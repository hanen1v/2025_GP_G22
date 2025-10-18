import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';
import '../models/user.dart';
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
}
