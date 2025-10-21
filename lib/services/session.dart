import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class Session {
  static const _kUser = 'current_user';

  static Future<void> saveUser(User u) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUser, jsonEncode(u.toJson()));
  }

  static Future<User?> getUser() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kUser);
    if (s == null || s.isEmpty) return null;
    return User.fromJson(jsonDecode(s));
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUser);
  }
}
