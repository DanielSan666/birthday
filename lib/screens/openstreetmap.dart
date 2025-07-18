import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class Openstreetmap extends StatefulWidget {
  const Openstreetmap({super.key});

  @override
  State<Openstreetmap> createState() => _OpenstreetmapState();
}

class _OpenstreetmapState extends State<Openstreetmap> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _locationController = TextEditingController();
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (!await _checktheRequestPermissions()) return;

    _locationSubscription = _location.onLocationChanged.listen((
      LocationData locationData,
    ) {
      if (locationData.latitude != null &&
          locationData.longitude != null &&
          mounted) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchCoordinatesPoints(String location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          if (mounted) {
            setState(() {
              _destination = LatLng(lat, lon);
            });
          }
          await _fetchRoute();
        } else {
          errorMessage('Location not found. Please try another location.');
        }
      } else {
        errorMessage('Failed to fetch location. Please try again later.');
      }
    } catch (e) {
      errorMessage('An error occurred: ${e.toString()}');
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;

    try {
      final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/"
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        if (mounted) {
          _decodePolyline(geometry);
        }
      } else {
        errorMessage('Failed to fetch route. Please try again later.');
      }
    } catch (e) {
      errorMessage('Route calculation error: ${e.toString()}');
    }
  }

  void _decodePolyline(String encodePolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
      encodePolyline,
    );

    setState(() {
      _route =
          decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
    });
  }

  Future<bool> _checktheRequestPermissions() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return false;
      }
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return false;
      }
      return true;
    } catch (e) {
      errorMessage('Permission error: ${e.toString()}');
      return false;
    }
  }

  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    } else {
      errorMessage('Current location not found');
    }
  }

  void errorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('OpenStreetMap'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          isLoading || _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(0, 0),
                  initialZoom: 15,
                  minZoom: 0,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  CurrentLocationLayer(
                    style: LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        child: Icon(Icons.location_pin, color: Colors.white),
                      ),
                      markerSize: const Size(35, 35),
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),
                  if (_destination != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destination!,
                          width: 50,
                          height: 50,
                          child: Icon(Icons.location_pin, color: Colors.red),
                        ),
                      ],
                    ),
                  if (_currentLocation != null &&
                      _destination != null &&
                      _route.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route,
                          strokeWidth: 5,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter a location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      final location = _locationController.text.trim();
                      if (location.isNotEmpty) {
                        _fetchCoordinatesPoints(location);
                      }
                    },
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: _userCurrentLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, size: 30, color: Colors.white),
      ),
    );
  }
}
