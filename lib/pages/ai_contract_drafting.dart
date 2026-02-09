import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiContractDrafting extends StatefulWidget {
  const AiContractDrafting({super.key});

  @override
  State<AiContractDrafting> createState() => _AiContractDraftingState();
}

class _AiContractDraftingState extends State<AiContractDrafting> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  // رسائل الشات
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      role: _Role.assistant,
      text:
          "هلا 👋 أنا مساعد صياغة العقود.\nقولي: وش نوع العقد؟ (خدمات / عمل / إيجار / شراكة...)",
    ),
  ];

  // ألوان تناسب تطبيقك
  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _primary = Color(0xFF0B5345); // أخضر غامق قريب من سناكبارك
  static const Color _bubbleBot = Color(0xFFE9F2F0); // فاتح مائل للأخضر
  static const Color _bubbleUser = Color(0xFF0B5345);
  static const Color _textOnUser = Colors.white;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse("http://10.71.214.246:8888/mujeer_api/ai_contract.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text}),
      );

      // لو السيرفر رجّع خطأ
      if (res.statusCode < 200 || res.statusCode >= 300) {
        setState(() {
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text:
                "صار خطأ في الاتصال (${res.statusCode}).\n${res.body.isNotEmpty ? res.body : ""}",
          ));
          _isSending = false;
        });
        _scrollToBottom();
        return;
      }

      final data = jsonDecode(res.body);
      final reply = (data["reply"] ?? "").toString().trim();

      setState(() {
        _messages.add(_ChatMessage(
          role: _Role.assistant,
          text: reply.isEmpty ? "ما وصلتني إجابة واضحة، جرّبي مرة ثانية." : reply,
        ));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: _Role.assistant,
          text: "صار خطأ غير متوقع.\n$e",
        ));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          "مساعد صياغة العقود",
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                // عنصر "يكتب..."
                if (_isSending && index == _messages.length) {
                  return _TypingBubble(
                    bubbleColor: _bubbleBot,
                    textColor: Colors.black87,
                  );
                }

                final m = _messages[index];
                final isUser = m.role == _Role.user;

                return _ChatBubble(
                  text: m.text,
                  isUser: isUser,
                  maxWidth: w * 0.78,
                  bubbleColor: isUser ? _bubbleUser : _bubbleBot,
                  textColor: isUser ? _textOnUser : Colors.black87,
                );
              },
            ),
          ),

          // صندوق الإدخال
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: TextField(
                        controller: _controller,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: "اكتب رسالتك…",
                          hintStyle: TextStyle(fontFamily: 'Tajawal'),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        elevation: 2,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatMessage {
  final _Role role;
  final String text;

  const _ChatMessage({required this.role, required this.text});
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double maxWidth;
  final Color bubbleColor;
  final Color textColor;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.maxWidth,
    required this.bubbleColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            height: 1.35,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final Color bubbleColor;
  final Color textColor;

  const _TypingBubble({required this.bubbleColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          "يكتب الآن…",
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: textColor,
          ),
        ),
      ),
    );
  }
}
