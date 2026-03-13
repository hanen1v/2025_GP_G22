import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AiContractDrafting extends StatefulWidget {
  const AiContractDrafting({super.key});

  @override
  State<AiContractDrafting> createState() => _AiContractDraftingState();
}

class _AiContractDraftingState extends State<AiContractDrafting> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  final List<_ChatMessage> _messages = [];

  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _primary = Color(0xFF0B5345);
  static const Color _bubbleBot = Color(0xFFE9F2F0);
  static const Color _bubbleUser = Color(0xFF0B5345);
  static const Color _textOnUser = Colors.white;

  static const String _endpoint =
      "http://10.164.73.246:8888/mujeer_api/ai_contract.php";

  @override
  void initState() {
    super.initState();
    _startChat();
  }

  Future<void> _startChat() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"conversation": []}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        setState(() {
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text:
                "تعذر بدء المحادثة (${res.statusCode}).\n${res.body.isNotEmpty ? res.body : ""}",
          ));
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data is Map && data["type"] == "question") {
        final q = (data["question"] ?? "").toString().trim();

        final optsRaw = data["options"];
        final options = (optsRaw is List)
            ? optsRaw.map((e) {
                if (e is Map) {
                  return (e["label"] ?? "").toString();
                }
                return e.toString();
              }).where((e) => e.trim().isNotEmpty).toList()
            : null;

        setState(() {
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text: q.isEmpty ? "ما نوع العقد الذي ترغب بصياغته؟" : q,
            options: options,
          ));
        });
      } else {
        setState(() {
          _messages.add(const _ChatMessage(
            role: _Role.assistant,
            text: "تعذر فهم رد السيرفر عند بدء المحادثة.",
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: _Role.assistant,
          text: "تعذر بدء المحادثة الآن.\n$e",
        ));
      });
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    final conversation = _messages
        .where((m) => m.role == _Role.user)
        .map((m) => {
              "role": "user",
              "content": m.text,
            })
        .toList();

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"conversation": conversation}),
      );

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
      if (data is! Map) {
        setState(() {
          _messages.add(const _ChatMessage(
            role: _Role.assistant,
            text: "رد غير متوقع من السيرفر.",
          ));
          _isSending = false;
        });
        _scrollToBottom();
        return;
      }

      final type = (data["type"] ?? "").toString();

      if (type == "question") {
        final q = (data["question"] ?? "").toString().trim();

        final optsRaw = data["options"];
        final options = (optsRaw is List)
            ? optsRaw.map((e) {
                if (e is Map) {
                  return (e["label"] ?? "").toString();
                }
                return e.toString();
              }).where((e) => e.trim().isNotEmpty).toList()
            : null;

        setState(() {
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text: q.isEmpty ? "ممكن توضح أكثر؟" : q,
            options: options,
          ));
          _isSending = false;
        });
        _scrollToBottom();
        return;
      }

      if (type == "contract") {
        final contractText = (data["text"] ?? "").toString().trim();
        final pdfUrl = (data["pdf_url"] ?? "").toString().trim();

        setState(() {
          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text: "تم إنشاء العقد بنجاح.",
          ));

          _messages.add(_ChatMessage(
            role: _Role.assistant,
            text:
                "تنويه: هذه مسودة أولية للعقد وتحتاج إلى مراجعة من محامٍ مرخّص قبل الاعتماد أو التوقيع.",
          ));

          // if (contractText.isNotEmpty) {
          //   _messages.add(_ChatMessage(
          //     role: _Role.assistant,
          //     text: contractText,
          //     isContractPreview: true,
          //   ));
          // }

          if (pdfUrl.isNotEmpty) {
            _messages.add(_ChatMessage(
              role: _Role.assistant,
              text: "يمكنك تحميل نسخة PDF من الزر التالي:",
              pdfUrl: pdfUrl,
              isDownloadCard: true,
            ));
          }

          _isSending = false;
        });

        _scrollToBottom();
        return;
      }

      setState(() {
        _messages.add(const _ChatMessage(
          role: _Role.assistant,
          text: "حصل خطأ غير متوقع في صيغة الرد.",
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

  Future<void> _openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر فتح رابط ملف PDF")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("رابط ملف PDF غير صالح")),
      );
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return const _TypingBubble();
                }

                final m = _messages[index];
                final isUser = m.role == _Role.user;

                return _ChatBubble(
                  text: m.text,
                  isUser: isUser,
                  maxWidth: w * 0.78,
                  bubbleColor: isUser ? _bubbleUser : _bubbleBot,
                  textColor: isUser ? _textOnUser : Colors.black87,
                  options: m.options,
                  isDownloadCard: m.isDownloadCard,
                  isContractPreview: m.isContractPreview,
                  onDownloadTap: m.pdfUrl == null ? null : () => _openPdf(m.pdfUrl!),
                  onOptionTap: (opt) {
                    _controller.text = opt;
                    _send();
                  },
                );
              },
            ),
          ),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                          : const Icon(Icons.send,
                              color: Colors.white, size: 20),
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
  final List<String>? options;
  final String? pdfUrl;
  final bool isDownloadCard;
  final bool isContractPreview;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.options,
    this.pdfUrl,
    this.isDownloadCard = false,
    this.isContractPreview = false,
  });
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double maxWidth;
  final Color bubbleColor;
  final Color textColor;
  final List<String>? options;
  final bool isDownloadCard;
  final bool isContractPreview;
  final VoidCallback? onDownloadTap;
  final void Function(String option)? onOptionTap;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.maxWidth,
    required this.bubbleColor,
    required this.textColor,
    this.options,
    this.isDownloadCard = false,
    this.isContractPreview = false,
    this.onDownloadTap,
    this.onOptionTap,
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
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                border: isContractPreview
                    ? Border.all(color: const Color(0xFFB7D7CF))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                  if (isDownloadCard) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onDownloadTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B5345),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          "تحميل PDF",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isUser && options != null && options!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options!.map((opt) {
                  return ActionChip(
                    label: Text(
                      opt,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                    onPressed: onOptionTap == null ? null : () => onOptionTap!(opt),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFE9F2F0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Text(
          "يكتب الآن…",
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}