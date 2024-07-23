import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_screen.dart';  // Pastikan ini diimport

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar('Harap lengkapi semua kolom');
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnackbar('Email tidak valid');
      return;
    }

    if (password.length < 6) {
      _showSnackbar('Kata sandi harus lebih dari 6 karakter');
      return;
    }

    setState(() {
      _message = 'Memproses pendaftaran...';
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
        });

        setState(() {
          _message = 'Pendaftaran Berhasil. Silakan cek email untuk verifikasi.';
        });

        // Menunggu beberapa detik sebelum mengalihkan ke halaman SignIn
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SignInScreen(), // Arahkan ke halaman SignIn
            ),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        setState(() {
          _message = 'Kata sandi terlalu lemah';
        });
      } else if (e.code == 'email-already-in-use') {
        setState(() {
          _message = 'Email sudah digunakan';
        });
      }
    } catch (error) {
      print("Error during sign up: $error");
      setState(() {
        _message = 'Terjadi kesalahan saat mendaftar. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BallThrift'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32.0),
            Center(
              child: Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'NAMA LENGKAP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'EMAIL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'SANDI',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _signUp,
                child: const Text('Daftar'),
              ),
            ),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('Pendaftaran Berhasil') ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
