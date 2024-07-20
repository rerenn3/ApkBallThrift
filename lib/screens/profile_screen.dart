import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user is signed in.');
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics/${user.uid}.jpg');

        // Upload image to Firebase Storage
        await storageRef.putFile(_image!);
        final downloadUrl = await storageRef.getDownloadURL();

        // Update user's photo URL in Firebase Auth
        await user.updatePhotoURL(downloadUrl);
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully.'),
          ),
        );
      } catch (error) {
        print('Error uploading profile picture: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading profile picture. Please try again later.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('No user is signed in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : NetworkImage(user.photoURL ?? 'https://via.placeholder.com/150') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                Text(
                  user.displayName ?? 'No display name',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'No email',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.star, size: 50, color: Colors.yellow),
                Icon(Icons.star, size: 50, color: Colors.yellow),
                Icon(Icons.star, size: 50, color: Colors.yellow),
                Icon(Icons.star, size: 50, color: Colors.yellow),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Profile Settings'),
              onTap: () async {
                final updatedName = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );

                if (updatedName != null) {
                  setState(() {
                    // Refresh the display name with the updated name
                    FirebaseAuth.instance.currentUser?.updateProfile(displayName: updatedName);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Privacy'),
              onTap: () {
                // Implement privacy settings navigation
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications '),
              onTap: () {
                // Implement notifications settings navigation
              },
            ),
          ],
        ),
      ),
    );
  }
}
