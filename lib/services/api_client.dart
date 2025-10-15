import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lawyer.dart';

class ApiClient {
  // مهم:
  // على Android Emulator نستخدم 10.0.2.2 بدل localhost
  static const String base = 'http://10.0.2.2:8888/mujeer_api';
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
}
