import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_screen.dart';
import '../services/session.dart';
import '../models/user.dart';
import 'package:flutter/gestures.dart';

class ClientRegisterPage extends StatefulWidget {
  const ClientRegisterPage({super.key});

  @override
  State<ClientRegisterPage> createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers للحقول النصية
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // متغيرات التحقق الفوري
  bool _isCheckingUsername = false;
  bool _isCheckingPhone = false;
  bool _isUsernameAvailable = false;
  bool _isPhoneAvailable = false;
  String? _usernameMessage;
  String? _phoneMessage;
// ===== Policies (like PaymentPage) =====
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
  void initState() {
    super.initState();
    // إضافة مستمعين للتحقق الفوري
    _usernameController.addListener(_checkUsernameAvailability);
    _phoneController.addListener(_checkPhoneAvailability);
  }

  @override
  void dispose() {
    // إزالة المستمعين
    _usernameController.removeListener(_checkUsernameAvailability);
    _phoneController.removeListener(_checkPhoneAvailability);

    // التخلص من جميع الـ controllers
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();

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
        Uri.parse('http://10.164.73.246:8888/mujeer_api/check_availability.php'),
        //Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),

        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'userType': 'client'}),
      );

      var result = json.decode(response.body);
      setState(() {
        _isUsernameAvailable = result['available'];
        _usernameMessage = result['message'];
      });
    } catch (e) {
      print('خطأ في التحقق من اسم المستخدم: $e');
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
        Uri.parse('http://10.164.73.246:8888/mujeer_api/check_availability.php'),
        //Uri.parse('http://10.0.2.2:8888/mujeer_api/check_availability.php'),

        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phone, 'userType': 'client'}),
      );

      var result = json.decode(response.body);
      setState(() {
        _isPhoneAvailable = result['available'];
        _phoneMessage = result['message'];
      });
    } catch (e) {
      print('خطأ في التحقق من رقم الجوال: $e');
    } finally {
      setState(() => _isCheckingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تسجيل عميل جديد',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRegisterForm(),
                    const SizedBox(height: 32),
                    _buildPoliciesSection(),
const SizedBox(height: 16),
                    _buildRegisterButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // نموذج التسجيل
  Widget _buildRegisterForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('معلومات التسجيل'),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _fullNameController,
              label: 'الاسم الكامل *',
              validator: (value) {
                if (value!.isEmpty) return 'الاسم الكامل مطلوب';
                if (value.length < 3)
                  return 'الاسم يجب أن يحتوي على 3 أحرف على الأقل';
                return null;
              },
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
                if (value.length < 6)
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
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
            _buildPhoneField(),
          ],
        ),
      ),
    );
  }

  // حقل اسم المستخدم مع التحقق الفوري
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

  // حقل رقم الجوال مع التحقق الفوري
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

  // زر التسجيل
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _registerClient,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5345),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'تسجيل العميل',
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

  // تسجيل العميل
  void _registerClient() async {
     if (!allAgreed) {
    setState(() {
      _policiesError = 'يجب الموافقة على جميع السياسات للمتابعة';
    });
    return;
  }
    if (!_formKey.currentState!.validate()) {
      _showError('يرجى تعبئة جميع الحقول الإجبارية بشكل صحيح');
      return;
    }

    if (!_isUsernameAvailable || !_isPhoneAvailable) {
      _showError('يرجى التأكد من أن اسم المستخدم ورقم الجوال متاحين');
      return;
    }

    // فقط التوجيه لصفحة OTP أول
    _navigateToOTP();
  }

  // التوجيه إلى صفحة OTP
  void _navigateToOTP() async {
    String phoneNumber = '+966${_phoneController.text.substring(1)}';

    // ننتظر نتيجة التحقق من شاشة OTP
    bool? verified = true;
      await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OTPScreen(
        phoneNumber: phoneNumber,
        registrationType: 'client',
      ),
    ),
  ); 

    // بعد العودة من صفحة OTP
    if (verified == true) {
      // بعد التحقق الناجح من OTP
      await _registerInDatabase();
    } else {
      _showError('فشل التحقق من رقم الجوال');
    }
  }

  // التسجيل في الداتابيز بعد التحقق
  Future<void> _registerInDatabase() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> requestData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
      };

      print('📤 إرسال بيانات العميل بعد التحقق: $requestData');

      //String baseUrl = 'http://10.0.2.2:8888/mujeer_api';
      String baseUrl = 'http://10.164.73.246:8888/mujeer_api';

      var response = await http
          .post(
            Uri.parse('$baseUrl/register_client.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 10));

      var result = json.decode(response.body);

      if (result['success'] == true) {
        final Map<String, dynamic>? userMap = result['user'];

        if (userMap != null) {
          final user = User.fromJson(userMap);
          await Session.saveUser(user); // <-- هذا هو الأهم
        }

        _showSuccess('تم إنشاء الحساب بنجاح!');

        // الانتقال إلى الصفحة الرئيسية
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'userType': 'client',
            'userName': _fullNameController.text,
            'username': _usernameController.text,
          },
        );
      } else {
        _showError(result['message'] ?? 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      _showError('فشل في التسجيل: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
