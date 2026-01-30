import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? senderID; 
  String? receiverID; 
  int? appointmentID;
  final messageController = TextEditingController(); 
  String? appointmentDate;
  String? appointmentTime;
  String? lawyerNumber;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // valueNotifier to update only the timer
  final ValueNotifier<Duration?> _remainingTimeNotifier = ValueNotifier<Duration?>(null);
  Timer? _appointmentTimer;
  Timer? _countdownTimer;
  bool _isAppointmentActive = false;
  bool _isAppointmentFinished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getArguments();
  }

  @override
  void dispose() {
    _appointmentTimer?.cancel();
    _countdownTimer?.cancel();
    _remainingTimeNotifier.dispose();
    messageController.dispose();
    super.dispose();
  }

  void _getArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map) {
      setState(() {
        senderID = args['senderID'];
        receiverID = args['receiverID'];
        appointmentID = args['appointmentID'];
        appointmentDate = args['appointmentDate']?.toString().replaceAll(';', '');
        appointmentTime = args['appointmentTime']?.toString().replaceAll(';', '');
        lawyerNumber = args['lawyerNumber'];
      });
      
      print(' Data received: $appointmentID');
      _startAppointmentCheck();
    }
  }

  void _startAppointmentCheck() {
    _appointmentTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkAppointmentTime();
    });
    _checkAppointmentTime();
  }

  void _checkAppointmentTime() {
    if (_isAppointmentFinished) return;

    final appointmentStart = _parseDateTime();
    if (appointmentStart == null) return;

    final now = DateTime.now();
    final diff = now.difference(appointmentStart).inMinutes;

    if (diff >= 0 && diff < 15) {
      if (!_isAppointmentActive) {
        setState(() => _isAppointmentActive = true);
        _startCountdown(appointmentStart);
      }
    } else if (diff >= 15) {
      _finishAppointment();
    }
  }

  void _startCountdown(DateTime start) {
    _countdownTimer?.cancel();
    final end = start.add(Duration(minutes: 15));

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = end.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        _finishAppointment();
      } else {
        _remainingTimeNotifier.value = remaining;
      }
    });
  }

  void _finishAppointment() {
    if (_isAppointmentFinished) return;
    _appointmentTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isAppointmentFinished = true;
      _isAppointmentActive = false;
    });
    _showEndDialog();
  }

  DateTime? _parseDateTime() {
    try {
      if (appointmentDate == null || appointmentTime == null) return null;
      return DateTime.parse('${appointmentDate!.trim()} ${appointmentTime!.trim()}');
    } catch (e) {
      return null;
    }
  }


void _showEndDialog() {
  bool isLawyer = senderID?.startsWith('L') ?? false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انتهى الوقت'),
        // الرسالة حسب محامي او عميل
        content: Text(isLawyer 
          ? 'انتهت جلسة الاستشارة، شكرا لعملك.' 
          : 'انتهت جلسة الاستشارة، الرجاء تقييم الموعد بخانة الطلبات المنتهية'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child: const Text(
              'انهاء',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 44, 36), 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void sendMessage() {
    final message = messageController.text.trim();
    if (message.isNotEmpty && _isAppointmentActive && !_isAppointmentFinished) {
      _firestore.collection('chats').add({
        'senderID': senderID, 
        'receiverID': receiverID, 
        'appointmentID': appointmentID,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      messageController.clear();
    } else if (!_isAppointmentActive && !_isAppointmentFinished) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الموعد لم يبدأ بعد')));
    }
  }

  Stream<QuerySnapshot> getChatMessages() {
    return _firestore
        .collection('chats')
        .where('appointmentID', isEqualTo: appointmentID)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    if (senderID == null || receiverID == null || appointmentID == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 9, 44, 36),
          title: const Text('تحميل...', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    Future<void> _makePhoneCall(String lawyerNumber) async {
    final Uri launchUri = Uri(
    scheme: 'tel',
    path: lawyerNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر إجراء الاتصال بهذا الرقم')),
      );
     }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 9, 44, 36),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
       if (lawyerNumber != null && senderID != null && senderID!.startsWith('C'))
        IconButton(
        icon: const Icon(Icons.phone, color: Colors.white),
        tooltip: 'اتصال بالمحامي',
        onPressed: () => _makePhoneCall(lawyerNumber!),
      ),
       ],
        title: Column(
          children: [
            const Text('محادثة نشطة', style: TextStyle(color: Colors.white, fontSize: 18)),
            // timer here
            ValueListenableBuilder<Duration?>(
              valueListenable: _remainingTimeNotifier,
              builder: (context, remaining, _) {
                if (_isAppointmentFinished) return Text('انتهت المحادثة', style: TextStyle(color: Colors.red, fontSize: 12));
                if (!_isAppointmentActive) return Text('بانتظار الموعد', style: TextStyle(color: Colors.white70, fontSize: 12));
                if (remaining == null) return const SizedBox();
                
                String timeStr = "${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}";
                return Text('متبقي: $timeStr', style: TextStyle(color: Colors.yellow, fontSize: 12));
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getChatMessages(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true, 
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index].data() as Map<String, dynamic>;
                      final isMe = messageData['senderID'] == senderID; 
                      return _buildMessageBubble(messageData['message'], isMe);
                    },
                  );
                },
              ),
            ),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color.fromARGB(255, 9, 44, 36) : Colors.grey[300], 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              enabled: _isAppointmentActive && !_isAppointmentFinished,
              decoration: InputDecoration(
                labelText: _isAppointmentFinished ? 'انتهت الجلسة' : 'أدخل رسالتك',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: (_isAppointmentActive && !_isAppointmentFinished) 
                  ? const Color.fromARGB(255, 9, 44, 36) 
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}