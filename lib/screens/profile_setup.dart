import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'home/home_page.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userId;

  const ProfileSetupPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  LatLng? _currentLatLng;
  String _locationName = '';

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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });

      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          String buildingName = placemarks[0].name ?? 'N/A';
          String roadName = placemarks[0].thoroughfare ?? 'N/A';
          String subLocality = placemarks[0].subLocality ?? 'N/A';
          String locality = placemarks[0].locality ?? 'N/A';
          String administrativeArea = placemarks[0].administrativeArea ?? 'N/A';
          String country = placemarks[0].country ?? 'N/A';

          _locationName =
              '$buildingName, $roadName, $subLocality, $locality, $administrativeArea, $country';

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
      _showSnackBar('Error fetching location: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline, // Icon indicating info
              color: Colors.white,
            ),
            const SizedBox(width: 8), // Space between the icon and text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Make text bold for emphasis
                  fontSize: 16, // Slightly larger font size
                  fontFamily: 'Raleway',
                ),
                overflow: TextOverflow.ellipsis, // Prevent text overflow
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF432C81),
        // Deep purple background
        behavior: SnackBarBehavior.floating,
        // Change to floating behavior
        duration: const Duration(seconds: 3),
        // Duration for the SnackBar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        margin: const EdgeInsets.all(16),
        // Margin around the SnackBar
        elevation: 6, // Slight elevation for a 3D effect
      ),
    );
  }

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

      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'name': 'New User',
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

      _showSnackBar('Location updated successfully');
    } catch (error) {
      _showSnackBar('Error saving location: $error');
    }
  }

  Future<void> _getLocationNameFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          String buildingName = placemarks[0].name ?? 'N/A';
          String roadName = placemarks[0].thoroughfare ?? 'N/A';
          String subLocality = placemarks[0].subLocality ?? 'N/A';
          String locality = placemarks[0].locality ?? 'N/A';
          String administrativeArea = placemarks[0].administrativeArea ?? 'N/A';
          String country = placemarks[0].country ?? 'N/A';

          _locationName =
              '$buildingName, $roadName, $subLocality, $locality, $administrativeArea, $country';

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
      _showSnackBar('Error fetching location: $error');
    }
  }

  Future<void> completeProfile() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (_currentLatLng == null) {
      _showSnackBar('Please fetch your location');
      await _getCurrentLocation();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      await userRef.set(
        {
          'name': _nameController.text,
          'isProfileComplete': true,
          'email': FirebaseAuth.instance.currentUser?.email,
          'location': {
            'latitude': _currentLatLng!.latitude,
            'longitude': _currentLatLng!.longitude,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            userId: FirebaseAuth.instance.currentUser!.uid,
            userName: _nameController.text,
            userEmail: FirebaseAuth.instance.currentUser!.email ?? "Email",
          ),
        ),
      );
    } catch (error) {
      _showSnackBar('Error saving profile: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }

    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Setup',
          style:
              AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPurple,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_pin_circle,
                        size: 60,
                        color: AppColors.deepPurple,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Complete Your Profile',
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Let us know who you are',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPurple,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Name Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPurple,
                          fontFamily: 'Raleway',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          filled: true,
                          fillColor: AppColors.veryLightPurple.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.lightPurple,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Location Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPurple,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(
                              Icons.my_location,
                              size: 18,
                              color: AppColors.deepPurple,
                            ),
                            label: const Text(
                              'Refresh',
                              style: TextStyle(
                                color: AppColors.deepPurple,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  AppColors.veryLightPurple.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.veryLightPurple,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepPurple.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _currentLatLng == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.deepPurple,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Fetching your location...',
                                      style: TextStyle(
                                        color: AppColors.textPurple,
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FlutterMap(
                                options: MapOptions(
                                  center: _currentLatLng!,
                                  zoom: 15,
                                  onTap: (tapPosition, point) {
                                    setState(() {
                                      _currentLatLng = point;
                                      _getLocationNameFromCoordinates(point);
                                    });
                                  },
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
                                        point: _currentLatLng!,
                                        builder: (context) => Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.deepPurple
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: AppColors.deepPurple,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.veryLightPurple,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.textPurple,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Location Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPurple,
                                    fontFamily: 'Raleway',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentLatLng == null
                                  ? 'No location selected'
                                  : _locationName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_currentLatLng != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates: (${_currentLatLng!.latitude.toStringAsFixed(4)}, ${_currentLatLng!.longitude.toStringAsFixed(4)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.deepPurple,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Complete Profile Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.deepPurple.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Complete Profile',
                                style: AppTextStyles.whiteHeading.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
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
