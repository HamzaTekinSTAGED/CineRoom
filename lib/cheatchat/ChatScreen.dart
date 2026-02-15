import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatScreen({super.key, 
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String currentUser = ""; // Replace with actual user ID

  @override
  void initState() {
    super.initState();
    _fetchUserNickname();
  }

  Future<void> _fetchUserNickname() async {
    final String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      // Handle unauthenticated user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must log in to use this feature.")),
      );
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();

      if (userDoc.exists && userDoc['nickname'] != null) {
        setState(() {
          currentUser = userDoc['nickname'];
        });
      } else {
        throw Exception("Nickname not found");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user nickname: $e")),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _firestore
        .collection('groupChats')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender': currentUser,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Odanın detaylarını al
    DocumentSnapshot roomDoc = await _firestore
        .collection('cineRooms')
        .doc(widget.groupId)
        .get();

    if (roomDoc['isPrivate'] == true) {
      // Gruptaki tüm üyeleri al
      List<dynamic> members = roomDoc['members'];
      
      // Her üye için UID'lerini bul
      for (String memberNickname in members) {
        if (memberNickname != currentUser) { // Mesajı gönderen kişiye bildirim gönderme
          // Üyenin UID'sini bul
          QuerySnapshot userQuery = await _firestore
              .collection('Users')
              .where('nickname', isEqualTo: memberNickname)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            String receiverUid = userQuery.docs.first.id;
            
            // Kullanıcının notifications koleksiyonuna bildirim ekle
            await _firestore
                .collection('notifications')
                .doc(receiverUid)
                .collection('userNotifications')
                .add({
              'roomId': widget.groupId,
              'roomName': widget.groupName,
              'sender': currentUser,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'message': _messageController.text.trim(),
            });
          }
        }
      }
    }

    _messageController.clear();
  }

  Future<String?> _getProfilePhotoUrl(String nickname) async {
    try {
      // Nickname'e göre kullanıcıyı bulalım
      QuerySnapshot userQuery = await _firestore
          .collection('Users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first['profilePhotoUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching profile photo: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'CineRoom',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[100]!,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('groupChats')
                      .doc(widget.groupId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading messages"));
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return const Center(child: Text("No messages yet"));
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final sender = message['sender'];
                        final text = message['text'];
                        final timestamp = message['timestamp'] as Timestamp?;
                        bool isCurrentUser = sender == currentUser;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isCurrentUser) ...[
                                FutureBuilder<String?>(
                                  future: _getProfilePhotoUrl(sender),
                                  builder: (context, snapshot) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                        image: snapshot.data != null
                                            ? DecorationImage(
                                                image: NetworkImage(snapshot.data!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: snapshot.data == null
                                          ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                                          : null,
                                    );
                                  },
                                ),
                              ],
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20).copyWith(
                                      bottomRight: isCurrentUser ? Radius.zero : null,
                                      bottomLeft: !isCurrentUser ? Radius.zero : null,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sender,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isCurrentUser
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isCurrentUser
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timestamp?.toDate().toString().substring(11, 16) ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isCurrentUser
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCurrentUser) ...[
                                FutureBuilder<String?>(
                                  future: _getProfilePhotoUrl(sender),
                                  builder: (context, snapshot) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[200],
                                        image: snapshot.data != null
                                            ? DecorationImage(
                                                image: NetworkImage(snapshot.data!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: snapshot.data == null
                                          ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                                          : null,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.white,
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
