import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_bottom_nav.dart';
import '../services/session.dart';
import '../models/user.dart';


class PaymentPage extends StatefulWidget {
  final int lawyerId;
  final int timeslotId;
  final double price;
  final String caseDetails;
  final String? attachedFileName; // اختياري

  const PaymentPage({
    super.key,
    required this.lawyerId,
    required this.timeslotId,
    required this.price,
    required this.caseDetails,
    this.attachedFileName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController(); // MM/YY
  final TextEditingController _cvvController = TextEditingController();

  String? _cardError;
  String? _expiryError;
  String? _cvvError;
  bool _isPaying = false;

  final Color mainColor = const Color.fromARGB(255, 6, 61, 65);

  bool _validate() {
    bool ok = true;
    _cardError = null;
    _expiryError = null;
    _cvvError = null;

    // رقم البطاقة
    String number = _cardNumberController.text.replaceAll(' ', '');
    if (number.length != 16 || int.tryParse(number) == null) {
      _cardError = 'أدخل رقم بطاقة صحيح مكون من 16 رقم';
      ok = false;
    }

    // CVV
    String cvv = _cvvController.text.trim();
    if (cvv.length != 3 || int.tryParse(cvv) == null) {
      _cvvError = 'أدخل CVV صحيح من 3 أرقام';
      ok = false;
    }

    // تاريخ الانتهاء MM/YY ويكون في المستقبل
    String expiry = _expiryController.text.trim();
    RegExp re = RegExp(r'^\d{2}/\d{2}$');
    if (!re.hasMatch(expiry)) {
      _expiryError = 'الصيغة يجب أن تكون MM/YY';
      ok = false;
    } else {
      int month = int.parse(expiry.split('/')[0]);
      int year = int.parse(expiry.split('/')[1]) + 2000; // 25 -> 2025 مثلاً
      if (month < 1 || month > 12) {
        _expiryError = 'شهر غير صالح';
        ok = false;
      } else {
        final now = DateTime.now();
        final lastDay =
            DateTime(year, month + 1, 0); // آخر يوم في شهر الانتهاء
        if (lastDay.isBefore(DateTime(now.year, now.month, now.day))) {
          _expiryError = 'انتهت صلاحية البطاقة';
          ok = false;
        }
      }
    }

    setState(() {});
    return ok;
  }

  Future<void> _confirmPayment() async {
    if (!_validate()) return;

    setState(() => _isPaying = true);

  
    // const int fakeClientId = 1;

  
User? currentUser = await Session.getUser();

if (currentUser == null || !currentUser.isClient) {
  setState(() => _isPaying = false);
  _showError("حدث خطأ: المستخدم غير مسجل ");
  return;
}

final int realClientId = currentUser.id;


    final url =
        Uri.parse('http://10.0.2.2:8888/mujeer_api/confirm_payment.php');

    try {
      final response = await http.post(url, body: {
        'lawyer_id': widget.lawyerId.toString(),
        'client_id': realClientId.toString(),
        'timeslot_id': widget.timeslotId.toString(),
        'price': widget.price.toString(),
        'details': widget.caseDetails,
        'file_name': widget.attachedFileName ?? '',
      });

      setState(() => _isPaying = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // تم الحجز بنجاح
          showDialog(
  context: context,
  barrierDismissible: false, // يمنع الإغلاق بالضغط خارج البوب-أب
  builder: (context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),

                // النص
                Text(
                  'تم حجز الموعد بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 6, 61, 65),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // زر الإغلاق (X)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // اغلاق البوب-أب
                Navigator.popUntil(context, (route) => route.isFirst); // الرجوع للهوم بيج
              },
              child: const Icon(
                Icons.close,
                size: 22,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  },
);

        } else {
          _showError(data['message'] ?? 'حدث خطأ أثناء الدفع');
        }
      } else {
        _showError('خطأ في الاتصال بالخادم');
      }
    } catch (e) {
      setState(() => _isPaying = false);
      _showError('حدث استثناء في الاتصال: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mainColor, width: 1.8),
      ),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // سهم الرجوع
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // الكونتينر الأبيض
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان
                      const Text(
                        'معلومات البطاقة',
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 61, 65),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // رقم البطاقة
                      const Text(
                        'رقم البطاقة',
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(
                          '1234 1234 1234 1234',
                          suffixIcon: Icon(Icons.credit_card, color: mainColor),
                        ).copyWith(errorText: _cardError),
                      ),

                      const SizedBox(height: 24),

                      // الصف: تاريخ الانتهاء + CVV
                      Row(
                        children: [
                          // CVV يسار
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.help_outline, size: 18),
                                    SizedBox(width: 4),
                                    Text('CVV'),
                                  ],
                                ),
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
                          // تاريخ الانتهاء يمين
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('تاريخ انتهاء الصلاحية'),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
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

                      // عرض السعر
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "المبلغ المستحق: ${widget.price.toStringAsFixed(2)} ر.س",
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // زر الدفع
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isPaying ? null : _confirmPayment,
                  child: _isPaying
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'الدفع وتأكيد الموعد',
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

      // نفس الناف بار
      bottomNavigationBar:
          const AppBottomNav(currentRoute: '/payment'),
    );
  }
}
