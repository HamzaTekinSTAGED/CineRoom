import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newdemo/widgets/MovieListView.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newdemo/config/env_config.dart';

class MovieSearchPage extends StatefulWidget {
  const MovieSearchPage({super.key});

  @override
  _MovieSearchPageState createState() => _MovieSearchPageState();
}

class _MovieSearchPageState extends State<MovieSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _movieResults = [];
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _searchMovies(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
          'https://api.themoviedb.org/3/search/movie?api_key=${EnvConfig.tmdbApiKey}&query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _movieResults = data['results'] ?? [];
        });
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToDatabase(String movieName, String listType) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final db = FirebaseFirestore.instance;
    
    try {
      await db
          .collection('Users')
          .doc(user!.uid)
          .collection(listType)
          .add({
        'name': movieName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$movieName added to ${listType == "watchlist" ? "watchlist" : "favourites"}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not add movie'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error saving to database: $e');
    }
  }

  void _showDescriptionDialog(String movieName, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movieName),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        body: Column(
          children: [
            // Custom Header
            Container(
              color: Colors.deepPurple[700],
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Expanded(
                        child:  Center(
                          child: Text(
                            'CineRoom',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SansitaSwashed',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (value) {
                  _searchMovies(value);
                },
              ),
            ),

            // Movie List
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_movieResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No results found'),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0), // Sağ ve sol kenar boşluğu
                  child: Container(
                    color: Colors.white, // Arka plan rengi
                    child: MovieListView(
                      movies: _movieResults,
                      onSaveToDatabase: (movieName, listType) {
                        _saveToDatabase(movieName, listType);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
