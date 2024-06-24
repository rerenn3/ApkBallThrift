import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  MapScreen({required this.onLocationSelected});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              if (_selectedLocation != null) {
                widget.onLocationSelected(_selectedLocation!);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pilih lokasi terlebih dahulu')),
                );
              }
            },
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-2.9761, 104.7759),
          zoom: 12,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: (position) {
          setState(() {
            _selectedLocation = position;
          });
        },
        markers: _selectedLocation == null
            ? Set()
            : {
          Marker(
            markerId: MarkerId('selected-location'),
            position: _selectedLocation!,
          ),
        },
      ),
    );
  }
}
