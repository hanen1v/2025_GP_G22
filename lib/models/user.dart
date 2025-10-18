
class User {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String userType; // 'client', 'lawyer', 'admin'
  final int points;
  final String? profileImage;
  final DateTime? registrationDate;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.points,
    this.profileImage,
    this.registrationDate,
  });

  // من JSON لـ User (للاستقبال من السيرفر)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseId(json),
      fullName: (json['FullName'] ?? json['fullName'] ?? '').toString(),
      username: (json['Username'] ?? json['username'] ?? '').toString(),
      email: (json['Email'] ?? json['email'] ?? '').toString(),
      phoneNumber: (json['PhoneNumber'] ?? json['phoneNumber'] ?? '').toString(),
      userType: _determineUserType(json),
      points: int.tryParse('${json['Points'] ?? json['points'] ?? 0}') ?? 0,
      profileImage: (json['LawyerPhoto'] ?? json['ProfileImage'] ?? '').toString(),
      registrationDate: _parseDate(json['RegistrationDate'] ?? json['created_at']),
    );
  }

  // من User لـ JSON (للالرسال للسيرفر)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'points': points,
      'profileImage': profileImage,
      'registrationDate': registrationDate?.toIso8601String(),
    };
  }

  // دالة مساعدة لتحديد نوع المستخدم
  static String _determineUserType(Map<String, dynamic> json) {
    if (json['ClientID'] != null || json['client_id'] != null) return 'client';
    if (json['LawyerID'] != null || json['lawyer_id'] != null) return 'lawyer';
    if (json['AdminID'] != null || json['admin_id'] != null) return 'admin';
    return (json['UserType'] ?? json['userType'] ?? 'client').toString();
  }

  // دالة مساعدة لتحويل ID
  static int _parseId(Map<String, dynamic> json) {
    if (json['ClientID'] != null) return int.tryParse('${json['ClientID']}') ?? 0;
    if (json['LawyerID'] != null) return int.tryParse('${json['LawyerID']}') ?? 0;
    if (json['AdminID'] != null) return int.tryParse('${json['AdminID']}') ?? 0;
    return int.tryParse('${json['id'] ?? json['Id'] ?? 0}') ?? 0;
  }

  // دالة مساعدة لتحويل التاريخ
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return null;
    }
  }

  // دوال مساعدة للتحقق من نوع المستخدم
  bool get isClient => userType == 'client';
  bool get isLawyer => userType == 'lawyer';
  bool get isAdmin => userType == 'admin';

  // دالة للحصول على الصورة (مع صورة افتراضية)
  String get profileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) {
      return ''; // يمكن إرجاع صورة افتراضية
    }
    
    const baseUrl = 'http://10.0.2.2:8888/mujeer_api';
    return '$baseUrl/uploads/$profileImage';
  }

  // دالة لعرض معلومات المستخدم بشكل جميل
  String get displayInfo {
    return '$fullName ($username) - ${_getUserTypeArabic()}';
  }

  String _getUserTypeArabic() {
    switch (userType) {
      case 'client':
        return 'عميل';
      case 'lawyer':
        return 'محامي';
      case 'admin':
        return 'مشرف';
      default:
        return 'مستخدم';
    }
  }

  @override
  String toString() {
    return 'User{id: $id, name: $fullName, type: $userType}';
  }

  // دالة للمقارنة بين مستخدمين
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// نموذج لبيانات تسجيل الدخول
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// نموذج لرد السيرفر بعد التسجيل
class LoginResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  LoginResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token']?.toString(),
    );
  }
}