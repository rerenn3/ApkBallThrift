import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';
import 'map_screen.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  TextEditingController _postTextController = TextEditingController();
  String? _imageUrl;
  XFile? _image;
  final User? user = FirebaseAuth.instance.currentUser;
  LatLng? _selectedLocation;
  String _locationMessage = "";
  bool _isPosting = false; // State to prevent multiple postings

  Future<void> _getImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = image;
      });

      if (!kIsWeb) {
        String? imageUrl = await _uploadImage(image);
        setState(() {
          _imageUrl = imageUrl;
        });
      } else {
        setState(() {
          _imageUrl = image.path;
        });
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return '${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      } else {
        return 'Lokasi Tidak Dikenal';
      }
    } catch (e) {
      print('Error fetching address: $e');
      return 'Lokasi Tidak Dikenal';
    }
  }

  Future<void> _postContent() async {
    if (_isPosting) {
      // Prevent multiple postings
      return;
    }

    if (_postTextController.text.isNotEmpty && _image != null) {
      _isPosting = true; // Set posting state to true

      if (_imageUrl == null) {
        _imageUrl = await _uploadImage(_image!);
      }
      if (_imageUrl != null) {
        try {
          await FirebaseFirestore.instance.collection('posts').add({
            'text': _postTextController.text,
            'image_url': _imageUrl,
            'timestamp': Timestamp.now(),
            'username': user?.displayName ?? 'Anonim',
            'userId': user?.uid,
            'location': _selectedLocation != null
                ? GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude)
                : null,
          });

          // Navigate to HomeScreen after successful posting
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } catch (error) {
          print('Error saving post: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan postingan. Silakan coba lagi.'),
            ),
          );
        } finally {
          _isPosting = false; // Reset posting state
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah gambar. Silakan coba lagi.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan tulis postingan dan pilih gambar.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Postingan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _getImageFromCamera,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: _image != null
                    ? kIsWeb
                    ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(_image!.path),
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.grey[400],
                ),
                alignment: Alignment.center,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _postTextController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Tulis postingan Anda di sini...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_locationMessage),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            onLocationSelected: (location) {
                              setState(() {
                                _selectedLocation = location;
                                _locationMessage =
                                'Latitude: ${location.latitude}, Longitude: ${location.longitude}';
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Pilih Lokasi di Peta'),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedLocation != null)
                    ElevatedButton(
                      onPressed: () async {
                        if (_selectedLocation != null) {
                          Uri googleMapsUrl = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}');
                          try {
                            await launch(googleMapsUrl.toString());
                          } catch (e) {
                            throw 'Tidak dapat membuka $googleMapsUrl';
                          }
                        }
                      },
                      child: const Text('Tampilkan di Peta'),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _postContent,
              child: Text('Posting'),
            ),
          ],
        ),
      ),
    );
  }
}
