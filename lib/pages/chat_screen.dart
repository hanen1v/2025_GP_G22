import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? senderID; 
  String? receiverID; 
  int? appointmentID;
  final messageController = TextEditingController(); 

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة دالة استقبال البيانات
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getArguments();
  }

  void _getArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map) {
      setState(() {
        senderID = args['senderID'];
        receiverID = args['receiverID'];
        appointmentID = args['appointmentID'];
      });
      
      print('✅ Data received - Sender: $senderID, Receiver: $receiverID, Appointment: $appointmentID');
    }
  }

  void sendMessage() {
    final message = messageController.text.trim();

    if (message.isNotEmpty) {
      _firestore.collection('chats').add({
        'senderID': senderID, 
        'receiverID': receiverID, 
        'appointmentID': appointmentID,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      messageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال الرسالة'))
      );
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
    // إضافة شرط التحميل
    if (senderID == null || receiverID == null || appointmentID == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 9, 44, 36),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تحميل...',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 9, 44, 36),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'محادثة نشطة',
          style: TextStyle(color: Colors.white),
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
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true, 
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index].data() as Map<String, dynamic>;
                      final message = messageData['message'];
                      final sender = messageData['senderID'];
  
                      final isMe = sender == senderID;  
  
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, 
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Color.fromARGB(255, 9, 44, 36) : Colors.grey[300], 
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'أدخل رسالتك',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 9, 44, 36),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
