import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class HospitalLocator extends StatefulWidget {
  const HospitalLocator({super.key});

  @override
  State<HospitalLocator> createState() => _HospitalLocatorState();
}

class _HospitalLocatorState extends State<HospitalLocator>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LatLng? _currentLocation;
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = true;
  bool _panicMode = false;
  Set<String> _favoriteHospitals = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _setupAnimations();
    _getCurrentLocation();
    _loadFavorites();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController != null && _currentLocation != null) {
          _mapController.move(_currentLocation!, 15.0);
        }
      });

      await _fetchNearbyHospitals();
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _fetchNearbyHospitals() async {
    if (_currentLocation == null) return;

    double lat = _currentLocation!.latitude;
    double lon = _currentLocation!.longitude;

    String overpassUrl =
        "https://overpass-api.de/api/interpreter?data=[out:json];node[amenity=hospital](around:5000,$lat,$lon);out;";

    try {
      final response = await http.get(Uri.parse(overpassUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Hospital> hospitals = [];
        for (var element in data['elements']) {
          hospitals.add(Hospital(
            location: LatLng(element['lat'], element['lon']),
            name: element['tags']['name'] ?? 'Unknown Hospital',
            distance: Geolocator.distanceBetween(
              lat,
              lon,
              element['lat'],
              element['lon'],
            ),
          ));
        }

        hospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          _hospitals = hospitals;
          if (_panicMode && _hospitals.isNotEmpty) {
            _selectedHospital = _hospitals.first;
            _mapController.move(_selectedHospital!.location, 15.0);
          }
        });
      }
    } catch (e) {
      _showError("Error fetching hospitals: $e");
    }
  }

  void _openInOpenStreetMap(LatLng location) async {
    final Uri url = Uri.parse(
        'https://www.openstreetmap.org/directions?engine=graphhopper_foot&route=${_currentLocation!.latitude},${_currentLocation!.longitude};${location.latitude},${location.longitude}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showError('Could not open OpenStreetMap');
    }
  }

  void _togglePanicMode() {
    setState(() {
      _panicMode = !_panicMode;
      if (_panicMode && _hospitals.isNotEmpty) {
        _selectedHospital = _hospitals.first;
        _mapController.move(_selectedHospital!.location, 15.0);
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteHospitals = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> _toggleFavorite(Hospital hospital) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteHospitals.contains(hospital.name)) {
        _favoriteHospitals.remove(hospital.name);
      } else {
        _favoriteHospitals.add(hospital.name);
      }
    });
    await prefs.setStringList('favorites', _favoriteHospitals.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Find Nearest Hospitals",
          style:
              AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingScreen()
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation!,
                    zoom: 14.0,
                    onTap: (_, __) => setState(() => _selectedHospital = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 50,
                          height: 50,
                          builder: (context) => AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: const CustomLocationMarker(),
                              );
                            },
                          ),
                        ),
                        ..._hospitals.map(
                          (hospital) => Marker(
                            point: hospital.location,
                            width: 40,
                            height: 40,
                            builder: (context) => GestureDetector(
                              onTap: () {
                                setState(() => _selectedHospital = hospital);
                                _mapController.move(hospital.location, 15.0);
                              },
                              child: HospitalMarker(
                                isSelected: _selectedHospital == hospital,
                                distance: hospital.distance,
                                isFavorite:
                                    _favoriteHospitals.contains(hospital.name),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedHospital != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: HospitalInfoCard(
                      hospital: _selectedHospital!,
                      onDirectionsPressed: () =>
                          _openInOpenStreetMap(_selectedHospital!.location),
                      isFavorite:
                          _favoriteHospitals.contains(_selectedHospital!.name),
                      onFavoriteToggle: () =>
                          _toggleFavorite(_selectedHospital!),
                    ),
                  ),
                Positioned(
                  top: 100,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _togglePanicMode,
                    backgroundColor:
                        _panicMode ? Colors.red : Colors.deepPurple,
                    child: Icon(
                      _panicMode ? Icons.emergency : Icons.emergency_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: AnimatedFloatingActionButton(

        fabButtons: [
          FloatingActionButton(
            heroTag: "location",
            onPressed: _fetchNearbyHospitals,
            child: const Icon(Icons.my_location),
          ),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.refresh),
          ),
        ],
        colorStartAnimation: Colors.blue,
        colorEndAnimation: Colors.red,
        animatedIconData: AnimatedIcons.menu_close,

      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class Hospital {
  final LatLng location;
  final String name;
  final double distance;

  Hospital(
      {required this.location, required this.name, required this.distance});
}

class CustomLocationMarker extends StatelessWidget {
  const CustomLocationMarker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );
  }
}

class HospitalMarker extends StatelessWidget {
  final bool isSelected;
  final double distance;
  final bool isFavorite;

  const HospitalMarker({
    Key? key,
    this.isSelected = false,
    required this.distance,
    this.isFavorite = false,
  }) : super(key: key);

  Color _getMarkerColor() {
    if (isSelected) return Colors.blue;
    if (isFavorite) return Colors.purple;
    if (distance < 1000) return Colors.green;
    if (distance < 3000) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _getMarkerColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getMarkerColor().withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class HospitalInfoCard extends StatelessWidget {
  final Hospital hospital;
  final VoidCallback onDirectionsPressed;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const HospitalInfoCard({
    Key? key,
    required this.hospital,
    required this.onDirectionsPressed,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${(hospital.distance / 1000).toStringAsFixed(2)} km',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onDirectionsPressed,
              icon: const Icon(Icons.directions),
              label: const Text(
                'Get Directions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Finding nearby hospitals...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
