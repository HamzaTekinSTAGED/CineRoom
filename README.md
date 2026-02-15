# CineRoom

A movie-based chat application. Users can take notes about movies, create favorite lists, get movie recommendations, and chat in CineRoom groups.

## Features

- Login/registration with Firebase Authentication
- Movie search and details (TMDB API)
- Favorite movie list
- Movie notes
- Movie recommendation system
- Chat in CineRoom groups
- Profile page (banner, profile picture)

## Requirements

- [Flutter](https://flutter.dev/docs/get-started/install) (SDK ^3.5.3)
- [Firebase](https://console.firebase.google.com/) project

- [TMDB](https://www.themoviedb.org/) API account (free)

## Installation

### 1. Install dependencies

```bash
flutter pub get
```
### 2. Environment Variables (.env)

Create a `.env` file in the project root directory and add the TMDB keys:

```bash
# Windows (PowerShell)
Copy-Item .env.example .env
# Linux / macOS
cp .env.example .env
```

Then open the `.env` file with a text editor and replace `your_tmdb_api_key_here` and `your_tmdb_read_access_token_here` with your own keys.

The following will be added to the `.env` file:

| Variable | Description | Where to get |
|----------|----------|----------------|
| `TMDB_API_KEY` | TMDB API Key | [TMDB API Settings](https://www.themoviedb.org/settings/api) |
| `TMDB_READ_ACCESS_TOKEN` | TMDB Read Access Token | Obtained via "Request API Key" → "Developer" option on the TMDB API page |

### 3. Firebase configuration

The application uses Firebase. To connect your own Firebase project:

```bash
# Run FlutterFire CLI (You may need to sign in to the Firebase Console)
dart run flutterfire_cli:flutterfire configure
```

This command creates/updates the `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist` files.

You can skip this step if an existing Firebase project is already configured.
### 4. Run the application

```bash
flutter run
```
## Project structure

```
lib/
├── config/
│ └── env_config.dart # API keys (reads from .env)
├── pages/ # Page widgets
├── widgets/ # Reusable widgets
├── cheatchat/ # Chat features
├── recommender/ # Movie recommendation system
├── firebase_options.dart # Firebase configuration (created with FlutterFire)
└── main.dart
```

## Dependencies

- **firebase_core, firebase_auth, cloud_firestore, firebase_storage** – Firebase services
- **flutter_dotenv** – Environment variables (.env)
- **tmdb_api** – TMDB movie API
- **provider** – State management
- **google_fonts** – Custom fonts
- **image_picker** – Image selection
- **flutter_local_notifications** – Local notifications

## Lisans

MIT
