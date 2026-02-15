import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newdemo/cheatchat/ChatScreen.dart';

class CineRoomsPage extends StatefulWidget {
  const CineRoomsPage({super.key});

  @override
  _CineRoomsPageState createState() => _CineRoomsPageState();
}

class _CineRoomsPageState extends State<CineRoomsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String currentUser = "";
  bool showPrivateOnly = false;
  bool showPublicOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchUserNickname();
  }

  Future<void> _fetchUserNickname() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('Users').doc(userId).get();
        if (userDoc.exists && userDoc['nickname'] != null) {
          setState(() {
            currentUser = userDoc['nickname'];
          });
        }
      } catch (e) {
        print("Error fetching nickname: $e");
      }
    }
  }

  Future<void> _showCreateRoomDialog() async {
    TextEditingController roomNameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:const Text("Create New Room"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomNameController,
                  decoration:const InputDecoration(
                    hintText: "Room Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isPrivate,
                      onChanged: (value) {
                        setState(() {
                          isPrivate = value ?? false;
                        });
                      },
                    ),
                    const Text("Private Room"),
                  ],
                ),
                if (isPrivate) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: "Room Password",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (roomNameController.text.isNotEmpty && 
                    (!isPrivate || (isPrivate && passwordController.text.isNotEmpty))) {
                  
                  // Close the dialog first
                  Navigator.pop(dialogContext);
                  
                  // Loading indicator
                  BuildContext loadingContext = context;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context){
                      loadingContext = context;
                      return   const Center(
                      child: CircularProgressIndicator(),
                    );
                    },
                  );

                  try {
                    await _firestore.collection('cineRooms').add({
                      'name': roomNameController.text,
                      'isPrivate': isPrivate,
                      'password': isPrivate ? passwordController.text : null,
                      'members': [currentUser],
                      'createdBy': currentUser,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // Close loading
                    Navigator.of(loadingContext).pop(); 

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Room created successfully"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } catch (e) {
                    // Close loading
                    Navigator.of(loadingContext).pop();
                    
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error creating room: $e"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all required fields"),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinPrivateRoom(String roomId, String roomName) async {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Enter Room Password"),
        content: SingleChildScrollView(
          child: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              hintText: "Password",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter password"),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }

              // Save loading context
              BuildContext loadingContext = context;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  loadingContext = context;
                  return const Center(child: CircularProgressIndicator());
                },
              );
              
              try {
                DocumentSnapshot room = await _firestore.collection('cineRooms').doc(roomId).get();
                
                // Close loading
                Navigator.pop(loadingContext);
                
                if (room['password'] == passwordController.text) {
                  await _firestore.collection('cineRooms').doc(roomId).update({
                    'members': FieldValue.arrayUnion([currentUser]),
                  });
                  
                  Navigator.pop(dialogContext); // Close password dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Successfully joined the room"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );

                  await Future.delayed(const Duration(milliseconds: 500));
                  Navigator.pushReplacement( 
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        groupId: roomId,
                        groupName: roomName,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect password. Please try again."),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                  passwordController.clear();
                }
              } catch (e) {
                Navigator.pop(loadingContext); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error joining room: $e"),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child:const Text("Join"),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom(String roomId, String roomName, bool isPrivate) async {
    if (isPrivate) {
      await _joinPrivateRoom(roomId, roomName);
    } else {
      try {
        // Loading göstergesi
        BuildContext dialogContext = context;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            dialogContext = context;
            return const Center(child: CircularProgressIndicator());
          },
        );

        DocumentSnapshot room = await _firestore.collection('cineRooms').doc(roomId).get();
        List<dynamic> members = room['members'];
        
        // Loading'i kapat
        Navigator.pop(dialogContext);
        
        if (members.contains(currentUser)) {
          Navigator.pushReplacement( 
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                groupId: roomId,
                groupName: roomName,
              ),
            ),
          );
          return;
        }

        await _firestore.collection('cineRooms').doc(roomId).update({
          'members': FieldValue.arrayUnion([currentUser]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully joined the room"),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacement( 
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              groupId: roomId,
              groupName: roomName,
            ),
          ),
        );

      } catch (e) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error joining room: $e"),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "CineRooms",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              onPressed: _showCreateRoomDialog,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterButton(
                    "Public",
                    Icons.public_rounded,
                    showPublicOnly,
                    () {
                      setState(() {
                        showPublicOnly = !showPublicOnly;
                        if (showPublicOnly) showPrivateOnly = false;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildFilterButton(
                    "Private",
                    Icons.lock_outline_rounded,
                    showPrivateOnly,
                    () {
                      setState(() {
                        showPrivateOnly = !showPrivateOnly;
                        if (showPrivateOnly) showPublicOnly = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('cineRooms').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rooms = snapshot.data!.docs.where((room) {
                    if (showPrivateOnly) {
                      return room['isPrivate'] == true;
                    } else if (showPublicOnly) {
                      return room['isPrivate'] == false;
                    }
                    return true;
                  }).toList();

                  if (rooms.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No rooms available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final bool isPrivate = room['isPrivate'];
                      final bool isMember = (room['members'] as List).contains(currentUser);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isMember
                                ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        groupId: room.id,
                                        groupName: room['name'],
                                      ),
                                    ),
                                  )
                                : () => _joinRoom(room.id, room['name'], isPrivate),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  _buildRoomIcon(isPrivate),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.group_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${(room['members'] as List).length} members",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isMember) _buildJoinButton(room, isPrivate),
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildRoomIcon(bool isPrivate) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPrivate
            ? Colors.orange[50]
            : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
        color: isPrivate ? Colors.orange[700] : Colors.green[700],
        size: 20,
      ),
    );
  }

  Widget _buildJoinButton(DocumentSnapshot room, bool isPrivate) {
    return  SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () => _joinRoom(room.id, room['name'], isPrivate),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          "Join",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      String text, IconData icon, bool isActive, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
} 