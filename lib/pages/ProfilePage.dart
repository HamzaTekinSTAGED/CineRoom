import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newdemo/config/env_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _bannerImage;
  File? _profilePhoto;
  String? _bannerUrl;
  String? _profilePhotoUrl;

  late TMDB tmdb;

  @override
  void initState() {
    super.initState();
    _fetchBannerUrl();
    _fetchProfilePhotoUrl();
    tmdb = TMDB(ApiKeys(
      EnvConfig.tmdbApiKey,
      EnvConfig.tmdbReadAccessToken,
    ));
  }

  Future<void> _fetchBannerUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _bannerUrl = userDoc['bannerUrl'];
        });
      }
    }
  }

  Future<void> _fetchProfilePhotoUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _profilePhotoUrl = userDoc['profilePhotoUrl'];
        });
      }
    }
  }

  Future<void> uploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final pathOfPhoto = pickedFile.path;
      File file = File(pathOfPhoto);
      setState(() {
        _profilePhoto = file;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        String filePath =
            'profilePhotos/${Uri.file(file.path).pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref().child(filePath);

        try {
          await storageRef.putFile(file);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .set({'profilePhotoUrl': imageUrl}, SetOptions(merge: true));

          setState(() {
            _profilePhotoUrl = imageUrl;
          });

          print('Profile photo uploaded to Storage and URL saved in Firestore');
        } catch (e) {
          print("Error uploading profile photo: $e");
        }
      } else {
        print('No user is signed in');
      }
    } else {
      print("No image selected");
    }
  }

  Future<void> uploadFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final pathOfPhoto = pickedFile.path;
      File file = File(pathOfPhoto);
      setState(() {
        _bannerImage = file;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        String filePath =
            'bannerImages/${Uri.file(file.path).pathSegments.last}';
        final storageRef = FirebaseStorage.instance.ref().child(filePath);

        try {
          await storageRef.putFile(file);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .set({'bannerUrl': imageUrl}, SetOptions(merge: true));

          setState(() {
            _bannerUrl = imageUrl; // Update UI with new banner URL
          });

          print('Image uploaded to Storage and URL saved in Firestore');
        } catch (e) {
          print('Error uploading banner image: $e');
        }
      } else {
        print('No user is signed in');
      }
    } else {
      print('No image selected');
    }
  }

  Future<String> _getNickname() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      return doc['nickname'] ?? 'No nickname found';
    }
    return 'User not found';
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: DefaultTabController(
        length: 1,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: false,
                snap: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Banner Image
                      Container(
                        height: 200,
                        color: const Color.fromARGB(31, 14, 35, 38),
                        child: _bannerImage != null
                            ? Image.file(
                                _bannerImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : (_bannerUrl != null
                                ? Image.network(
                                    _bannerUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      // Edit Button
                      Positioned(
                        top: 40,
                        right: 16,
                        child: TextButton(
                          onPressed: uploadFile,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      // Profile Photo
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: GestureDetector(
                          onTap: uploadProfilePhoto,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey,
                            backgroundImage: _profilePhoto != null
                                ? FileImage(_profilePhoto!)
                                : (_profilePhotoUrl != null
                                    ? NetworkImage(_profilePhotoUrl!)
                                    : null),
                            child: _profilePhoto == null && _profilePhotoUrl == null
                                ? const Text('Photo')
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              // Username container - her zaman görünür
              Container(
                color: Colors.deepPurple[700],
                padding: const EdgeInsets.all(10),
                child: FutureBuilder<String>(
                  future: _getNickname(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(
                        child: Text(
                          snapshot.data ?? 'No nickname found',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Geri kalan içerik
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SectionTitle(title: 'Favourites'),
                      FavoriteMoviesGrid(userId: uid),
                      const SectionTitle(title: 'Notes'),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(uid)
                            .collection('notes')
                            .orderBy('timestamp', descending: true)
                            .limit(4)
                            .snapshots(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data!.docs.take(3);

                          return Container(
                            child: Column(
                              children: docs.map((doc) {
                                return Column(
                                  children: [
                                    ListTile(
                                      tileColor: Colors.white,
                                      title: Text(
                                        doc['movieName'] ?? 'Unknown Movie',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepPurple[700],
                                        ),
                                      ),
                                      subtitle: Text(
                                        (doc['content'] as String).length > 50
                                            ? '${(doc['content'] as String).substring(0, 50)}...'
                                            : doc['content'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      doc['movieName'] ?? 'Unknown Movie',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepPurple[700],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.close, color: Colors.deepPurple[700]),
                                                      onPressed: () => Navigator.of(context).pop(),
                                                    ),
                                                    Divider(color: Colors.deepPurple[200], thickness: 1),
                                                    const SizedBox(height: 8),
                                                    SingleChildScrollView(
                                                      child: Text(
                                                        doc['content'] ?? '',
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    if (doc['timestamp'] != null)
                                                      Text(
                                                        'Added: ${(doc['timestamp'] as Timestamp).toDate().toString().split('.')[0]}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const Divider(color: Colors.grey, thickness: 1, indent: 16, endIndent: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DashedLinePainter(),
          ),
        ),
      ],
    );
  }
}

// Kesikli çizgi için CustomPainter ekleyelim
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FavoriteMoviesGrid extends StatelessWidget {
  final String userId;

  const FavoriteMoviesGrid({super.key, required this.userId});

  Future<String?> fetchMoviePoster(String movieName) async {
    final query = Uri.encodeComponent(movieName);
    final url =
        'https://api.themoviedb.org/3/search/movie?api_key=${EnvConfig.tmdbApiKey}&query=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final posterPath = data['results'][0]['poster_path'];
          return 'https://image.tmdb.org/t/p/w200$posterPath';
        }
      }
    } catch (e) {
      print('Error fetching poster: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('favourites')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No favourite movies yet')),
          );
        }

        final favouriteMovies = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.only(top: 2, left: 8, right: 8, bottom: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2/3,
            ),
            itemCount: favouriteMovies.length,
            itemBuilder: (context, index) {
              final movie = favouriteMovies[index];
              final movieName = movie['name'] ?? 'Unknown Movie';

              return FutureBuilder<String?>(
                future: fetchMoviePoster(movieName),
                builder: (context, posterSnapshot) {
                  if (posterSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final posterUrl = posterSnapshot.data;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.deepPurple[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: posterUrl != null
                              ? Image.network(
                                  posterUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : const Center(child: Text('No Poster')),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            movieName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
