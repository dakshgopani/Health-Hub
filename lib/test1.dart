import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Geolocator for location fetching
import 'package:flutter_map/flutter_map.dart'; // Flutter Map for OpenStreetMap
import 'package:latlong2/latlong.dart'; // LatLong for map coordinates
import 'package:geocoding/geocoding.dart'; // Geocoding for location name
import 'welcome_screen.dart'; // Import your WelcomeScreen

class ProfileScreen extends StatefulWidget {
  final String userId; // Pass the user's ID for Firestore operations
  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  LatLng? _currentLatLng; // To store user's current coordinates
  String _locationName = ''; // To store the location name

  // All the location details
  String buildingName = '';
  String roadName = '';
  String subLocality = '';
  String locality = '';
  String administrativeArea = '';
  String country = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user data from Firestore
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        _nameController.text = userData?['name'] ?? ''; // Pre-fill the name

        // Fetch and set the location from Firestore
        if (userData?['location'] != null) {
          _currentLatLng = LatLng(userData?['location']['latitude'], userData?['location']['longitude']);
          _getLocationNameFromCoordinates(_currentLatLng!); // Fetch location name based on saved coordinates
        }
      }
    } catch (error) {
      print('Error loading user profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to fetch the address of the manually tapped location
  Future<void> _getLocationNameFromCoordinates(LatLng coordinates) async {
    try {
      // Fetch placemarks (address components) from coordinates
      List<Placemark> placemarks = await GeocodingPlatform.instance!.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          // Extract detailed address information
          buildingName = placemarks[0].name ?? 'N/A'; // This may contain the building name
          roadName = placemarks[0].thoroughfare ?? 'N/A'; // This is the road/street name
          subLocality = placemarks[0].subLocality ?? 'N/A'; // This is a more detailed area like a neighborhood
          locality = placemarks[0].locality ?? 'N/A'; // City name
          administrativeArea = placemarks[0].administrativeArea ?? 'N/A'; // State/Region
          country = placemarks[0].country ?? 'N/A'; // Country

          // Format the location as a more detailed string
          _locationName = '$buildingName, $roadName, $subLocality, $locality, $administrativeArea, $country';

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

  // Function to save location details to Firestore
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
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

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

  // Save updated profile data to Firestore
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Ensure that all the location fields are updated, not just latitude and longitude
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': _nameController.text,
        'location': {
          'buildingName': buildingName,
          'roadName': roadName,
          'subLocality': subLocality,
          'locality': locality,
          'administrativeArea': administrativeArea,
          'country': country,
          'latitude': _currentLatLng!.latitude,
          'longitude': _currentLatLng!.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      print('Error saving profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign out user
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(), // Navigate to the Welcome Screen
        ),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Map Section to change location
            _currentLatLng == null
                ? const Center(child: Text('Fetching location...'))
                : Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: _currentLatLng!, // Set initial center of the map
                  zoom: 15, // Set zoom level
                  onTap: (tapPosition, point) {
                    setState(() {
                      _currentLatLng = point;
                      _getLocationNameFromCoordinates(point); // Get address for tapped location
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
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
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut, // Sign out button
              child: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Red button for sign out
            ),
          ],
        ),
      ),
    );
  }
}
