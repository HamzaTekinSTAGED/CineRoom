import 'package:flutter/material.dart';

class MovieListView_forRecommender extends StatelessWidget {
  final List<dynamic> movies;
  final Function(String, String)? onSaveToDatabase;
  final bool showActions;

  const MovieListView_forRecommender({
    required this.movies,
    this.onSaveToDatabase,
    this.showActions = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final posterUrl = movie['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w200${movie['poster_path']}'
            : null;
        final movieName = movie['title'] ?? 'No Title';
        final description = movie['overview'] ?? 'No description available';

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie Poster
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  child: posterUrl != null
                      ? Image.network(
                          posterUrl,
                          height: 200,
                          width: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 200,
                          width: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, color: Colors.white70),
                        ),
                ),
                const SizedBox(width: 12),
                // Movie Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Film başlığı
                        Text(
                          movieName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Eşleşme göstergesi
                        if (movie['match_score'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: movie['match_percentage'] / 100,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      movie['match_percentage'] > 74
                                          ? Colors.yellow
                                          : movie['match_percentage'] > 49
                                              ? Colors.orange[400]!
                                              : Colors.red,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${movie['match_percentage']}% Match',
                                  style: TextStyle(
                                    color: movie['match_percentage'] > 74
                                        ? Colors.yellow[700]
                                        : movie['match_percentage'] > 49
                                            ? Colors.orange[400]
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Açıklama
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _showDescriptionDialog(context, movieName, description);
                            },
                            child: Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        // Butonlar
                        if (showActions)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      onSaveToDatabase?.call(movieName, 'watchlist');
                                    },
                                    icon: const Icon(Icons.playlist_add, size: 16),
                                    label: const Text(
                                      'Watchlist',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: const Size(0, 36),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      onSaveToDatabase?.call(movieName, 'favourites');
                                    },
                                    icon: const Icon(Icons.favorite, size: 16),
                                    label: const Text(
                                      'Favourites',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: const Size(0, 36),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
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

  void _showDescriptionDialog(BuildContext context, String movieName, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movieName),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
