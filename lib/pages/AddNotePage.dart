import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:newdemo/config/env_config.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _movieController = TextEditingController();

  String _posterUrl = '';
  bool _isLoading = false;  // New loading state

  // Fetch poster URL from TMDb API
  Future<void> _fetchMoviePoster(String movieName) async {
    movieName = Uri.encodeComponent(movieName);
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=${EnvConfig.tmdbApiKey}&query=$movieName',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final posterUrl =
            'https://image.tmdb.org/t/p/w200${data['results'][0]['poster_path']}';
        setState(() {
          _posterUrl = posterUrl;
        });
      }
    }
  }

  // Publish note to Firestore
  Future<void> _publishNote() async {
    final String uid = _auth.currentUser?.uid ?? '';
    if (_noteController.text.isNotEmpty &&
        _movieController.text.isNotEmpty &&
        uid.isNotEmpty) {

      setState(() {
        _isLoading = true;  // Set loading state
      });

      await _fetchMoviePoster(_movieController.text);  // Wait for poster URL

      await _firestore.collection('Users').doc(uid).collection('notes').add({
        'movieName': _movieController.text,
        'content': _noteController.text,
        'posterURL': _posterUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;  // Remove loading state
      });

      _noteController.clear();
      _movieController.clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[700],
        title: const Text(
          'Add Note',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(height: 2, color: Colors.deepPurple[700]),
          Container(height: 2, color: Colors.deepPurple[400]),
          Container(height: 2, color: Colors.deepPurple[200]),
          Container(height: 2, color: Colors.grey[300]),
          const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _movieController,
                    decoration: InputDecoration(
                      hintText: 'Enter movie name...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter your note here...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    CircularProgressIndicator(color: Colors.deepPurple[700]),
                  if (!_isLoading)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _publishNote,
                      child: const Text(
                        'Publish',
                        style: TextStyle(fontSize: 16),
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
