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
  TextEditingController _descriptionController = TextEditingController();
  String _editedDescription = ''; // Added to store edited description
  bool _editingMode = false; // Track whether in editing mode or not

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _descriptionController.text = widget.caption; // Initialize controller with current caption
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  void _openInMaps() async {
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.geoPoint.latitude},${widget.geoPoint.longitude}');
    try {
      await launch(googleMapsUrl.toString());
    } catch (e) {
      throw 'Could not open $googleMapsUrl';
    }
  }

  void _toggleEditingMode() {
    setState(() {
      _editingMode = true; // Enable editing mode
    });
  }

  void _saveDescription() {
    setState(() {
      _editedDescription = _descriptionController.text; // Update edited description
      _editingMode = false; // Disable editing mode after saving
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Postingan'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.caption,
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 16.0),
            if (address != null)
              Text(
                'Location: $address',
                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16.0),
            if (_editingMode)
              TextField(
                controller: _descriptionController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Tambahkan deskripsi...',
                  border: OutlineInputBorder(),
                ),
              ),
            if (!_editingMode && _editedDescription.isNotEmpty)
              Text(
                'Deskripsi: $_editedDescription',
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_editingMode && _editedDescription.isEmpty)
                  ElevatedButton(
                    onPressed: _toggleEditingMode,
                    child: Text('Tambah Deskripsi'),
                  ),
                if (_editingMode)
                  ElevatedButton(
                    onPressed: _saveDescription,
                    child: Text('Simpan'),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _openInMaps,
              child: const Text('Tampilkan di Peta '),
            ),
          ],
        ),
      ),
    );
  }
}
