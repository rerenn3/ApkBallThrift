import 'package:fasum/screens/edit_profile_screen.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

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
            onPressed: () => Navigator.of(context).pop(true),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Account'),
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.facebook),
            title: Text('Facebook'),
            onTap: () {
              // Aksi untuk membuka pengaturan Facebook
            },
          ),
          ListTile(
            title: Text('Notifications'),
          ),
          SwitchListTile(
            title: Text('Notifications'),
            value: true, // Ganti sesuai status notifikasi Anda
            onChanged: (bool value) {
              // Aksi untuk mengubah status notifikasi
            },
          ),
          SwitchListTile(
            title: Text('App notification'),
            value: true, // Ganti sesuai status notifikasi aplikasi Anda
            onChanged: (bool value) {
              // Aksi untuk mengubah status notifikasi aplikasi
            },
          ),
          ListTile(
            title: Text('More'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            onTap: () {
              // Aksi untuk membuka pengaturan bahasa
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text('Country'),
            onTap: () {
              // Aksi untuk membuka pengaturan negara
            },
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => signOut(context),
          ),
        ],
      ),
    );
  }
}
