import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';


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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Emergency Ambulance', style: AppTextStyles.whiteHeading),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        centerTitle: true,
        leading: Icon(Icons.local_hospital, size: 28, color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('Emergency Services', style: AppTextStyles.heading),
                  content: Text(
                    'This app automatically finds the nearest hospital and books an ambulance for you in case of emergency.',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.deepPurple,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Map Display
          FlutterMap(
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
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightPurple.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: AppColors.deepPurple,
                          size: 30,
                        ),
                      ),
                    ),
                    // ✅ Hospital Markers - FIXED ALIGNMENT
                    for (var hospital in _hospitals)
                      Marker(
                        point: LatLng(hospital['lat'], hospital['lon']),
                        width: 50,
                        height: 50,
                        // Anchor the marker at the center of the icon
                        anchorPos: AnchorPos.align(AnchorAlign.center),
                        builder: (context) => GestureDetector(
                          onTap: () {
                            _selectHospital(hospital);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _selectedHospital == hospital
                                        ? AppColors.deepPurple.withOpacity(0.2)
                                        : AppColors.lightPurple.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Hospital icon
                                Icon(
                                  Icons.add_box,
                                  color: _selectedHospital == hospital
                                      ? Colors.red
                                      : AppColors.deepPurple,
                                  size: 30,
                                ),
                                // Selected indicator
                                if (_selectedHospital == hospital)
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Selected',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontFamily: 'Raleway',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Location button
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: AppColors.deepPurple),
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    15.0,
                  );
                }
              },
            ),
          ),

          // Hospital list button
          Positioned(
            right: 16,
            top: 70,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.list, color: AppColors.deepPurple),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nearby Hospitals',
                          style: AppTextStyles.heading,
                        ),
                        SizedBox(height: 8),
                        Divider(color: AppColors.veryLightPurple),
                        if (_hospitals.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No hospitals found nearby',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _hospitals.length,
                              itemBuilder: (context, index) {
                                final hospital = _hospitals[index];
                                final isSelected = _selectedHospital == hospital;
                                final distance = (hospital['distance'] / 1000).toStringAsFixed(1);

                                return ListTile(
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.red.withOpacity(0.1)
                                          : AppColors.veryLightPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_box,
                                      color: isSelected ? Colors.red : AppColors.deepPurple,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    hospital['name'],
                                    style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$distance km away',
                                    style: TextStyle(
                                      fontFamily: 'Raleway',
                                      color: Colors.black54,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Chip(
                                    label: Text(
                                      'Selected',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                  )
                                      : null,
                                  onTap: () {
                                    _selectHospital(hospital);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ Booking Controls - Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ambulanceBooked)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundPurple,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.veryLightPurple),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Ambulance Booked!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                  color: AppColors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hospital:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Raleway',
                                      ),
                                    ),
                                    Text(
                                      _selectedHospital?['name'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightPurple,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: AppColors.deepPurple),
                                    SizedBox(width: 4),
                                    Text(
                                      'ETA: 5 mins',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Raleway',
                                        color: AppColors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedHospital != null
                                    ? Icons.location_on
                                    : Icons.search,
                                color: _selectedHospital != null
                                    ? AppColors.deepPurple
                                    : AppColors.lightPurple,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _bookingInfo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Raleway',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _bookAmbulance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 56),
                            elevation: 4,
                          ),
                          child: _loading
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Booking Ambulance...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emergency, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'EMERGENCY SOS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (!_isLocationLoaded)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.deepPurple),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Raleway',
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}