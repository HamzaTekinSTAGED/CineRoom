# CineRoom

Film tabanlı sohbet uygulaması. Kullanıcılar filmler hakkında notlar alabilir, favori listeleri oluşturabilir, film önerileri alabilir ve CineRoom gruplarında sohbet edebilir.

## Özellikler

- Firebase Authentication ile giriş/kayıt
- Film arama ve detayları (TMDB API)
- Favori film listesi
- Film notları
- Film öneri sistemi
- CineRoom gruplarında sohbet
- Profil sayfası (banner, profil fotoğrafı)

## Gereksinimler

- [Flutter](https://flutter.dev/docs/get-started/install) (SDK ^3.5.3)
- [Firebase](https://console.firebase.google.com/) projesi
- [TMDB](https://www.themoviedb.org/) API hesabı (ücretsiz)

## Kurulum

### 1. Bağımlılıkları yükle

```bash
flutter pub get
```

### 2. Ortam değişkenleri (.env)

Proje kök dizininde `.env` dosyası oluştur ve TMDB anahtarlarını ekle:

```bash
# Windows (PowerShell)
Copy-Item .env.example .env

# Linux / macOS
cp .env.example .env
```

Ardından `.env` dosyasını bir metin editörüyle açıp `your_tmdb_api_key_here` ve `your_tmdb_read_access_token_here` değerlerini kendi anahtarlarınızla değiştirin.

`.env` dosyasına eklenecekler:

| Değişken | Açıklama | Nereden alınır |
|----------|----------|----------------|
| `TMDB_API_KEY` | TMDB API Key | [TMDB API Ayarları](https://www.themoviedb.org/settings/api) |
| `TMDB_READ_ACCESS_TOKEN` | TMDB Read Access Token | TMDB API sayfasında "Request API Key" → "Developer" seçeneği ile alınır |

### 3. Firebase yapılandırması

Uygulama Firebase kullanır. Kendi Firebase projenizi bağlamak için:

```bash
# FlutterFire CLI'ı çalıştır (Firebase Console'da oturum açmanız gerekebilir)
dart run flutterfire_cli:flutterfire configure
```

Bu komut `lib/firebase_options.dart`, `android/app/google-services.json` ve `ios/Runner/GoogleService-Info.plist` dosyalarını oluşturur/günceller.

Mevcut bir Firebase projesi zaten yapılandırılmışsa bu adımı atlayabilirsiniz.

### 4. Uygulamayı çalıştır

```bash
flutter run
```

## Proje yapısı

```
lib/
├── config/
│   └── env_config.dart      # API anahtarları (.env'den okur)
├── pages/                   # Sayfa widget'ları
├── widgets/                 # Yeniden kullanılabilir widget'lar
├── cheatchat/               # Sohbet özellikleri
├── recommender/             # Film öneri sistemi
├── firebase_options.dart    # Firebase yapılandırması (FlutterFire ile oluşturulur)
└── main.dart
```

## Bağımlılıklar

- **firebase_core, firebase_auth, cloud_firestore, firebase_storage** – Firebase servisleri
- **flutter_dotenv** – Ortam değişkenleri (.env)
- **tmdb_api** – TMDB film API
- **provider** – State yönetimi
- **google_fonts** – Özel fontlar
- **image_picker** – Görsel seçimi
- **flutter_local_notifications** – Yerel bildirimler

## GitHub'a yüklemeden önce

- `.env` dosyası `.gitignore`'da olduğundan commit edilmez ✓
- API anahtarlarınızı asla koda yazmayın
- `.env.example` dosyasını güncel tutun (gerçek değerler olmadan)

## Lisans

MIT
