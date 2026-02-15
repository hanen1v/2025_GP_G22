import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_bottom_nav.dart';
import '../services/session.dart';
import '../models/user.dart';
import 'package:flutter/gestures.dart';
import '../models/request_type.dart'; 

class PaymentPage extends StatefulWidget {
  final int lawyerId;
  final int timeslotId;
  final double price;
  final String caseDetails;
  final String? attachedFileName;
final RequestType requestType;

  const PaymentPage({
    super.key,
    required this.lawyerId,
    required this.timeslotId,
    required this.price,
    required this.caseDetails,
    this.attachedFileName,
      required this.requestType,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String? _cardError;
  String? _expiryError;
  String? _cvvError;
  bool _isPaying = false;

  final Color mainColor = const Color.fromARGB(255, 6, 61, 65);


  bool agreeTerms = false;
  bool agreeData = false;
  bool agreeService = false;

  bool get allAgreed => agreeTerms && agreeData && agreeService;


  bool _validate() {
    bool ok = true;
    _cardError = null;
    _expiryError = null;
    _cvvError = null;

    String number = _cardNumberController.text.replaceAll(' ', '');
    if (number.length != 16 || int.tryParse(number) == null) {
      _cardError = 'أدخل رقم بطاقة صحيح مكون من 16 رقم';
      ok = false;
    }

    String cvv = _cvvController.text.trim();
    if (cvv.length != 3 || int.tryParse(cvv) == null) {
      _cvvError = 'أدخل CVV صحيح من 3 أرقام';
      ok = false;
    }

    String expiry = _expiryController.text.trim();
    RegExp re = RegExp(r'^\d{2}/\d{2}$');

    if (!re.hasMatch(expiry)) {
      _expiryError = 'الصيغة يجب أن تكون MM/YY';
      ok = false;
    } else {
      final parts = expiry.split('/');
      final int? month = int.tryParse(parts[0]);
      final int? year = int.tryParse(parts[1]);

      if (month == null || year == null || month < 1 || month > 12) {
        _expiryError = 'شهر غير صالح';
        ok = false;
      } else {
        final now = DateTime.now();
        final expiryDate = DateTime(2000 + year, month + 1, 0);

        if (expiryDate.isBefore(now)) {
          _expiryError = 'البطاقة منتهية الصلاحية';
          ok = false;
        }
      }
    }

    setState(() {});
    return ok;
  }


final TextStyle checkboxTextStyle = const TextStyle(
  fontSize: 13, // نفس حجم التطبيق
  color: Color.fromARGB(255, 6, 61, 65), // نفس mainColor
  fontWeight: FontWeight.w400,
);


  Future<void> _confirmPayment() async {
    if (!_validate()) return;

    setState(() => _isPaying = true);

    User? currentUser = await Session.getUser();

    if (currentUser == null || !currentUser.isClient) {
      setState(() => _isPaying = false);
      _showError("المستخدم غير مسجل");
      return;
    }

    final url =
        Uri.parse('http://10.0.2.2:8888/mujeer_api/confirm_payment.php');

    try {
      final response = await http.post(url, body: {
        'lawyer_id': widget.lawyerId.toString(),
        'client_id': currentUser.id.toString(),
        'timeslot_id': widget.timeslotId.toString(),
        'price': widget.price.toString(),
        'details': widget.caseDetails,
        'file_name': widget.attachedFileName ?? '',
          'request_type': widget.requestType.name,  
      });

      setState(() => _isPaying = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'تم حجز الموعد بنجاح',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (route) => false);
                        },
                        child: const Icon(Icons.close,
                            size: 22, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          _showError(data['message'] ?? 'خطأ أثناء الدفع');
        }
      } else {
        _showError('خطأ في الاتصال بالخادم');
      }
    } catch (e) {
      setState(() => _isPaying = false);
      _showError('خطأ في الاتصال: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
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
              // ===== Header =====
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
                      icon: Icon(
                        Icons.close,
                        color: mainColor,
                      ),
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
                      setState(() => agreeTerms = true);
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


  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFab(BuildContext context) => Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 61, 65),
              Color.fromARGB(255, 8, 65, 69)
            ],
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/plus'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات البطاقة',
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 61, 65),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('رقم البطاقة'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(
                          '1234 1234 1234 1234',
                          suffixIcon: const Icon(Icons.credit_card),
                        ).copyWith(errorText: _cardError),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CVV'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration('123')
                                      .copyWith(errorText: _cvvError),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('تاريخ انتهاء الصلاحية'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _expiryController,
                                  textAlign: TextAlign.center,
                                  decoration: _fieldDecoration('MM/YY')
                                      .copyWith(errorText: _expiryError),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "المبلغ المستحق: ${widget.price.toStringAsFixed(2)} ر.س",
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    CheckboxListTile(
  dense: true, 
  value: agreeTerms,
  onChanged: (v) => setState(() => agreeTerms = v!),
  activeColor: mainColor,
  checkColor: Colors.white,
  contentPadding: EdgeInsets.zero,

  title: RichText(
    text: TextSpan(
      style: checkboxTextStyle, 
      children: [
        TextSpan(text: 'قرأت وفهمت '),

        TextSpan(
          text: 'الشروط والأحكام',
          style: checkboxTextStyle.copyWith(
            decoration: TextDecoration.underline, 
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = _showTermsPopup,
        ),

        TextSpan(text: ' وأوافق عليها'),
      ],
    ),
  ),
),


                    CheckboxListTile(
  value: agreeData,
  onChanged: (v) => setState(() => agreeData = v!),
  activeColor: mainColor,
  checkColor: Colors.white,
  contentPadding: EdgeInsets.zero,
  title: RichText(
    text: TextSpan(
      style: checkboxTextStyle,
      text: 'أقر بصحة البيانات والمستندات المقدمة.',
    ),
  ),
),

                    CheckboxListTile(
  value: agreeService,
  onChanged: (v) => setState(() => agreeService = v!),
  activeColor: mainColor,
  checkColor: Colors.white,
  contentPadding: EdgeInsets.zero,
  title: RichText(
    text: TextSpan(
      style: checkboxTextStyle,
      text: 'أفهم أن الخدمة استشارية ولا تضمن نتيجة معينة.',
    ),
  ),
),

                    

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed:
                              (_isPaying || !allAgreed) ? null : _confirmPayment,
                          child: _isPaying
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'الدفع وتأكيد الموعد',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNav(currentRoute: "/payment"),
    );
  }
}
