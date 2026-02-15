import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newdemo/config/env_config.dart';
import 'package:newdemo/cheatchat/CineRoomsPage.dart';
import 'package:newdemo/pages/MovieSearchPage.dart';
import 'package:newdemo/pages/NewsPage.dart';
import 'package:newdemo/pages/NotesPage.dart';
import 'package:newdemo/pages/ProfilePage.dart';
import 'package:newdemo/pages/WatchlistPage.dart';
import 'package:newdemo/recommender/movie_recommender_page.dart';
import 'package:newdemo/pages/login_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newdemo/cheatchat/ChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CineRoomApp extends StatelessWidget {
  const CineRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CineRoomHome(),
    );
  }
}

class CineRoomHome extends StatefulWidget {
  const CineRoomHome({super.key});

  @override
  State<CineRoomHome> createState() => _CineRoomHomeState();
}

class _CineRoomHomeState extends State<CineRoomHome> {
  final List<String> _movieNames = [
    'Wıcked',
    'Sonic the Hedgehog 3',
    'Mufasa: The Lion King ',
    'Kraven the Hunter',
    'Red One',
    'Nosferatu',
    'Anora',
    'A Complete Unknown',
    'Heretic',
    'The Lord of the Rings: The War of the Rohirrim'
  ];
  String? _currentPosterUrl;
  int _currentIndex = 0;

  final Color _primaryColor = Colors.deepPurple[700]!;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  int _unreadNotifications = 0;
  String currentUser = "";

  @override
  void initState() {
    super.initState();
    _fetchRandomMoviePoster();
    _initializeNotifications();
    _fetchCurrentUser();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String groupName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      '$groupName yeni mesajlarınız var',
      'Yeni mesajlarınızı kontrol edin.',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void _onNotificationIconPressed() {
    _showNotification("Grup A");
  }

  Future<void> _fetchMoviePoster(String movieName) async {
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=${EnvConfig.tmdbApiKey}&query=${Uri.encodeComponent(movieName)}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final posterPath = data['results'][0]['poster_path'];
        if (posterPath != null) {
          setState(() {
            _currentPosterUrl = 'https://image.tmdb.org/t/p/w200$posterPath';
          });
        } else {
          setState(() {
            _currentPosterUrl = null; // No poster available
          });
        }
      } else {
        setState(() {
          _currentPosterUrl = null; // No results
        });
      }
    } else {
      setState(() {
        _currentPosterUrl = null; // API error
      });
    }
  }

  void _fetchRandomMoviePoster() {
    final randomIndex = Random().nextInt(_movieNames.length);
    _fetchMoviePoster(_movieNames[randomIndex]);
  }

  void _showNextPoster() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _movieNames.length;
    });
    _fetchMoviePoster(_movieNames[_currentIndex]);
  }

  void _showPreviousPoster() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _movieNames.length) % _movieNames.length;
    });
    _fetchMoviePoster(_movieNames[_currentIndex]);
  }

  void _listenToNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _notificationSubscription = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadNotifications = snapshot.docs.length;
      });
    });
  }

  Future<void> _fetchCurrentUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      if (userDoc.exists && userDoc['nickname'] != null) {
        setState(() {
          currentUser = userDoc['nickname'];
        });
        _listenToNotifications();
      }
    }
  }

  void _showNotifications(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final notifications = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (!context.mounted) return;

    if (notifications.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No new notifications'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notifications'),
            TextButton(
              onPressed: () async {
                for (var doc in notifications.docs) {
                  await doc.reference.update({'isRead': true});
                }
                if (context.mounted) Navigator.pop(context);
                setState(() {
                  _unreadNotifications = 0;
                });
              },
              child: const Text('Mark all as read'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notifications.docs.length,
            itemBuilder: (context, index) {
              final notification = notifications.docs[index];
              return ListTile(
                leading: const Icon(Icons.message),
                title: Text(
                  '${notification['roomName']} grubundan mesajınız var',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Gönderen: ${notification['sender']}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  await notification.reference.update({'isRead': true});
                  
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  
                  setState(() {
                    _unreadNotifications = _unreadNotifications - 1;
                  });
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        groupId: notification['roomId'],
                        groupName: notification['roomName'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              color: _primaryColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'CineRoom',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () => _showNotifications(context),
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$_unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Ana içerik
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Arama Çubuğu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MovieSearchPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Search movies...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trend Filmler
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Trending Movies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Film Posterleri
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.7),
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                          _fetchMoviePoster(_movieNames[_currentIndex]);
                        },
                        itemCount: _movieNames.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: _currentPosterUrl != null
                                ? Image.network(
                                    _currentPosterUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: Text('Error loading image'),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: Text('No poster available'),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Özellikler Grid'i
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          _buildFeatureCard(
                            'Movie Monster',
                            Icons.movie_filter_rounded,
                            const MovieRecommenderPage(),
                          ),
                          _buildFeatureCard(
                            'Watch List',
                            Icons.playlist_play_rounded,
                            WatchlistPage(),
                          ),
                          _buildFeatureCard(
                            'Chat Room',
                            Icons.chat_bubble_outline_rounded,
                            CineRoomsPage(),
                          ),
                          _buildFeatureCard(
                            'Notes',
                            Icons.note_alt_outlined,
                            const NotesPage(),
                          ),
                          _buildFeatureCard(
                            'News',
                            Icons.newspaper_rounded,
                            NewsPage(),
                          ),
                          _buildFeatureCard(
                            'Switch Account',
                            Icons.switch_account_rounded,
                            const LoginPage(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Widget page) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: _primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
