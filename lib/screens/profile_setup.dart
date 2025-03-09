import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator for location fetching
import 'package:flutter_map/flutter_map.dart'; // Flutter Map for OpenStreetMap
import 'package:latlong2/latlong.dart'; // LatLong for map coordinates
import 'package:geocoding/geocoding.dart'; // Geocoding for location name
import 'home/home_page.dart'; // Ensure HomePage is imported

class ProfileSetupPage extends StatefulWidget {
  final String userId;

  const ProfileSetupPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false; // To handle loading state
  LatLng? _currentLatLng; // To store user's current coordinates
  String _locationName = ''; // To store the location name

  // Function to fetch the user's current location and location name
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });

      // Use geocoding to get the address based on the coordinates
      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          // Extract detailed address information
          String buildingName =
              placemarks[0].name ?? 'N/A'; // This may contain the building name
          String roadName = placemarks[0].thoroughfare ??
              'N/A'; // This is the road/street name
          String subLocality = placemarks[0].subLocality ??
              'N/A'; // This is a more detailed area like a neighborhood
          String locality = placemarks[0].locality ?? 'N/A'; // City name
          String administrativeArea =
              placemarks[0].administrativeArea ?? 'N/A'; // State/Region
          String country = placemarks[0].country ?? 'N/A'; // Country

          // Format the location as a more detailed string
          _locationName =
              '$buildingName, $roadName, $subLocality, $locality, $administrativeArea, $country';

          // Save each location detail separately in Firestore
          _saveLocationToFirestore(
            buildingName,
            roadName,
            subLocality,
            locality,
            administrativeArea,
            country,
            position.latitude,
            position.longitude,
          );
        });
      } else {
        setState(() {
          _locationName = 'Location not found';
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $error')),
      );
    }
  }

// Function to save location details to Firestore
// Save location details if the document exists or create a new one if it doesn't
  Future<void> _saveLocationToFirestore(
    String buildingName,
    String roadName,
    String subLocality,
    String locality,
    String administrativeArea,
    String country,
    double latitude,
    double longitude,
  ) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      // Fetch the document
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Document doesn't exist, create a new one
        await userRef.set({
          'name': 'New User', // or get it from some input
          'location': {
            'buildingName': buildingName,
            'roadName': roadName,
            'subLocality': subLocality,
            'locality': locality,
            'administrativeArea': administrativeArea,
            'country': country,
            'latitude': latitude,
            'longitude': longitude,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Document exists, update the existing one
        await userRef.update({
          'location': {
            'buildingName': buildingName,
            'roadName': roadName,
            'subLocality': subLocality,
            'locality': locality,
            'administrativeArea': administrativeArea,
            'country': country,
            'latitude': latitude,
            'longitude': longitude,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $error')),
      );
    }
  }

  // Function to fetch the address of the manually tapped location
  Future<void> _getLocationNameFromCoordinates(LatLng coordinates) async {
    try {
      // Fetch placemarks (address components) from coordinates
      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          // Extract detailed address information
          String buildingName =
              placemarks[0].name ?? 'N/A'; // This may contain the building name
          String roadName = placemarks[0].thoroughfare ??
              'N/A'; // This is the road/street name
          String subLocality = placemarks[0].subLocality ??
              'N/A'; // This is a more detailed area like a neighborhood
          String locality = placemarks[0].locality ?? 'N/A'; // City name
          String administrativeArea =
              placemarks[0].administrativeArea ?? 'N/A'; // State/Region
          String country = placemarks[0].country ?? 'N/A'; // Country

          // Format the location as a more detailed string
          _locationName =
              '$buildingName, $roadName, $subLocality, $locality, $administrativeArea, $country';

          // Save each location detail separately in Firestore
          _saveLocationToFirestore(
            buildingName,
            roadName,
            subLocality,
            locality,
            administrativeArea,
            country,
            coordinates.latitude,
            coordinates.longitude,
          );
        });
      } else {
        setState(() {
          _locationName = 'Location not found';
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $error')),
      );
    }
  }

  // Function to complete the profile setup
  Future<void> completeProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (_currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch your location')),
      );
      await _getCurrentLocation();
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      // Update user profile data in Firestore
      await userRef.set(
        {
          'name': _nameController.text,
          'isProfileComplete': true, // Mark profile as complete
          'email': FirebaseAuth.instance.currentUser?.email,
          'location': {
            'latitude': _currentLatLng!.latitude,
            'longitude': _currentLatLng!.longitude,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // Use merge to avoid overwriting existing data
      );

      // Navigate to HomePage after profile setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            // userId: widget.userId, // Pass userId to HomePage
            userId: FirebaseAuth.instance.currentUser!.uid,
            userName: FirebaseAuth.instance.currentUser!.displayName ?? "User",
            userEmail: FirebaseAuth.instance.currentUser!.email ?? "Email",
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch user's location on page load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Name input field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Map Section
                  Expanded(
                    child: _currentLatLng == null
                        ? const Center(
                            child: Text(
                              'Fetching your location...',
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              center: _currentLatLng!,
                              // Set the initial center of the map
                              zoom: 15,
                              // Set the initial zoom level
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _currentLatLng = point;
                                  _getLocationNameFromCoordinates(
                                      point); // Get address for the tapped location
                                });
                              },
                            ),
                            children: [
                              // Tile Layer for OpenStreetMap
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              // Marker Layer
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentLatLng!,
                                    builder: (context) => const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    _currentLatLng == null
                        ? 'No location selected'
                        : 'Location: $_locationName (${_currentLatLng!.latitude.toStringAsFixed(4)}, ${_currentLatLng!.longitude.toStringAsFixed(4)})',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Loading indicator or complete profile button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: completeProfile,
                          child: const Text('Complete Profile'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
