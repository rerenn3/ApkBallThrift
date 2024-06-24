import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_post_screen.dart';
import 'sign_in_screen.dart';
import 'setting_screen.dart';
import 'profile_screen.dart';
import 'detail_screen.dart'; // Import DetailScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  String? searchQuery; // Variable for search query

  @override
  void initState() {
    super.initState();
    setUserEmail();
  }

  Future<void> setUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? email = await getUserEmail(user.uid);
      setState(() {
        userEmail = email;
      });
    }
  }

  Future<void> signOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'];
        return address;
      } else {
        return 'Unknown Location';
      }
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown Location';
    }
  }

  Future<String?> getUserEmail(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc['email'];
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                signOut(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Update search query
                });
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blue[50], // Background color
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Terjadi kesalahan.'));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://cdn3.iconfinder.com/data/icons/laundry-137/64/Clothes_clothing_Cloth_tshirt_shirt_Clothes_hanger_clothes_on_hangers_Laundry_icon_outline_illustration-1024.png',
                            height: 200,
                          ),
                          const SizedBox(height: 20),
                          const Text('Tidak ada postingan tersedia'),
                        ],
                      ),
                    );
                  }

                  // Filter posts based on search query
                  var filteredPosts = snapshot.data!.docs.where((post) {
                    var data = post.data() as Map<String, dynamic>;
                    var text = data['text'] as String? ?? '';
                    return searchQuery == null || searchQuery!.isEmpty
                        ? true
                        : text.toLowerCase().contains(searchQuery!);
                  }).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      var post = filteredPosts[index];
                      var data = post.data() as Map<String, dynamic>;
                      var postTime = data['timestamp'] as Timestamp;
                      var date = postTime.toDate();
                      var formattedDate =
                          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
                      var imageUrl = data['image_url'] as String?;
                      var text = data['text'] as String? ?? '';
                      var location = data['location'] as GeoPoint?;
                      var userId = data['userId'] as String?;

                      return FutureBuilder<String?>(
                        future: getUserEmail(userId ?? ''),
                        builder: (context, userSnapshot) {
                          var userEmail = userSnapshot.data ?? 'Unknown User';
                          var locationString = '';

                          if (location != null) {
                            locationString =
                            '${location.latitude}, ${location.longitude}';
                          }

                          return GestureDetector(
                            onTap: () {
                              // Check if location is not null before navigating to DetailScreen
                              if (location != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      imageUrl: imageUrl ?? '',
                                      caption: text,
                                      geoPoint: location,
                                      postId: post.id,
                                    ),
                                  ),
                                );
                              } else {
                                // Handle if location is null
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Location is not available')),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (imageUrl != null)
                                      Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (location != null)
                                      FutureBuilder(
                                        future: getAddress(
                                            location.latitude, location.longitude),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text: 'Location: ',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${snapshot.data}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            return Container();
                                          }
                                        },
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      text,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Post By: $userEmail',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.lightBlueAccent,
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}