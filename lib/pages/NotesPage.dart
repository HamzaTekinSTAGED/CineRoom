import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newdemo/pages/AddNotePage.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Navigates to the AddNotePage
  void _navigateToAddNotePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddNotePage(),
      ),
    );
  }

  
  String? _fixPosterUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // w00 olan URL'leri w200 olarak düzelt
    if (url.contains('/w00/')) {
      return url.replaceAll('/w00/', '/w200/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _auth.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[700],
        title: const Text(
          'Notes',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToAddNotePage,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 2,
            color: Colors.deepPurple[400],
          ),
          Container(
            height: 2,
            color: Colors.deepPurple[200],
          ),
          Container(
            height: 2,
            color: Colors.deepPurple[100],
          ),
          Container(
            height: 2,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('Users')
                  .doc(uid)
                  .collection('notes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.greenAccent));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    String content = doc['content'];
                    String? posterUrl = _fixPosterUrl(doc["posterURL"]);
                    
                    
                    
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: posterUrl != null && posterUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  posterUrl,
                                  width: 40,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.movie,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.grey,
                                ),
                              ),
                        title: Text(
                          doc["movieName"],
                          style: const TextStyle(color: Colors.black),
                        ),
                        onTap: () {
                          _showFullNoteDialog(content, doc['movieName'], doc["posterURL"]);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullNoteDialog(String content, String movieName, String? posterUrl) {
    posterUrl = _fixPosterUrl(posterUrl);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Movie Name
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    movieName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Close Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
