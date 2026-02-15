import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newdemo/config/env_config.dart';

class MovieSearchService {
  // Searches for a movie by name and returns its ID
  Future<int?> searchMovie(String movieName) async {
    final apiKey = EnvConfig.tmdbApiKey;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieName');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        return data['results'][0]['id']; // Return the first result's ID
      }
    }
    return null; // If no results found, return null
  }

  // Fetches recommendations based on a movie's ID
  Future<List<int>> getRecommendations(int movieId) async {
    final apiKey = EnvConfig.tmdbApiKey;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/$movieId/recommendations?api_key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['results'] as List)
          .map((movie) => movie['id'] as int)
          .toList();
    }
    return []; // Return an empty list if no recommendations
  }

  // Fetches details of a movie by its ID
  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    final apiKey = EnvConfig.tmdbApiKey;
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'title': data['title'],
        'poster_path': data['poster_path'],
        'overview': data['overview'],
      };
    }
    return null; // Return null if the request fails
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    try {
      final apiKey = EnvConfig.tmdbApiKey;
      final url = Uri.parse(
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}&language=en-US',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List)
            .take(5)
            .map((movie) => {
                  'title': movie['original_title'],
                  'id': movie['id'],
                  'year': movie['release_date'] != null && movie['release_date'].toString().isNotEmpty
                      ? movie['release_date'].toString().substring(0, 4)
                      : '',
                })
            .toList();
        return results;
      }
    } catch (e) {
      print('Error searching movies: $e');
    }
    return [];
  }
}
