import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AmbulanceBookingScreen extends StatefulWidget {
  @override
  _AmbulanceBookingScreenState createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _loading = false;
  String _bookingInfo = "Searching for hospitals...";
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _hospitals = [];
  Map<String, dynamic>? _selectedHospital;
  bool _isLocationLoaded = false;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  /// ✅ Starts continuous location updates
  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _isLocationLoaded = true;
      });

      // ✅ Fetch nearby hospitals after getting position
      _findNearbyHospitals();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    });
  }

  /// ✅ Finds the nearest hospitals and auto-books the closest one
  Future<void> _findNearbyHospitals() async {
    if (_currentPosition == null) return;

    double lat = _currentPosition!.latitude;
    double lon = _currentPosition!.longitude;
    final int radius = 5000;

    final query = """
[out:json];
node(around:$radius,$lat,$lon)["amenity"="hospital"];
out body;
    """;

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {"Content-Type": "text/plain"},
        body: query,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List<dynamic>;

        if (elements.isEmpty) {
          setState(() {
            _bookingInfo = "No hospitals found nearby!";
          });
          return;
        }

        setState(() {
          _hospitals = elements
              .map((e) => {
                    "name": e['tags']?['name'] ?? 'Unnamed Hospital',
                    "lat": e['lat'],
                    "lon": e['lon'],
                    "distance":
                        _calculateDistance(lat, lon, e['lat'], e['lon']),
                  })
              .toList();
        });

        // ✅ Sort hospitals by nearest distance
        if (_hospitals.isNotEmpty) {
          _hospitals.sort((a, b) => a['distance'].compareTo(b['distance']));
          _selectHospital(_hospitals.first); // Auto-select nearest hospital
          _bookAmbulance(); // Auto-book for the nearest hospital
        }
      } else {
        setState(() {
          _bookingInfo = "Error fetching hospitals. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _bookingInfo = "Error fetching hospitals. Please try again.";
      });
    }
  }

  /// ✅ Calculates distance between two coordinates
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// ✅ Selects a hospital (including auto-booked one)
  void _selectHospital(Map<String, dynamic> hospital) {
    setState(() {
      _selectedHospital = hospital;
      _bookingInfo = "Selected Hospital: ${hospital['name']}";
    });

    _mapController.move(LatLng(hospital['lat'], hospital['lon']), 16.0);
  }

  /// ✅ Quick emergency ambulance booking
  bool _ambulanceBooked = false; // Add this flag at the top

  /// ✅ Quick emergency ambulance booking (only once)
  Future<void> _bookAmbulance() async {
    if (_selectedHospital == null || _loading || _ambulanceBooked) return;

    setState(() {
      _loading = true;
      _bookingInfo = "Booking ambulance...";
    });

    String hospitalName = _selectedHospital!['name'];
    double hospitalLat = _selectedHospital!['lat'];
    double hospitalLon = _selectedHospital!['lon'];

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    setState(() {
      _ambulanceBooked = true; // ✅ Prevent multiple bookings
      _bookingInfo =
          "🚑 Ambulance Booked!\nHospital: $hospitalName\nLocation: ($hospitalLat, $hospitalLon)\nETA: 5 mins";
      _loading = false;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = _isLocationLoaded && _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629); // Default location (India)

    return Scaffold(
      appBar: AppBar(title: const Text('🚨 Emergency Ambulance Booking')),
      body: Column(
        children: [
          // ✅ Map Display
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: initialCenter, // ✅ Fixed
                zoom: 15.0, // ✅ Fixed
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                if (_isLocationLoaded && _currentPosition != null)
                  MarkerLayer(
                    markers: [
                      // ✅ User's Location Marker
                      Marker(
                        point: LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        width: 40,
                        height: 40,
                        builder: (context) => const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                      // ✅ Hospital Markers
                      for (var hospital in _hospitals)
                        Marker(
                          point: LatLng(hospital['lat'], hospital['lon']),
                          width: 50,
                          height: 50,
                          builder: (context) => GestureDetector(
                            onTap: () {
                              _selectHospital(hospital);
                            },
                            child: Icon(
                              Icons.local_hospital,
                              color: _selectedHospital == hospital
                                  ? Colors.red
                                  : Colors.green,
                              size: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          // ✅ Booking Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _bookingInfo,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _bookAmbulance,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 40)),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('🚨 Emergency SOS',
                          style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//CAN YOU IMPROVE THE UI OF THIS PAGE WITHOUT CHANGING ANY OF MY LOGIC OR CODE AND MAKE IT MORE USER INTUITIVE AND ATTRACTIVE
