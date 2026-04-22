import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إعدادات Agora
  final String appId = "appkey"; 
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false; 
  bool _isRemoteUserJoined = false;
  bool _isMinimized = false;

  // منطق الوقت والتنبيهات
  final ValueNotifier<Duration?> _remainingTimeNotifier = ValueNotifier<Duration?>(null);
  Timer? _appointmentTimer;
  Timer? _countdownTimer;
  bool _isAppointmentActive = false;
  bool _isAppointmentFinished = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getArguments();
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _appointmentTimer?.cancel();
    _countdownTimer?.cancel();
    _remainingTimeNotifier.dispose();
    messageController.dispose();
    super.dispose();
  }

  // --- منطق Agora ---
  Future<void> _initAgora() async {
    await Permission.microphone.request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId, channelProfile: ChannelProfileType.channelProfileCommunication));
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) => setState(() => _isJoined = true),
        onLeaveChannel: (RtcConnection connection, RtcStats stats) => setState(() {
          _isJoined = false;
          _isRemoteUserJoined = false;
          _isMinimized = false;
        }),
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) => setState(() => _isRemoteUserJoined = true),
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) => setState(() => _isRemoteUserJoined = false),
      ),
    );
    await _engine!.enableAudio();
  }

  Future<void> _toggleCall() async {
    if (_engine == null || _isAppointmentFinished) return;
    if (_isJoined) {
      await _engine!.leaveChannel();
    } else {
      if (!_isAppointmentActive) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الموعد لم يبدأ بعد')));
        return;
      }
      setState(() => _isJoined = true);
      _firestore.collection('chats').add({
        'senderID': senderID, 'receiverID': receiverID, 'appointmentID': appointmentID,
        'message': 'CALL_SIGNAL_START', 'timestamp': FieldValue.serverTimestamp(),
      });
      await _engine!.joinChannel(token: '', channelId: "call_$appointmentID", uid: 0, 
          options: const ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster, channelProfile: ChannelProfileType.channelProfileCommunication));
    }
  }

  // --- تحذير الخروج ---
  Future<bool> _showExitWarning() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء المكالمة؟', textAlign: TextAlign.right),
        content: const Text('مغادرة الصفحة ستؤدي إلى قطع المكالمة الجارية.', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('بقاء', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('إنهاء ومغادرة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (senderID == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: !_isJoined,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitWarning();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
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
            if (_isJoined && !_isMinimized) Positioned.fill(child: _buildFullCallOverlay()),
            if (_isJoined && _isMinimized) _buildMinimizedBar(),
          ],
        ),
      ),
    );
  }

  // --- الأببار المخصص مع التايمر الذكي ---
  Widget _buildMyCustomAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 10),
      color: const Color.fromARGB(255, 9, 44, 36),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () async {
              if (_isJoined) {
                if (await _showExitWarning()) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            }
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('محادثة نشطة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                // التايمر يظهر في الشات العادي أو المكالمة المصغرة
                if (!_isJoined || _isMinimized)
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
          if (!_isJoined)
            IconButton(icon: const Icon(Icons.phone, color: Colors.white), onPressed: _toggleCall)
          else
            const SizedBox(width: 48), 
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
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                padding: const EdgeInsets.all(20),
                icon: const Icon(Icons.close_fullscreen, color: Colors.white, size: 30),
                onPressed: () => setState(() => _isMinimized = true),
              ),
            ),
            const Spacer(),
            Text(_isRemoteUserJoined ? "متصل الآن" : "جاري الاتصال...", 
                style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
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
      top: 100, 
      left: 15, right: 15,
      child: GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
          child: Row(
            children: [
              const Icon(Icons.call, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 15),
              const Expanded(child: Text("المكالمة نشطة.. اضغط للفتح", style: TextStyle(color: Colors.white, fontSize: 13))),
              IconButton(icon: const Icon(Icons.call_end, color: Colors.redAccent, size: 20), onPressed: _toggleCall),
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
        _roundBtn(icon: _isMuted ? Icons.mic_off : Icons.mic, label: "كتم", color: _isMuted ? Colors.orange : Colors.white12, onTap: () {
          setState(() => _isMuted = !_isMuted);
          _engine!.muteLocalAudioStream(_isMuted);
        }),
        _roundBtn(icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down, label: "سبيكر", color: _isSpeakerOn ? Colors.blue : Colors.white12, onTap: () {
          setState(() => _isSpeakerOn = !_isSpeakerOn);
          _engine!.setEnableSpeakerphone(_isSpeakerOn);
        }),
        _roundBtn(icon: Icons.call_end, label: "إنهاء", color: Colors.redAccent, onTap: _toggleCall),
      ],
    );
  }

  Widget _roundBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(children: [GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(shape: BoxShape.circle, color: color), child: Icon(icon, color: Colors.white, size: 28))), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))]);
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
            return _bubble(msg['message'], isMe);
          },
        );
      },
    );
  }

  Widget _incomingCallWidget(String docId) {
    return Container(
      margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green)),
      child: Column(
        children: [
          Row(children: [const Icon(Icons.phone_in_talk, color: Colors.green), const SizedBox(width: 10), const Text("مكالمة واردة...", style: TextStyle(fontWeight: FontWeight.bold))]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => _firestore.collection('chats').doc(docId).delete(), child: const Text("رفض", style: TextStyle(color: Colors.red))),
            ElevatedButton(onPressed: _toggleCall, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("انضمام", style: TextStyle(color: Colors.white))),
          ])
        ],
      ),
    );
  }

  Widget _bubble(String m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
    _engine?.leaveChannel();
    _appointmentTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() { 
      _isAppointmentFinished = true; _isAppointmentActive = false; 
      _isJoined = false; _isMinimized = false;
    });
    _showEndDialog();
  }

  void _showEndDialog() {
    bool isLawyer = senderID?.startsWith('L') ?? false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('انتهى الوقت'),
        content: Text(isLawyer ? 'انتهت جلسة الاستشارة، شكراً لعملك.' : 'انتهت جلسة الاستشارة، الرجاء تقييم الموعد بخانة الطلبات المنتهية'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(c);
            Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
          }, child: const Text("انهاء"))
        ],
      ),
    );
  }

  DateTime? _parseDateTime() {
    try { return DateTime.parse('${appointmentDate!.trim()} ${appointmentTime!.trim()}'); } catch (e) { return null; }
  }
}
