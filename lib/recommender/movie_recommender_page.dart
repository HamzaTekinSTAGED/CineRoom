import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'movie_search_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recommendations_loading_page.dart';
import 'dart:async';

class MovieRecommenderPage extends StatefulWidget {
  const MovieRecommenderPage({super.key});

  @override
  _MovieRecommenderPageState createState() => _MovieRecommenderPageState();
}

class _MovieRecommenderPageState extends State<MovieRecommenderPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final MovieSearchService _movieService = MovieSearchService();
  List<dynamic> recommendations = [];
  final bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  
  final List<List<dynamic>> _suggestions = List.generate(4, (_) => []);
  final List<bool> _showSuggestions = List.generate(4, (_) => false);
  final List<Timer?> _debounceTimers = List.generate(4, (_) => null);
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getSuggestions(int index) async {
    if (_debounceTimers[index]?.isActive ?? false) {
      _debounceTimers[index]?.cancel();
    }

    _debounceTimers[index] = Timer(const Duration(milliseconds: 300), () async {
      final query = _controllers[index].text;
      if (query.isEmpty) {
        setState(() {
          _suggestions[index] = [];
          _showSuggestions[index] = false;
        });
        return;
      }

      try {
        final results = await _movieService.searchMovies(query);
        if (mounted) {
          setState(() {
            _suggestions[index] = results;
            _showSuggestions[index] = true;
          });
        }
      } catch (e) {
        print('Error getting suggestions: $e');
      }
    });
  }

  Widget _buildTextField(int index) {
    return Column(
      children: [
        TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          decoration: InputDecoration(
            labelText: 'Movie Name',
            labelStyle: TextStyle(color: Colors.deepPurple[700]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple[700]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple[200]!),
            ),
          ),
          onChanged: (value) {
            if (_focusNodes[index].hasFocus) {
              _getSuggestions(index);
            }
          },
          onTap: () {
            setState(() {
              for (int i = 0; i < _showSuggestions.length; i++) {
                if (i != index) {
                  _showSuggestions[i] = false;
                }
              }
            });
          },
        ),
        if (_showSuggestions[index] && _suggestions[index].isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _suggestions[index].length,
                  itemBuilder: (context, i) {
                    final movie = _suggestions[index][i];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        movie['title'],
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: movie['year'] != null && movie['year'].toString().isNotEmpty
                          ? Text(
                              movie['year'],
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _controllers[index].text = movie['title'];
                          _showSuggestions[index] = false;
                          _focusNodes[index].unfocus();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _saveToDatabase(String movieName, String listType) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
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

Future<void> getRecommendations() async {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => RecommendationsLoadingPage(
        movieControllers: _controllers,
        movieService: _movieService,
        onSaveToDatabase: _saveToDatabase,
      ),
    ),
  );
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
    return GestureDetector(
      onTap: () {
        setState(() {
          for (int i = 0; i < _showSuggestions.length; i++) {
            _showSuggestions[i] = false;
          }
        });
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Movie Recommender',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple[700],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 32.0),
                ..._controllers.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: _buildTextField(entry.key),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: getRecommendations,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('request'),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var timer in _debounceTimers) {
      timer?.cancel();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
