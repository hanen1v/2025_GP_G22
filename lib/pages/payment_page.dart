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
  final String? attachedFileName;

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
  final TextEditingController _expiryController = TextEditingController();
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
    }

    setState(() {});
    return ok;
  }

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
        //Uri.parse('http://10.0.2.2:8888/mujeer_api/confirm_payment.php');
        Uri.parse('http://10.71.214.246:8888/mujeer_api/confirm_payment.php');

    try {
      final response = await http.post(url, body: {
        'lawyer_id': widget.lawyerId.toString(),
        'client_id': currentUser.id.toString(),
        'timeslot_id': widget.timeslotId.toString(),
        'price': widget.price.toString(),
        'details': widget.caseDetails,
        'file_name': widget.attachedFileName ?? '',
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

                      const SizedBox(height: 40),

                      // ⬇⬇⬇ هنا التعديل الوحيد — الزر داخل الكونتينر ⬇⬇⬇
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
                          onPressed: _isPaying ? null : _confirmPayment,
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

      bottomNavigationBar: const AppBottomNav(currentRoute: "/payment"),
    );
  }
}
