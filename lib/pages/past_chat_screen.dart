import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PastChatScreen extends StatefulWidget {
  @override
  _PastChatScreenState createState() => _PastChatScreenState();
}

class _PastChatScreenState extends State<PastChatScreen> {
  String? senderID; 
  String? receiverID; 
  int? appointmentID;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
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
      
      print('Data received - Sender: $senderID, Receiver: $receiverID, Appointment: $appointmentID');
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
          'محادثة منتهية',
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
          ],
        ),
      ),
    );
  }
}