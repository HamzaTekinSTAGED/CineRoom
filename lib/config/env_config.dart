import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Merkezi API key yönetimi - .env dosyasından okur
class EnvConfig {
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get tmdbReadAccessToken =>
      dotenv.env['TMDB_READ_ACCESS_TOKEN'] ?? '';

  static bool get hasValidTmdbConfig =>
      tmdbApiKey.isNotEmpty && tmdbReadAccessToken.isNotEmpty;
}
