import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
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
  /// ✅ Starts continuous location updates
  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    // ADD THIS: Flag to track the first location update
    bool isFirstUpdate = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _isLocationLoaded = true;
      });

      // MODIFY THIS: Only move the map and fetch hospitals on the first update
      if (isFirstUpdate) {
        _findNearbyHospitals();
        _mapController.move(
            LatLng(position.latitude, position.longitude), 15.0);
        isFirstUpdate = false; // ADD THIS: Disable after first update
      }
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
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        title: const Text(
          'Emergency Ambulance',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
       actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Emergency Services',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.deepPurple,
                      )),
                  content: const Text(
                    'This app automatically finds the nearest hospital and books an ambulance for you in case of emergency.',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
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
                        child: const Icon(
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
                                        : AppColors.lightPurple
                                            .withOpacity(0.1),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
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
            child: SizedBox(
              height: 50, // Set height here
              width: 50,  // Set width to match aspect ratio
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.deepPurple),
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
          ),

          // Hospital list button
          Positioned(
            right: 16,
            top: 80,
            child: SizedBox(
              height: 50, // Increased for better touch target
              width: 50,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 6, // Added elevation for better UI
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18), // Softer corners
                ),
                child: const Icon(Icons.list, color: AppColors.deepPurple, size: 28),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Allow larger modal height
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.4, // Start at 40% height
                      minChildSize: 0.3, // Min height
                      maxChildSize: 0.8, // Max height
                      expand: false,
                      builder: (context, scrollController) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Nearby Hospitals',
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(color: AppColors.veryLightPurple),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _hospitals.isEmpty
                                  ? const Center(
                                child: Text(
                                  'No hospitals found nearby',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                controller: scrollController,
                                itemCount: _hospitals.length,
                                itemBuilder: (context, index) {
                                  final hospital = _hospitals[index];
                                  final isSelected = _selectedHospital == hospital;
                                  final distance = (hospital['distance'] / 1000)
                                      .toStringAsFixed(1);

                                  return Card(
                                    elevation: 3,
                                    margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isSelected
                                            ? Colors.red.withOpacity(0.2)
                                            : AppColors.veryLightPurple,
                                        child: Icon(
                                          Icons.local_hospital,
                                          color: isSelected
                                              ? Colors.red
                                              : AppColors.deepPurple,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        hospital['name'],
                                        style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$distance km away',
                                        style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Chip(
                                        label: const Text(
                                          'Selected',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontFamily: 'Raleway',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor:
                                        Colors.red.withOpacity(0.1),
                                      )
                                          : null,
                                      onTap: () {
                                        _selectHospital(hospital);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ambulanceBooked)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundPurple,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.veryLightPurple),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Ambulance Booked!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Raleway',
                                  color: AppColors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: const Text(
                                        'Hospital Name:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Raleway',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      _selectedHospital?['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightPurple,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16, color: AppColors.deepPurple),
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
                          padding: const EdgeInsets.all(12),
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _bookingInfo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Raleway',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _bookAmbulance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const Row(
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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
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
              child: const Center(
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
