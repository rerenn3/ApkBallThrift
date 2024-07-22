import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailScreen extends StatefulWidget {
  final String imageUrl;
  final String caption;
  final GeoPoint geoPoint;
  final String postId;

  const DetailScreen({
    required this.imageUrl,
    required this.caption,
    required this.geoPoint,
    required this.postId,
    Key? key,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? address;
  String _description = ''; // For storing description from Firestore

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _fetchDescription(); // Fetch description from Firestore
  }

  Future<void> _fetchAddress() async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${widget.geoPoint.latitude}&lon=${widget.geoPoint.longitude}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          address = data['display_name'];
        });
      } else {
        setState(() {
          address = 'Unknown Location';
        });
      }
    } catch (e) {
      setState(() {
        address = 'Unknown Location';
      });
      print('Error fetching address: $e');
    }
  }

  Future<void> _fetchDescription() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      if (doc.exists) {
        setState(() {
          _description = doc.data()?['description'] ?? widget.caption;
        });
      }
    } catch (e) {
      print('Error fetching description: $e');
    }
  }

  Future<void> _saveDescription(String description) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'description': description,
      });
      setState(() {
        _description = description;
      });
    } catch (e) {
      print('Error saving description: $e');
    }
  }

  void _openInMaps() async {
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.geoPoint.latitude},${widget.geoPoint.longitude}');
    if (await canLaunch(googleMapsUrl.toString())) {
      await launch(googleMapsUrl.toString());
    } else {
      throw 'Could not open $googleMapsUrl';
    }
  }

  void _showEditDescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _description);
        return AlertDialog(
          title: const Text('Edit Deskripsi'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Tambahkan deskripsi...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _saveDescription(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                child: Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.caption,
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (address != null)
                        Text(
                          'Location: $address',
                          style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                        )
                      else
                        const CircularProgressIndicator(),
                      const SizedBox(height: 16.0),
                      Text(
                        'Deskripsi: $_description',
                        style: const TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _openInMaps,
                child: const Text('Tampilkan di Peta'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDescriptionDialog,
        child: const Icon(Icons.edit),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
