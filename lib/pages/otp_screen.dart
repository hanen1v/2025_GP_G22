import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reset_password_page.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isPasswordReset;
  final String username;
  final String? registrationType;
  

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    this.isPasswordReset = false, 
    this.username = '',
    this.registrationType,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  String _verificationId = '';
  int? _resendToken;
  bool _isLoading = false;
  @override
void initState() {
  super.initState();
  _sendOTP();// Automatically send OTP when screen loads
}

  /// Initiates OTP sending process (wrapper for _sendOTPRequest)
  Future<void> _sendOTP() async => _sendOTPRequest();
  /// Handles OTP resend functionality
  Future<void> _resendOTP() async => _sendOTPRequest(isResend: true);
/// Core function to send OTP via Firebase Authentication
  /// Handles both initial send and resend scenarios
  Future<void> _sendOTPRequest({bool isResend = false}) async {

    setState(() => _isLoading = true);

    try {
      print(' ${isResend ? 'إعادة إرسال' : 'إرسال'} الرمز إلى: ${widget.phoneNumber}');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: isResend ? _resendToken : null,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (credential) async {
          await _verifyWithCredential(credential);
        },
        verificationFailed: (error) {
          setState(() => _isLoading = false);
          _showError('فشل الإرسال: ${error.message}');
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _showSuccess('تم إرسال رمز التحقق!');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الإرسال: $e');
    }
  }
/// Verifies OTP using Firebase credential
  /// Signs in with credential then immediately signs out for security
  Future<void> _verifyWithCredential(PhoneAuthCredential credential) async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await FirebaseAuth.instance.signOut(); // Security measure - sign out immediately
        setState(() => _isLoading = false);
        _showSuccess('تم التحقق بنجاح!');
         _handleVerificationSuccess();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('فشل التحقق: $e');
    }
  }
  /// Routes user to appropriate screen based on verification context
  /// Handles password reset, registration, and general verification flows
  void _handleVerificationSuccess() {
  if (widget.isPasswordReset) {
    // Navigate to password reset page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(username: widget.username),
      ),
    );
  } else if (widget.registrationType != null) {
    _handleRegistrationSuccess();
  } else {
    Navigator.pop(context, true);
  }
}
/// Handles post-registration navigation based on user type
void _handleRegistrationSuccess() {
  Navigator.pop(context, true);
    Future.delayed(Duration.zero, () {
    switch (widget.registrationType) {
      case 'client':
        Navigator.pushNamed(context, '/home');
        break;
      case 'lawyer':
        Navigator.pushNamed(context, '/lawyer/more');
        break;
    }
  });
}
/// Validates and verifies manually entered OTP code
  /// Creates credential from user input and verifies with Firebase
  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showError('يرجى إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      await _verifyWithCredential(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }
  }
  /// Displays error messages to the user
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
      ),
    );
  }
  /// Displays success messages to the user
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'التحقق من رقم الجوال',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildVerificationCard(),
                  const SizedBox(height: 32),
                  _buildVerifyButton(),
                  const SizedBox(height: 20),
                  _buildResendButton(),
                ],
              ),
            ),
    );
  }
  /// Builds the main verification card with instructions and OTP input
  Widget _buildVerificationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التحقق من رقم الجوال',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B5345),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تم إرسال رمز التحقق إلى: ${widget.phoneNumber}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'رمز التحقق (6 أرقام)',
                labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0B5345)),
                ),
                hintText: '123456',
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// Builds the primary verification button
  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5345),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'تحقق',
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
  /// Builds the resend OTP button
  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _resendOTP,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0B5345),
          side: const BorderSide(color: Color(0xFF0B5345)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'إعادة إرسال الرمز',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
