import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'otp_screen.dart';
import '../services/session.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'package:flutter/gestures.dart';

class LawyerRegisterPage extends StatefulWidget {
  const LawyerRegisterPage({super.key});

  @override
  State<LawyerRegisterPage> createState() => _LawyerRegisterPageState();
}

class _LawyerRegisterPageState extends State<LawyerRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers للحقول النصية
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _startMonthController = TextEditingController();
  final _startYearController = TextEditingController();
  // للملفات
  String? _licenseFileName;
  String? _profileImageName;
  PlatformFile? _licenseFile;
  PlatformFile? _profileImage;

  // للتخصصات (قوائم محددة)
  String? _selectedGender;
  String? _selectedMainSpecialization;
  String? _selectedSubSpecialization1;
  String? _selectedSubSpecialization2;
  String? _selectedEducationLevel;
  String? _selectedAcademicMajor;

  // لإظهار/إخفاء كلمة المرور
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // القوائم المحددة
  final List<String> _genders = ['ذكر', 'أنثى'];
  final List<String> _mainSpecializations = [
    'القضايا الجنائية',
    'القضايا الأسرية',
    'القضايا التجارية',
    'القضايا العمالية',
    'القضايا العقارية',
    'القضايا الإدارية',
    'القضايا المالية',
    'قضايا الأحوال الشخصية',
  ];
  final List<String> _subSpecializations = [
     'القضايا الجنائية',
    'القضايا الأسرية',
    'القضايا التجارية',
    'القضايا العمالية',
    'القضايا العقارية',
    'القضايا الإدارية',
    'القضايا المالية',
    'قضايا الأحوال الشخصية',
  ];
  final List<String> _educationLevels = [
    'بكالوريوس',
    'ماجستير',
    'دكتوراه',
    'دبلوم',
  ];
  final List<String> _academicMajors = ['الشريعة', 'القانون'];

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isCheckingPhone = false;
  bool _isCheckingLicense = false;
  bool _isLicenseAvailable = false;
bool _isUsernameAvailable = false;
bool _isPhoneAvailable = false;


  String? _usernameMessage;
  String? _phoneMessage;
  String? _licenseMessage;
  @override
  void initState() {
    super.initState();
    // إضافة مستمعين للتحقق الفوري
    _usernameController.addListener(_checkUsernameAvailability);
    _phoneController.addListener(_checkPhoneAvailability);
    _licenseController.addListener(_checkLicenseAvailability);
  }
final Color mainColor = const Color(0xFF0B5345);

bool agreeTerms = false;
bool agreeData = false;
bool agreeService = false;

bool get allAgreed => agreeTerms && agreeData && agreeService;

String? _policiesError;

final TextStyle checkboxTextStyle = const TextStyle(
  fontSize: 13,
  color: Color(0xFF0B5345),
  fontWeight: FontWeight.w400,
);

void _showTermsPopup() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'الشروط والأحكام',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: mainColor),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    '''
طبيعة الخدمات
1. يقر المستخدم علمه وموافقته على أن الخدمات المقدمة عبر التطبيق:
 • هي خدمات استشارية قانونية تهدف إلى التوجيه العام.
 • تعتمد على المعلومات والمستندات المقدمة من المستخدم.
2. لا تُعد الاستشارات أو الملاحظات:
 • ضمانًا لتحقيق نتيجة قانونية أو قضائية معينة.
 • ولا تشكل تعهدًا بسلامة أي إجراء قانوني أو تعاقدي.
3. لا تغني هذه الخدمات عن:
 • التمثيل النظامي أمام الجهات القضائية.
 • أو الاستعانة بمحامٍ مرخص عند الحاجة لذلك.

مسؤولية المستخدم
1. يقر المستخدم ويضمن:
 • صحة واكتمال البيانات والمعلومات المقدمة.
 • نظامية المستندات والعقود المرفوعة.
2. يتحمل المستخدم كامل المسؤولية عن:
 • أي خطأ أو نقص في المعلومات.
 • أي نتائج تترتب على الاعتماد على الاستشارة.

حدود المسؤولية
1. لا يتحمل التطبيق أو المستشار أي مسؤولية عن:
 • أي خسائر غير مباشرة أو تبعية.
 • فوات أرباح أو فرص تجارية.
 • أي أضرار ناتجة عن تطبيق الاستشارة.
2. يقتصر الحد الأعلى للمسؤولية على قيمة الرسوم المدفوعة فقط.

السرية وحماية البيانات
1. يلتزم التطبيق بالحفاظ على سرية:
 • جميع بيانات المستخدم.
 • العقود والمستندات القانونية.
2. لا يتم الإفصاح عن أي بيانات إلا:
 • بموافقة المستخدم.
 • أو بموجب أمر نظامي.

حقوق الملكية الفكرية
1. جميع التقارير والملاحظات والآراء والاستشارات تعتبر ملكية فكرية للتطبيق أو لمقدّم الخدمة.
2. يمنح المستخدم حق استعمالها لغرضه الشخصي أو التجاري الخاص فقط.
3. يمنع نسخها أو إعادة بيعها أو نشرها دون موافقة خطية مسبقة.

الرسوم وسياسة الإلغاء والاسترجاع
1. تستحق الرسوم كاملة بمجرد بدء تقديم الخدمة.
2. لا يحق للمستخدم طلب استرجاع المبلغ بعد بدء تنفيذ الخدمة.
3. يحق للتطبيق رفض تقديم الخدمة إذا كانت مخالفة للأنظمة أو الآداب العامة.

النظام الواجب التطبيق والاختصاص
1. تخضع هذه الشروط لأنظمة ولوائح المملكة العربية السعودية.
2. تختص محاكم المملكة بالفصل في أي نزاع ينشأ عن هذه الشروط.
''',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        agreeTerms = true;
                        _policiesError = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'أوافق',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  @override
  void dispose() {
    _usernameController.removeListener(_checkUsernameAvailability);
    _phoneController.removeListener(_checkPhoneAvailability);
    _licenseController.removeListener(_checkLicenseAvailability);
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _startMonthController.dispose();
    _startYearController.dispose();
    super.dispose();
  }

  // التحقق الفوري من اسم المستخدم
  void _checkUsernameAvailability() async {
  String username = _usernameController.text.trim();
  if (username.length < 3) {
    setState(() {
      _usernameMessage = null;
      _isUsernameAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingUsername = true);

  try {
    var response = await http.post(
      Uri.parse('https://2025gpg22-production.up.railway.app/check_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'userType': 'lawyer'}),
    );

    var result = json.decode(response.body);
    print('📥 استجابة التحقق من اسم المستخدم: $result'); // للتصحيح
    
    setState(() {
      // التحقق من وجود الحقل available وليس null
      if (result.containsKey('available') && result['available'] != null) {
        _isUsernameAvailable = result['available'] == true || result['available'] == 1;
      } else {
        _isUsernameAvailable = false;
      }
      _usernameMessage = result['message']?.toString() ?? 'حدث خطأ في التحقق';
    });
  } catch (e) {
    print('خطأ في التحقق من اسم المستخدم: $e');
    setState(() {
      _isUsernameAvailable = false;
      _usernameMessage = 'خطأ في الاتصال بالخادم';
    });
  } finally {
    setState(() => _isCheckingUsername = false);
  }
}

  // التحقق الفوري من رقم الجوال
  void _checkPhoneAvailability() async {
  String phone = _phoneController.text.trim();
  if (phone.length < 10 || !RegExp(r'^05\d{8}$').hasMatch(phone)) {
    setState(() {
      _phoneMessage = null;
      _isPhoneAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingPhone = true);

  try {
    var response = await http.post(
      Uri.parse('https://2025gpg22-production.up.railway.app/check_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phone, 'userType': 'lawyer'}),
    );

    var result = json.decode(response.body);
    print('📥 استجابة التحقق من رقم الجوال: $result'); // للتصحيح
    
    setState(() {
      if (result.containsKey('available') && result['available'] != null) {
        _isPhoneAvailable = result['available'] == true || result['available'] == 1;
      } else {
        _isPhoneAvailable = false;
      }
      _phoneMessage = result['message']?.toString() ?? 'حدث خطأ في التحقق';
    });
  } catch (e) {
    print('خطأ في التحقق من رقم الجوال: $e');
    setState(() {
      _isPhoneAvailable = false;
      _phoneMessage = 'خطأ في الاتصال بالخادم';
    });
  } finally {
    setState(() => _isCheckingPhone = false);
  }
}

  // التحقق الفوري من رقم الرخصة
  void _checkLicenseAvailability() async {
  String license = _licenseController.text.trim();
  if (license.isEmpty) {
    setState(() {
      _licenseMessage = null;
      _isLicenseAvailable = false;
    });
    return;
  }

  setState(() => _isCheckingLicense = true);

  try {
    var response = await http.post(
      Uri.parse('https://2025gpg22-production.up.railway.app/check_availability.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'licenseNumber': license, 'userType': 'lawyer'}),
    );

    var result = json.decode(response.body);
    print('📥 استجابة التحقق من رقم الرخصة: $result'); // للتصحيح
    
    setState(() {
      if (result.containsKey('available') && result['available'] != null) {
        _isLicenseAvailable = result['available'] == true || result['available'] == 1;
      } else {
        _isLicenseAvailable = false;
      }
      _licenseMessage = result['message']?.toString() ?? 'حدث خطأ في التحقق';
    });
  } catch (e) {
    print('خطأ في التحقق من رقم الرخصة: $e');
    setState(() {
      _isLicenseAvailable = false;
      _licenseMessage = 'خطأ في الاتصال بالخادم';
    });
  } finally {
    setState(() => _isCheckingLicense = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تسجيل محامي جديد',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 20),
                    _buildSpecializationSection(),
                    const SizedBox(height: 20),
                    _buildFilesSection(),
                    const SizedBox(height: 32),
                    _buildPoliciesSection(),   
const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // قسم المعلومات الأساسية
  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('المعلومات الأساسية'),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _fullNameController,
              label: 'الاسم الكامل *',
              validator: (value) =>
                  value!.isEmpty ? 'الاسم الكامل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildUsernameField(),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _passwordController,
              label: 'كلمة المرور *',
              obscureText: _obscurePassword,
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
               validator: (value) {
  if (value!.isEmpty) return 'كلمة المرور مطلوبة';
  if (value.length < 8) 
    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  if (value.contains(' '))
    return 'كلمة المرور يجب ألا تحتوي على مسافات';
  if (!RegExp(r'[A-Z]').hasMatch(value))
    return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
  if (!RegExp(r'[a-z]').hasMatch(value))
    return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
  if (!RegExp(r'[0-9]').hasMatch(value))
    return 'يجب أن تحتوي على رقم واحد على الأقل';
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
    return 'يجب أن تحتوي على حرف خاص واحد على الأقل (!@#\$%)';
  return null;
}
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور *',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (value) {
                if (value!.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (value != _passwordController.text)
                  return 'كلمة المرور غير متطابقة';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPhoneField(),
          ],
        ),
      ),
    );
  }

  // قسم التخصصات
  Widget _buildSpecializationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('المعلومات المهنية'),
            const SizedBox(height: 16),
            _buildLicenseField(),
            const SizedBox(height: 12),
            _buildTextFormField(
  controller: _startMonthController,
  label: 'شهر بداية الممارسة *',
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال شهر البداية';
    }
    final month = int.tryParse(value);
    if (month == null || month < 1 || month > 12) {
      return 'أدخل شهر صحيح من 1 إلى 12';
    }
    return null;
  },
),
const SizedBox(height: 12),
_buildTextFormField(
  controller: _startYearController,
  label: 'سنة بداية الممارسة *',
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال سنة البداية';
    }
    final year = int.tryParse(value);
    final currentYear = DateTime.now().year;
    if (year == null || year < 1900 || year > currentYear) {
      return 'أدخل سنة صحيحة';
    }
    return null;
  },
),
const SizedBox(height: 12),

            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedGender,
              items: _genders,
              label: 'الجنس *',
              onChanged: (value) => setState(() => _selectedGender = value),
              validator: (value) => value == null ? 'الجنس مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedMainSpecialization,
              items: _mainSpecializations,
              label: 'التخصص الرئيسي *',
              onChanged: (value) =>
                  setState(() => _selectedMainSpecialization = value),
              validator: (value) =>
                  value == null ? 'التخصص الرئيسي مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSubSpecialization1,
              items: _subSpecializations,
              label: 'التخصص الفرعي الأول',
              onChanged: (value) =>
                  setState(() => _selectedSubSpecialization1 = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSubSpecialization2,
              items: _subSpecializations,
              label: 'التخصص الفرعي الثاني',
              onChanged: (value) =>
                  setState(() => _selectedSubSpecialization2 = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedEducationLevel,
              items: _educationLevels,
              label: 'المؤهل العلمي *',
              onChanged: (value) =>
                  setState(() => _selectedEducationLevel = value),
              validator: (value) =>
                  value == null ? 'المؤهل العلمي مطلوب' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedAcademicMajor,
              items: _academicMajors,
              label: 'التخصص الأكاديمي *',
              onChanged: (value) =>
                  setState(() => _selectedAcademicMajor = value),
              validator: (value) =>
                  value == null ? 'التخصص الأكاديمي مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  // قسم رفع الملفات
  Widget _buildFilesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('الملفات المطلوبة'),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'رخصة المحاماة *',
              fileName: _licenseFileName,
              onPressed: _pickLicenseFile,
              isRequired: true,
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى ادخال ملف بصيغة pdf',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            _buildFilePicker(
              label: 'الصورة الشخصية',
              fileName: _profileImageName,
              onPressed: _pickProfileImage,
              isRequired: false,
            ),
            const SizedBox(height: 8),
            Text(
              'الملفات المسموحة: PDF, JPG, PNG, DOC (الحجم الأقصى: 10MB)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // زر التسجيل
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _registerLawyer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5345),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'تسجيل المحامي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ========== الدوال المساعدة ==========
Widget _buildPoliciesSection() {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الموافقات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B5345),
            ),
          ),
          const SizedBox(height: 8),

          CheckboxListTile(
            dense: true,
            value: agreeTerms,
            onChanged: (v) => setState(() {
              agreeTerms = v ?? false;
              _policiesError = null;
            }),
            activeColor: mainColor,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: RichText(
              text: TextSpan(
                style: checkboxTextStyle,
                children: [
                  const TextSpan(text: 'قرأت وفهمت '),
                  TextSpan(
                    text: 'الشروط والأحكام',
                    style: checkboxTextStyle.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showTermsPopup,
                  ),
                  const TextSpan(text: ' وأوافق عليها'),
                ],
              ),
            ),
          ),

          CheckboxListTile(
            dense: true,
            value: agreeData,
            onChanged: (v) => setState(() {
              agreeData = v ?? false;
              _policiesError = null;
            }),
            activeColor: mainColor,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'أقر بصحة البيانات والمستندات المقدمة.',
              style: checkboxTextStyle,
            ),
          ),

          CheckboxListTile(
            dense: true,
            value: agreeService,
            onChanged: (v) => setState(() {
              agreeService = v ?? false;
              _policiesError = null;
            }),
            activeColor: mainColor,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'أفهم أن الخدمة استشارية ولا تضمن نتيجة معينة.',
              style: checkboxTextStyle,
            ),
          ),

          if (_policiesError != null) ...[
            const SizedBox(height: 8),
            Text(
              _policiesError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0B5345),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0B5345)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0B5345)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontFamily: 'Tajawal')),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0B5345)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFilePicker({
    required String label,
    required String? fileName,
    required VoidCallback onPressed,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B5345),
            side: const BorderSide(color: Color(0xFF0B5345)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
  children: [
    Expanded(
      child: Text(
        fileName ?? 'اختر ملف',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: fileName != null ? Colors.black : Colors.grey,
        ),
      ),
    ),
    const SizedBox(width: 8),
    const Icon(Icons.attach_file),
  ],
),

        ),
        if (isRequired && fileName == null) ...[
          const SizedBox(height: 4),
          Text(
            'هذا الحقل مطلوب',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ],
    );
  }

  // اختيار ملف الرخصة
  void _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _licenseFile = result.files.single;
          _licenseFileName = _licenseFile!.name;
        });
      }
    } catch (e) {
      _showError('حدث خطأ في اختيار الملف: $e');
    }
  }

  // اختيار الصورة الشخصية
  void _pickProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _profileImage = result.files.single;
          _profileImageName = _profileImage!.name;
        });
      }
    } catch (e) {
      _showError('حدث خطأ في اختيار الصورة: $e');
    }
  }

  //تسجيل المحامي
  Future<void> _registerLawyer() async {
    if (!allAgreed) {
  setState(() {
    _policiesError = 'يجب الموافقة على جميع السياسات للمتابعة';
  });
  return;
}

    //التحقق من اليونيكية أولاً
    if (!_isUsernameAvailable || !_isPhoneAvailable || !_isLicenseAvailable) {
      _showError(
        'يرجى التأكد من أن اسم المستخدم ورقم الجوال ورقم الرخصة متاحين',
      );
      return;
    }
    // التحقق من البيانات الأساسية
    if (!_formKey.currentState!.validate()) {
      _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
      return;
    }

    if (_licenseFile == null) {
      _showError('يرجى رفع رخصة المحاماة');
      return;
    }

    // استدعاء OTP أولاً والانتظار للنتيجة
    bool? otpVerified = await _navigateToOTP();

    // إذا التحقق نجح، أرسل البيانات للسيرفر
    if (otpVerified == true) {
      await _sendLawyerToServer();
    } else {
      _showError('فشل التحقق من رقم الجوال');
    }
  }

  // التوجيه إلى صفحة OTP
  Future<bool?> _navigateToOTP() async {
    String phoneNumber = '+966${_phoneController.text.substring(1)}';

    // انتظار نتيجة التحقق من OTP
    bool? verified = true;

      await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(
          phoneNumber: phoneNumber,
          registrationType: 'lawyer',
          ),
      ),
    ); 

    print('✅ نتيجة OTP: $verified');

    return verified; // ترجع true أو false أو null
  }

  // دالة محسنة لإرسال بيانات المحامي
  Future<void> _sendLawyerToServer() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> requestData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'startMonth': int.parse(_startMonthController.text),
        'startYear': int.parse(_startYearController.text),
        'gender': _selectedGender,
        'mainSpecialization': _selectedMainSpecialization,
        'fSubSpecialization': _selectedSubSpecialization1 ?? '',
        'sSubSpecialization': _selectedSubSpecialization2 ?? '',
        'educationQualification': _selectedEducationLevel,
        'academicMajor': _selectedAcademicMajor,
      };

      print('📤 إرسال بيانات المحامي بعد التحقق الناجح: $requestData');

      const String baseUrl = 'https://2025gpg22-production.up.railway.app';
print('📤 JSON المرسل: ${json.encode(requestData)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register_lawyer.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 10));

      print("📥 Status Code: ${response.statusCode}");
print("📥 Body: ${response.body}");

      final result = json.decode(response.body);

      if (result['success'] == true) {
        final int lawyerId = result['userId'] ?? 0;

        // نقرأ user من الـ PHP
        final Map<String, dynamic>? userMap = (result['user'] as Map?)
            ?.cast<String, dynamic>();

        User? user;
        if (userMap != null) {
          // نضيف UserType = 'lawyer' احتياط حتى لو backend نسي
          user = User.fromJson({...userMap, 'UserType': 'lawyer'});
        }

        // أولاً: نرفع ملف الرخصة فقط (لو موجود)
        if (_licenseFile != null && _licenseFile!.path != null) {
          final licenseName =
              (result['licenseFileName'] ??
                      'license_${_usernameController.text}.pdf')
                  .toString();

          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/upload_files.php'),
          );

          request.fields['fileName'] = licenseName;
          request.files.add(
            await http.MultipartFile.fromPath(
              'license_file',
              _licenseFile!.path!,
              filename: licenseName,
            ),
          );

          final uploadRes = await request.send();
          final uploadBody = await uploadRes.stream.bytesToString();
          print('📤 رفع الرخصة: $uploadBody');
        }

        // ثانياً: لو فيه صورة شخصية، نرفعها بالـ API الشغال
        // قبل
if (_profileImage != null && _profileImage!.path != null) {
  try {
    final newFileName = await ApiClient.uploadLawyerPhoto(
      userId: lawyerId,
      imagePath: _profileImage!.path!,
    );
    if (user != null && newFileName.isNotEmpty) {
      user = user.copyWith(profileImage: newFileName);
    }
  } catch (e) {
    print('⚠️ فشل رفع الصورة عند التسجيل: $e');
  }
}

// بعد — أضيفي _showSuccessAndNavigate() داخل try بعد رفع الصورة مباشرة
if (_profileImage != null && _profileImage!.path != null) {
  try {
    final newFileName = await ApiClient.uploadLawyerPhoto(
      userId: lawyerId,
      imagePath: _profileImage!.path!,
    );
    if (user != null && newFileName.isNotEmpty) {
      user = user.copyWith(profileImage: newFileName);
    }
  } catch (e) {
    print('⚠️ فشل رفع الصورة، نكمل بدونها: $e');
    // نكمل حتى لو فشل رفع الصورة
  }
}

// تأكدي إن هذا الجزء موجود بعد الـ if مباشرة
if (user != null) {
  await Session.saveUser(user);
}
_showSuccessAndNavigate();

        // أخيراً: نخزن اليوزر في السيشن ونروح لصفحة المزيد
        if (user != null) {
          print('👤 USER AFTER REGISTER = $user');
          print('🖼️ profileImage = ${user.profileImage}');
          print('🖼️ profileImageUrl = ${user.profileImageUrl}');
          await Session.saveUser(user);
        }

        _showSuccessAndNavigate();
      } else {
        _showError(result['message'] ?? 'حدث خطأ غير معروف');
      }
    } catch (e) {
      _showError('فشل في التسجيل: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // دالة محسنة لرفع الملفات
  Future<void> _uploadFiles(
    int lawyerId,
    Map<String, dynamic> result,
    String baseUrl,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_files.php'),
      );

      // إضافة معرف المحامي
      request.fields['lawyer_id'] = lawyerId.toString();

      // رفع ملف الرخصة إذا موجود
      if (_licenseFile != null && _licenseFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_file',
            _licenseFile!.path!,
            filename:
                result['licenseFileName'] ??
                'license_${_usernameController.text}.pdf',
          ),
        );
      }

      // رفع الصورة الشخصية إذا موجودة
      if (_profileImage != null && _profileImage!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path!,
            filename:
                result['photoFileName'] ??
                'photo_${_usernameController.text}.jpg',
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('📤 رفع الملفات: $responseData');
    } catch (e) {
      print('⚠️ حدث خطأ في رفع الملفات: $e');
    }
  }

  // دالة مساعدة لرفع الملفات
  Future<void> _uploadFile(
    PlatformFile file,
    String fileName,
    String baseUrl,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_files.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: fileName,
        ),
      );

      request.fields['fileName'] = fileName;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('📤 رفع الملف: $fileName');
      print('📥 استجابة رفع الملف: $responseData');
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
    }
  }

  // عرض النجاح والتوجيه
  void _showSuccessAndNavigate() {
    // عرض رسالة النجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تسجيل المحامي بنجاح! سيتم مراجعة طلبك من قبل الإدارة.',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // التوجيه بعد فترة بسيطة
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/lawyer/more');
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'اسم المستخدم *',
            labelStyle: const TextStyle(fontFamily: 'Tajawal'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0B5345)),
            ),
            suffixIcon: _isCheckingUsername
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _usernameController.text.length >= 3
                ? Icon(
                    _isUsernameAvailable ? Icons.check_circle : Icons.error,
                    color: _isUsernameAvailable ? Colors.green : Colors.red,
                  )
                : null,
          ),
          validator: (value) {
            if (value!.isEmpty) return 'اسم المستخدم مطلوب';
            if (value.length < 3) return 'يجب أن يحتوي على 3 أحرف على الأقل';
            if (value.contains(' ')) return 'لا يمكن أن يحتوي على مسافات';
            if (!_isUsernameAvailable && value.length >= 3)
              return 'اسم المستخدم محجوز';
            return null;
          },
        ),
        if (_usernameMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _usernameMessage!,
            style: TextStyle(
              color: _isUsernameAvailable ? Colors.green : Colors.red,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'رقم الجوال *',
            hintText: '05XXXXXXXX',
            labelStyle: const TextStyle(fontFamily: 'Tajawal'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0B5345)),
            ),
            suffixIcon: _isCheckingPhone
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _phoneController.text.length >= 10
                ? Icon(
                    _isPhoneAvailable ? Icons.check_circle : Icons.error,
                    color: _isPhoneAvailable ? Colors.green : Colors.red,
                  )
                : null,
          ),
          validator: (value) {
            if (value!.isEmpty) return 'رقم الجوال مطلوب';
            if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
              return 'يجب أن يبدأ بـ 05 ويحتوي 10 أرقام';
            }
            if (!_isPhoneAvailable && value.length == 10)
              return 'رقم الجوال مسجل مسبقاً';
            return null;
          },
        ),
        if (_phoneMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _phoneMessage!,
            style: TextStyle(
              color: _isPhoneAvailable ? Colors.green : Colors.red,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLicenseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _licenseController,
          decoration: InputDecoration(
            labelText: 'رقم الرخصة *',
            labelStyle: const TextStyle(fontFamily: 'Tajawal'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0B5345)),
            ),
            suffixIcon: _isCheckingLicense
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _licenseController.text.isNotEmpty
                ? Icon(
                    _isLicenseAvailable ? Icons.check_circle : Icons.error,
                    color: _isLicenseAvailable ? Colors.green : Colors.red,
                  )
                : null,
          ),
          validator: (value) {
            if (value!.isEmpty) return 'رقم الرخصة مطلوب';
            if (!_isLicenseAvailable && value.isNotEmpty)
              return 'رقم الرخصة مسجل مسبقاً';
            return null;
          },
        ),
        if (_licenseMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _licenseMessage!,
            style: TextStyle(
              color: _isLicenseAvailable ? Colors.green : Colors.red,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ],
    );
  }
}
