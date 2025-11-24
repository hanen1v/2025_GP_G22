class User {
  final int id;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String userType; // 'client', 'lawyer', 'admin'
  final int points;
  final String? profileImage;
  final DateTime? registrationDate;
  final String? status; // 'Approved' | 'Pending' | 'Rejected' | null

  // 🟣 حقول المحامي الإضافية
  final int? yearsOfExp;
  final String? mainSpecialization;
  final String? fSubSpecialization;
  final String? sSubSpecialization;
  final String? educationQualification;
  final String? academicMajor;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.userType,
    required this.points,
    this.profileImage,
    this.registrationDate,
    this.status,
    this.yearsOfExp,
    this.mainSpecialization,
    this.fSubSpecialization,
    this.sSubSpecialization,
    this.educationQualification,
    this.academicMajor,
  });

  // من JSON لـ User (للاستقبال من السيرفر)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseId(json),
      fullName: (json['FullName'] ?? json['fullName'] ?? '').toString(),
      username: (json['Username'] ?? json['username'] ?? '').toString(),
      phoneNumber: (json['PhoneNumber'] ?? json['phoneNumber'] ?? '')
          .toString(),
      userType: _determineUserType(json),
      points: int.tryParse('${json['Points'] ?? json['points'] ?? 0}') ?? 0,
      profileImage:
          (json['lawyerPhoto'] ??
                  json['LawyerPhoto'] ??
                  json['profileImage'] ??
                  json['ProfileImage'] ??
                  '')
              .toString(),
      registrationDate: _parseDate(
        json['RegistrationDate'] ?? json['created_at'],
      ),
      status: (json['Status'] ?? json['status'])?.toString(),

      // 🟣 الحقول الإضافية
      yearsOfExp:
          int.tryParse('${json['YearsOfExp'] ?? json['yearsOfExp'] ?? ''}') ??
          null,
      mainSpecialization:
          (json['MainSpecialization'] ?? json['mainSpecialization'])
              ?.toString(),
      fSubSpecialization:
          (json['FSubSpecialization'] ?? json['fSubSpecialization'])
              ?.toString(),
      sSubSpecialization:
          (json['SSubSpecialization'] ?? json['sSubSpecialization'])
              ?.toString(),
      educationQualification:
          (json['EducationQualification'] ?? json['educationQualification'])
              ?.toString(),
      academicMajor: (json['AcademicMajor'] ?? json['academicMajor'])
          ?.toString(),
    );
  }

  // من User لـ JSON (للالرسال للسيرفر أو الحفظ)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FullName': fullName,
      'Username': username,
      'PhoneNumber': phoneNumber,
      'UserType': userType,
      'Points': points,
      'ProfileImage': profileImage,
      'RegistrationDate': registrationDate?.toIso8601String(),
      'Status': status,

      'YearsOfExp': yearsOfExp,
      'MainSpecialization': mainSpecialization,
      'FSubSpecialization': fSubSpecialization,
      'SSubSpecialization': sSubSpecialization,
      'EducationQualification': educationQualification,
      'AcademicMajor': academicMajor,
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
    if (json['UserID'] != null) {
      return int.tryParse('${json['UserID']}') ?? 0;
    }
    if (json['ClientID'] != null) {
      return int.tryParse('${json['ClientID']}') ?? 0;
    }
    if (json['LawyerID'] != null) {
      return int.tryParse('${json['LawyerID']}') ?? 0;
    }
    if (json['AdminID'] != null) {
      return int.tryParse('${json['AdminID']}') ?? 0;
    }
    return int.tryParse('${json['id'] ?? json['Id'] ?? 0}') ?? 0;
  }

  // دالة مساعدة لتحويل التاريخ
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
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
      return '';
    }
    const baseUrl = 'http://10.0.2.2:8888/mujeer_api';
    //const baseUrl = 'http://192.168.3.10:8888/mujeer_api';
    return '$baseUrl/uploads/$profileImage';
  }

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

  // دوال مساعدة لحالة المحامي
  String get statusNormalized {
    final s = (status ?? '').trim().toLowerCase();
    if (s == 'approved') return 'Approved';
    if (s == 'rejected') return 'Rejected';
    return 'Pending';
  }

  bool get isApproved => statusNormalized == 'Approved';
  bool get isRejected => statusNormalized == 'Rejected';
  bool get isPending => statusNormalized == 'Pending';

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

  User copyWith({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? userType,
    int? points,
    String? profileImage,
    DateTime? registrationDate,
    String? status,

    int? yearsOfExp,
    String? mainSpecialization,
    String? fSubSpecialization,
    String? sSubSpecialization,
    String? educationQualification,
    String? academicMajor,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      points: points ?? this.points,
      profileImage: profileImage ?? this.profileImage,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,

      yearsOfExp: yearsOfExp ?? this.yearsOfExp,
      mainSpecialization: mainSpecialization ?? this.mainSpecialization,
      fSubSpecialization: fSubSpecialization ?? this.fSubSpecialization,
      sSubSpecialization: sSubSpecialization ?? this.sSubSpecialization,
      educationQualification:
          educationQualification ?? this.educationQualification,
      academicMajor: academicMajor ?? this.academicMajor,
    );
  }
}

// نموذج لبيانات تسجيل الدخول
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
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
