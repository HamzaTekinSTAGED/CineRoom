import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newdemo/config/env_config.dart';

// Moving MovieDetails class outside
class MovieDetails {
  final String? posterUrl;
  final String? overview;
  final List<String> genres;
  final double? rating;

  MovieDetails({
    this.posterUrl, 
    this.overview,
    this.genres = const [],
    this.rating,
  });

  String? get shortOverview {
    if (overview == null) return null;
    
    // Count words
    List<String> words = overview!.split(' ');
    if (words.length <= 50) return overview;

    // Take first 50 words
    String truncated = words.take(50).join(' ');
    
    // Find text after first period
    int dotIndex = truncated.indexOf('.');
    if (dotIndex == -1) {
      dotIndex = truncated.length;
    }
    
    // Take until period and add ellipsis
    return '${truncated.substring(0, dotIndex + 1)}...';
  }
}

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  _WatchlistPageState createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isGridView = true;

  Future<MovieDetails> fetchMovieDetails(String movieName) async {
    final apiKey = EnvConfig.tmdbApiKey;
    final query = Uri.encodeComponent(movieName);
    final url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final movie = data['results'][0];
          final posterPath = movie['poster_path'];
          final overview = movie['overview'];
          
          // Second API call to get movie genres
          final movieId = movie['id'];
          final detailsUrl =
              'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey';
          final detailsResponse = await http.get(Uri.parse(detailsUrl));
          List<String> genres = [];
          double? rating;
          
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            genres = (detailsData['genres'] as List)
                .map((genre) => genre['name'] as String)
                .toList();
            rating = (detailsData['vote_average'] as num?)?.toDouble();
          }

          return MovieDetails(
            posterUrl: posterPath != null
                ? 'https://image.tmdb.org/t/p/w200$posterPath'
                : null,
            overview: overview,
            genres: genres,
            rating: rating,
          );
        }
      }
    } catch (e) {
      print('Error fetching movie details: $e');
    }
    return MovieDetails();
  }

 // moving addToWatchedList it adds movie to favourites in database and interface
 // When we decided to abandon the watchedlist structure and make a favorite movie list, there were some minor messes in the code structure.
 // WATCHEDLIST functions are used for FAVORITES list.
  Future<void> addToWatchedList(String movieName, BuildContext context) async {
    try {
      // First delete from watchlist
      final watchlistRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('watchlist')
          .where('name', isEqualTo: movieName);
      
      final watchlistDocs = await watchlistRef.get();
      if (watchlistDocs.docs.isNotEmpty) {
        await watchlistDocs.docs.first.reference.delete();
      }

      // Add to watched list
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .collection('watchedlist')
          .add({
        'name': movieName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$movieName moved to favourites list')),
      );
    } catch (e) {
      print('Error moving to favourites list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error moving movie to favourites list')),
      );
    }
  }

  Widget _buildListView(List<QueryDocumentSnapshot> watchlistMovies) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: watchlistMovies.length,
      physics: const PageScrollPhysics(),
      itemBuilder: (context, index) {
        final movie = watchlistMovies[index];
        final movieName = movie['name'] ?? 'Unknown Movie';

        return FutureBuilder<MovieDetails>(
          future: fetchMovieDetails(movieName),
          builder: (context, movieSnapshot) {
            final movieDetails = movieSnapshot.data;
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: movieSnapshot.connectionState == ConnectionState.waiting
                          ? SizedBox(
                              height: 400,
                              child: const Center(child: CircularProgressIndicator()),
                            )
                          : movieDetails?.posterUrl != null
                              ? ClipRRect(
                                  borderRadius:const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color:const Color(0xFF283593), width: 1.5),
                                    ),
                                    child: Image.network(
                                      movieDetails!.posterUrl!,
                                      height: 380,
                                      width: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 400,
                                  child: const Center(child: Text('No Poster')),
                                ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF283593),
                        border: Border.all(color: const Color(0xFF283593)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                movieName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(user!.uid)
                                  .collection('watchlist')
                                  .doc(movie.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$movieName removed from watchlist'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (movieDetails?.genres.isNotEmpty ?? false) ...[
                      Container(
                        padding:const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: movieDetails!.genres.map((genre) => Container(
                                  padding:const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF283593).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    genre,
                                    style:const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            if (movieDetails.rating != null) ...[
                              Container(
                                padding:const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      movieDetails.rating!.toStringAsFixed(1),
                                      style:const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (movieDetails?.overview != null) ...[
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Text(
                            movieDetails!.shortOverview!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_agenda : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .collection('watchlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No movies in your watchlist'),
            );
          }
          final watchlistMovies = snapshot.data!.docs;

          return isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: watchlistMovies.length,
                  itemBuilder: (context, index) {
                    final movie = watchlistMovies[index];
                    final movieName = movie['name'] ?? 'Unknown Movie';

                    return FutureBuilder<MovieDetails>(
                      future: fetchMovieDetails(movieName),
                      builder: (context, movieSnapshot) {
                        final movieDetails = movieSnapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            movieSnapshot.connectionState == ConnectionState.waiting
                                ? const Expanded(
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : movieDetails?.posterUrl != null
                                    ? Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color:const Color(0xFF283593), width: 1.5),
                                            ),
                                            child: Image.network(
                                              movieDetails!.posterUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Expanded(
                                        child: Center(child: Text('No Poster')),
                                      ),
                            Container(
                              decoration: BoxDecoration(
                                color:const Color(0xFF283593),
                                border: Border.all(color:const Color(0xFF283593)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        movieName,
                                        overflow: TextOverflow.ellipsis,
                                        style:const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon:const Icon(Icons.delete, color: Colors.white),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(user!.uid)
                                          .collection('watchlist')
                                          .doc(movie.id)
                                          .delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$movieName removed from watchlist'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
              : _buildListView(watchlistMovies);
        },
      ),
    );
  }
}
