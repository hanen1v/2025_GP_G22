import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CallManager {
  // تصميم السنغلتون (نسخة واحدة فقط للتطبيق كامل)
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  RtcEngine? engine;
  bool isJoined = false;

  // تهيئة المحرك لمرة واحدة فقط عند تشغيل التطبيق
  Future<void> initAgora(String appId) async {
    if (engine != null) return; 

    await Permission.microphone.request();
    engine = createAgoraRtcEngine();
    await engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    
    // فعلي الصوت في الخلفية (مهم جداً)
    await engine!.enableAudio();
  }

  Future<void> joinChannel(String token, String channelName) async {
    if (isJoined) return;
    await engine?.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    isJoined = true;
  }

  Future<void> leaveChannel() async {
    await engine?.leaveChannel();
    isJoined = false;
  }
}