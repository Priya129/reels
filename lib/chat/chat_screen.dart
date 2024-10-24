import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../global/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _messageController = TextEditingController();
  late Future<Map<String, String>> _userNamesFuture;

  @override
  void initState() {
    super.initState();
    _userNamesFuture = _getUserNames();
  }

  Future<Map<String, String>> _getUserNames() async {
    final currentUserSnapshot =
        await _firestore.collection('user').doc(widget.currentUserId).get();
    final otherUserSnapshot =
        await _firestore.collection('user').doc(widget.otherUserId).get();

    return {
      widget.currentUserId:
          currentUserSnapshot.data()?['username'] ?? 'Unknown',
      widget.otherUserId: otherUserSnapshot.data()?['username'] ?? 'Unknown'
    };
  }

  Future<void> _showDeleteConfirmationDialog(String messageId) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete Message'),
            content: Text('Are you sure you want to delete this message?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Delete'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteMessage(messageId);
                },
              ),
            ],
          );
        });
  }

  Future<void> _deleteMessage(String messageId) async {
    await _firestore
        .collection('chats')
        .doc(widget.currentUserId)
        .collection(widget.otherUserId)
        .doc(messageId)
        .delete();

    await _firestore
        .collection('chats')
        .doc(widget.otherUserId)
        .collection(widget.otherUserId)
        .doc(messageId)
        .delete();
  }

  Future<void> _clearAllMessages() async {
    final currentUserMessage = await _firestore
        .collection('chats')
        .doc(widget.currentUserId)
        .collection(widget.otherUserId)
        .get();

    for (var doc in currentUserMessage.docs) {
      await doc.reference.delete();
    }

    final otherUserMessage = await _firestore
        .doc(widget.otherUserId)
        .collection(widget.currentUserId)
        .get();

    for (var doc in otherUserMessage.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.mainColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          title: FutureBuilder(
              future: _userNamesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Chat');
                }
                if (!snapshot.hasData) {
                  return const Text('Chat');
                }
                final userNames = snapshot.data!;
                return Text(
                  'Chat with ${userNames[widget.otherUserId]}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: AppColors.mainColor),
                );
              }),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'clear_all') {
                  await _clearAllMessages();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Text('Clear All Messages'),
                  ),
                ];
              },
              icon: const Icon(Icons.more_vert,
                  color: AppColors.mainColor),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.currentUserId)
                  .collection(widget.otherUserId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No message'),
                  );
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isSentByCurrentUser =
                          message['sender'] == widget.currentUserId;
                      return ListTile(
                        onLongPress: isSentByCurrentUser
                            ? () {
                                _showDeleteConfirmationDialog(message.id);
                              }
                            : null,
                        title: Align(
                          alignment: isSentByCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSentByCurrentUser
                                  ? AppColors.mainColor
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: isSentByCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                FutureBuilder(
                                    future: _userNamesFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container();
                                      }
                                      final userNames = snapshot.data!;
                                      return Text(
                                        userNames[message['sender']] ??
                                            'Unknown',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSentByCurrentUser
                                                ? Colors.white
                                                : Colors.black87),
                                      );
                                    }),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  message['text'],
                                  style: TextStyle(
                                      color: isSentByCurrentUser
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                    message['timestamp'] != null
                                        ? DateFormat('EEE HH:mm').format(
                                            (message['timestamp'] as Timestamp)
                                                .toDate())
                                        : '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isSentByCurrentUser
                                            ? Colors.white70
                                            : Colors.black54))
                              ],
                            ),
                          ),
                        ),
                        trailing: isSentByCurrentUser ? null : null,
                      );
                    });
              },
            )),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mainColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.mainColor)),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_messageController.text.isNotEmpty) {
                        await _firestore
                            .collection('chats')
                            .doc(widget.currentUserId)
                            .collection(widget.otherUserId)
                            .add({
                          'text': _messageController.text,
                          'sender': widget.currentUserId,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        await _firestore
                            .collection('chats')
                            .doc(widget.otherUserId)
                            .collection(widget.currentUserId)
                            .add({
                          'text': _messageController.text,
                          'sender': widget.currentUserId,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        _messageController.clear();
                      }
                    },
                    child: const ImageIcon(AssetImage('assets/Images/send.png'),
                        size: 25, color: AppColors.mainColor),
                  )
                ],
              ),
            )
          ],
        ));
  }
}
