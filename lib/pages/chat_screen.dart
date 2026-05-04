import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'call_manager.dart';

// تأكدي من استيراد كلاس CallManager
// import 'call_manager.dart'; 

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? senderID; 
  String? receiverID; 
  int? appointmentID;
  String? appointmentDate;
  String? appointmentTime;
  final messageController = TextEditingController(); 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CallManager _callManager = CallManager();
  final String tempToken = "007eJxTYNCrXLGXKd2Rn2kSw7tXDNwSc9YduFwyMShTbGbqPBFNm78KDAZpJsmmBilpJgbmJiZpqalJaSmpKUYpxonGRgYWyWaGEWe/ZTYEMjLEsl5gZmSAQBCfmyG3NCs1tSg+OTEnh4EBAHkHII4="; 
  
  bool _isMuted = false;
  bool _isSpeakerOn = false; 
  bool _isRemoteUserJoined = false;
  
  // جعل الواجهة مصغرة تلقائياً عند فتح الصفحة والمكالمة قائمة
  bool _isMinimized = true; 

  final ValueNotifier<Duration?> _remainingTimeNotifier = ValueNotifier<Duration?>(null);
  Timer? _appointmentTimer;
  Timer? _countdownTimer;
  bool _isAppointmentActive = false;
  bool _isAppointmentFinished = false;

  @override
  void initState() {
    super.initState();
    _setupAgoraEvents();
  }

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

  void _setupAgoraEvents() {
    _callManager.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) setState(() => _isRemoteUserJoined = true);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) setState(() => _isRemoteUserJoined = false);
        },
      ),
    );
  }

  // --- رفع وفتح الملفات ---
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var file = result.files.single;
      var request = http.MultipartRequest('POST', Uri.parse('http://10.164.73.246:8888/mujeer_api/upload_file.php'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        if (data['success']) {
          _firestore.collection('chats').add({
            'senderID': senderID, 'receiverID': receiverID, 'appointmentID': appointmentID,
            'fileUrl': data['file_url'], 'fileName': file.name, 'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  Future<void> _openDownloadedFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(file.path);
      }
    } catch (e) { debugPrint("Error opening file: $e"); }
  }

  Future<void> _toggleCall() async {
    if (_isAppointmentFinished) return;
    if (_callManager.isJoined) {
      await _callManager.leaveChannel();
      if (mounted) setState(() {});
    } else {
      if (!_isAppointmentActive) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الموعد لم يبدأ بعد')));
        return;
      }
      _firestore.collection('chats').add({
        'senderID': senderID, 'receiverID': receiverID, 'appointmentID': appointmentID,
        'message': 'CALL_SIGNAL_START', 'timestamp': FieldValue.serverTimestamp(),
      });
      await _callManager.joinChannel(tempToken, "mujeer_call");
      // عند بدء المكالمة لأول مرة نفتحها كاملة
      if (mounted) setState(() => _isMinimized = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (senderID == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: true, 
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _buildMyCustomAppBar(), 
                Expanded(child: _buildMessagesList()),
                _buildInputArea(),
              ],
            ),
            // واجهة المكالمة الكاملة
            if (_callManager.isJoined && !_isMinimized) Positioned.fill(child: _buildFullCallOverlay()),
            // شريط المكالمة المصغر (يظهر إذا كانت المكالمة قائمة والواجهة مصغرة)
            if (_callManager.isJoined && _isMinimized) _buildMinimizedBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCustomAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 10),
      color: const Color.fromARGB(255, 9, 44, 36),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('محادثة نشطة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ValueListenableBuilder<Duration?>(
                  valueListenable: _remainingTimeNotifier,
                  builder: (context, remaining, _) {
                    if (_isAppointmentFinished) return const Text('انتهت المحادثة', style: TextStyle(color: Colors.red, fontSize: 12));
                    if (!_isAppointmentActive) return const Text('بانتظار الموعد', style: TextStyle(color: Colors.white70, fontSize: 12));
                    String timeStr = remaining != null ? "${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}" : "00:00";
                    return Text('متبقي: $timeStr', style: const TextStyle(color: Colors.yellow, fontSize: 12));
                  },
                ),
              ],
            ),
          ),
          if (!_callManager.isJoined)
            IconButton(icon: const Icon(Icons.phone, color: Colors.white), onPressed: _toggleCall)
          else
            // زر التكبير يظهر في الأببار إذا كانت المكالمة مصغرة
            IconButton(icon: const Icon(Icons.open_in_full, color: Colors.white), onPressed: () => setState(() => _isMinimized = false)),
        ],
      ),
    );
  }

  Widget _buildFullCallOverlay() {
    return Container(
      color: const Color.fromARGB(255, 9, 44, 36),
      child: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.close_fullscreen, color: Colors.white, size: 30), onPressed: () => setState(() => _isMinimized = true))),
            const Spacer(),
            Text(
              _isRemoteUserJoined ? "متصل الآن" : "جاري الاتصال...", 
              style: TextStyle(
                color: _isRemoteUserJoined ? Colors.greenAccent : Colors.white70, 
                fontSize: 26, 
                fontWeight: FontWeight.bold
              )
            ),
            const Spacer(),
            _buildCallControls(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizedBar() {
    return Positioned(
      top: 100, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 20, 20, 20), 
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
          ),
          child: Row(
            children: [
              const Icon(Icons.call, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 15),
              const Expanded(child: Text("المكالمة نشطة", style: TextStyle(color: Colors.white, fontSize: 13))),
              IconButton(icon: const Icon(Icons.call_end, color: Colors.redAccent, size: 22), onPressed: _toggleCall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // زر الميوت - يتغير لونه للبرتقالي عند الضغط
        _roundBtn(
          icon: _isMuted ? Icons.mic_off : Icons.mic, 
          label: "كتم", 
          color: _isMuted ? Colors.orange : Colors.white10, 
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            _callManager.engine?.muteLocalAudioStream(_isMuted);
          }
        ),
        // زر السبيكر - يتغير لونه للأزرق عند الضغط
        _roundBtn(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down, 
          label: "سبيكر", 
          color: _isSpeakerOn ? Colors.blueAccent : Colors.white10, 
          onTap: () {
            setState(() => _isSpeakerOn = !_isSpeakerOn);
            _callManager.engine?.setEnableSpeakerphone(_isSpeakerOn);
          }
        ),
        _roundBtn(icon: Icons.call_end, label: "إنهاء", color: Colors.redAccent, onTap: _toggleCall),
      ],
    );
  }

  Widget _roundBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap, 
          child: Container(
            padding: const EdgeInsets.all(20), 
            decoration: BoxDecoration(shape: BoxShape.circle, color: color), 
            child: Icon(icon, color: Colors.white, size: 30)
          )
        ), 
        const SizedBox(height: 8), 
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))
      ]
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('chats').where('appointmentID', isEqualTo: appointmentID).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final msg = doc.data() as Map<String, dynamic>;
            bool isMe = msg['senderID'] == senderID;
            if (msg['message'] == 'CALL_SIGNAL_START') {
              if (isMe) return const SizedBox();
              return _incomingCallWidget(doc.id);
            }
            if (msg['fileUrl'] != null) return _fileBubble(msg['fileName'] ?? 'ملف', msg['fileUrl'], isMe);
            return _bubble(msg['message'] ?? "", isMe);
          },
        );
      },
    );
  }

  Widget _fileBubble(String name, String url, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _openDownloadedFile(url, name),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isMe ? const Color.fromARGB(255, 9, 44, 36) : Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.attach_file, color: Colors.blue), const SizedBox(width: 8), Flexible(child: Text(name, style: TextStyle(color: isMe ? Colors.white : Colors.black, decoration: TextDecoration.underline)))]),
        ),
      ),
    );
  }

  Widget _bubble(String m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isMe ? const Color.fromARGB(255, 9, 44, 36) : Colors.grey[300], borderRadius: BorderRadius.circular(12)),
        child: Text(m, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file, color: Color.fromARGB(255, 9, 44, 36)), onPressed: _pickAndUploadFile),
          Expanded(child: TextField(controller: messageController, decoration: InputDecoration(hintText: 'أدخل رسالتك', border: const OutlineInputBorder()))),
          IconButton(icon: const Icon(Icons.send, color: Color.fromARGB(255, 9, 44, 36)), onPressed: () {
            if (messageController.text.trim().isNotEmpty) {
              _firestore.collection('chats').add({'senderID': senderID, 'receiverID': receiverID, 'appointmentID': appointmentID, 'message': messageController.text.trim(), 'timestamp': FieldValue.serverTimestamp()});
              messageController.clear();
            }
          }),
        ],
      ),
    );
  }

  Widget _incomingCallWidget(String docId) {
    return Container(
      margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green)),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk, color: Colors.green),
          const SizedBox(width: 10),
          const Expanded(child: Text("مكالمة واردة...")),
          TextButton(onPressed: () => _firestore.collection('chats').doc(docId).delete(), child: const Text("رفض", style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () { _firestore.collection('chats').doc(docId).delete(); _toggleCall(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("انضمام")),
        ],
      ),
    );
  }

  void _getArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      setState(() {
        senderID = args['senderID']; receiverID = args['receiverID']; appointmentID = args['appointmentID'];
        appointmentDate = args['appointmentDate']; appointmentTime = args['appointmentTime'];
      });
      _startAppointmentCheck();
    }
  }

  void _startAppointmentCheck() {
    _appointmentTimer = Timer.periodic(const Duration(seconds: 10), (t) => _checkAppointmentTime());
    _checkAppointmentTime();
  }

  void _checkAppointmentTime() {
    if (_isAppointmentFinished) return;
    final start = _parseDateTime(); if (start == null) return;
    final diff = DateTime.now().difference(start).inMinutes;
    if (diff >= 15) {
      _finishAppointment();
    } else if (DateTime.now().isAfter(start)) { 
      setState(() => _isAppointmentActive = true); 
      _startCountdown(start); 
    }
  }

  void _startCountdown(DateTime start) {
    _countdownTimer?.cancel();
    final end = start.add(const Duration(minutes: 15));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final rem = end.difference(DateTime.now());
      if (rem.isNegative) _finishAppointment(); else _remainingTimeNotifier.value = rem;
    });
  }

  void _finishAppointment() {
    if (_isAppointmentFinished) return;
    _callManager.leaveChannel();
    _appointmentTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() { _isAppointmentFinished = true; _isAppointmentActive = false; _isMinimized = false; });
    _showEndDialog();
  }

  void _showEndDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('انتهى الوقت'),
        content: const Text('انتهت جلسة الاستشارة.'),
        actions: [TextButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false), child: const Text("إنهاء"))],
      ),
    );
  }

  DateTime? _parseDateTime() {
    try { return DateTime.parse('${appointmentDate!.trim()} ${appointmentTime!.trim()}'); } catch (e) { return null; }
  }
}
