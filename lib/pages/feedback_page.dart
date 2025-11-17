import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/session.dart';

class FeedbackPage extends StatefulWidget {
  static const route = '/feedback';
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();

  User? _user;
  bool _loadingUser = true;
  bool _submitting = false;

  int? _lawyerId;
  bool _gotArgs = false;

  int _rating = 0;

  static const String _phpPage = 'http://10.0.2.2:8888/mujeer_api/add_feedback.php';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gotArgs) return;
    _gotArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is int) {
      _lawyerId = args;
    } else if (args is Map) {
      _lawyerId = args['lawyerId'] ?? args['id'];
    }
  }

  Future<void> _loadUser() async {
    final u = await Session.getUser();
    if (!mounted) return;
    setState(() {
      _user = u;
      _loadingUser = false;
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loadingUser) return;

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول أولاً')),
      );
      return;
    }

    if (_lawyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: لا يوجد معرف المحامي')),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تقييم المحامي')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = {
        'client_id': _user!.id,
        'lawyer_id': _lawyerId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final res = await http.post(
        Uri.parse(_phpPage),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم إرسال تقييمك بنجاح')),
      );

    await Future.delayed(const Duration(milliseconds: 500));

   if (!mounted) return;
  Navigator.pushReplacementNamed(context, '/thankYouPage');

      } else {
        throw Exception(data['message'] ?? 'تعذر حفظ التقييم');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _buildStars() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final v = i + 1;
          final filled = v <= _rating;
          return IconButton(
            iconSize: 38,
            onPressed: () {
              setState(() => _rating = (_rating == v) ? 0 : v);
            },
            icon: Icon(
              filled ? Icons.star : Icons.star_border,
              color: filled ? Colors.amber : Colors.grey.shade400,
            ),
          );
        }),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 9, 44, 36),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'التقييم',
        style: TextStyle(color: Colors.white),
      ),
      centerTitle: true,
    ),

    body: SafeArea(
      child: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      const SizedBox(height: 16),

                      const Text(
                        'قيّم تجربتك',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      _buildStars(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('غير راضٍ للغاية'),
                            Text('راضٍ للغاية'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      Expanded(
                        child: TextFormField(
                          controller: _commentCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'شارك رأيك هنا..',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'الرجاء كتابة تعليق'
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: 150,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 9, 44, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'مشاركة',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );
}
}