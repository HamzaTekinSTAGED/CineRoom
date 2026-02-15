import 'package:flutter/material.dart';
import 'package:newdemo/widgets/MovieListView_forRecommender.dart';
import 'movie_search_service.dart';

class RecommendationsLoadingPage extends StatefulWidget {
  final List<TextEditingController> movieControllers;
  final MovieSearchService movieService;
  final Function(String, String) onSaveToDatabase;

  const RecommendationsLoadingPage({
    super.key,
    required this.movieControllers,
    required this.movieService,
    required this.onSaveToDatabase,
  });

  @override
  State<RecommendationsLoadingPage> createState() => _RecommendationsLoadingPageState();
}

class _RecommendationsLoadingPageState extends State<RecommendationsLoadingPage> {
  List<dynamic> recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      Map<int, int> recommendationCounts = {};
      Map<int, Map<String, dynamic>> movieDetails = {};
      int validMovieCount = 0;

      for (var controller in widget.movieControllers) {
        final movieName = controller.text.trim();
        if (movieName.isEmpty) continue;

        final movieId = await widget.movieService.searchMovie(movieName);
        if (movieId != null) {
          validMovieCount++;
          final recommendedMovieIds =
              await widget.movieService.getRecommendations(movieId);

          for (var recId in recommendedMovieIds) {
            recommendationCounts[recId] = (recommendationCounts[recId] ?? 0) + 1;
            
            if (!movieDetails.containsKey(recId)) {
              final details = await widget.movieService.getMovieDetails(recId);
              if (details != null) {
                movieDetails[recId] = details;
              }
            }
          }
        }
      }

      List<MapEntry<int, int>> sortedRecommendations = recommendationCounts.entries
          .where((entry) => entry.value >= 1) 
          .toList()
        ..sort((a, b) {
          // First sort by match count
          int compareResult = b.value.compareTo(a.value);
          if (compareResult == 0) {
            return a.key.compareTo(b.key);
          }
          return compareResult;
        });

      if (sortedRecommendations.length > 20) {
        sortedRecommendations = sortedRecommendations.sublist(0, 20);
      }

      List<dynamic> allRecommendations = [];
      
      for (var entry in sortedRecommendations) {
        if (movieDetails.containsKey(entry.key)) {
          var details = movieDetails[entry.key]!;
          double matchPercentage = (entry.value / validMovieCount) * 100;
          
          allRecommendations.add({
            'id': entry.key,
            'title': details['title'],
            'poster_path': details['poster_path'],
            'overview': details['overview'],
            'match_score': entry.value,
            'match_percentage': matchPercentage.round(),
          });
        }
      }

      setState(() {
        recommendations = allRecommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recommendations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        for (var controller in widget.movieControllers) {
          controller.clear();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Recommendations',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              for (var controller in widget.movieControllers) {
                controller.clear();
              }
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple[700],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple[700],
                ),
              )
            : recommendations.isEmpty
                ? const Center(child: Text('No recommendations found.'))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      color: Colors.white,
                      child: MovieListView_forRecommender(
                        movies: recommendations,
                        onSaveToDatabase: widget.onSaveToDatabase,
                      ),
                    ),
                  ),
      ),
    );
  }
} 