import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Flutter Map for OpenStreetMap
import 'package:latlong2/latlong.dart'; // LatLong for map coordinates
import 'package:geocoding/geocoding.dart'; // Geocoding for location name
import 'auth/welcome_screen.dart';
import 'blood_donation/qr_code_scanner.dart';
import 'blood_donation/store_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; // Pass the user's ID for Firestore operations
  final String userName;

  const ProfileScreen({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  // final TextEditingController _UidController = TextEditingController();
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

  String? _localUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _localUserId = widget.userId;
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
        // _UidController.text = userData?['uid']??'';

        // Fetch and set the location from Firestore
        if (userData?['location'] != null) {
          _currentLatLng = LatLng(userData?['location']['latitude'],
              userData?['location']['longitude']);
          _getLocationNameFromCoordinates(
              _currentLatLng!); // Fetch location name based on saved coordinates
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
      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          // Extract detailed address information
          buildingName =
              placemarks[0].name ?? 'N/A'; // This may contain the building name
          roadName = placemarks[0].thoroughfare ??
              'N/A'; // This is the road/street name
          subLocality = placemarks[0].subLocality ??
              'N/A'; // This is a more detailed area like a neighborhood
          locality = placemarks[0].locality ?? 'N/A'; // City name
          administrativeArea =
              placemarks[0].administrativeArea ?? 'N/A'; // State/Region
          country = placemarks[0].country ?? 'N/A'; // Country

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
      setState(() {
        _localUserId = null;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WelcomeScreen(), // Navigate to the Welcome Screen
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
      appBar: AppBar(
        title: const Text('Profile Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              children: [
                _buildListTile(
                  icon: Icons.notifications,
                  iconColor: Colors.blue,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.privacy_tip,
                  iconColor: Colors.blue,
                  title: 'Privacy',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  title: 'Account',
                  subtitle: 'Manage your account settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageAccountScreen(
                          nameController: _nameController,
                          currentLatLng: _currentLatLng,
                          locationName: _locationName,
                          // Pass location name
                          onLocationTap: _getLocationNameFromCoordinates,
                          onSaveProfile: _saveProfile,
                          onSignOut: _signOut,
                          userId: widget.userId, // Pass the sign-out method
                        ),
                      ),
                    );
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.refresh,
                  iconColor: Colors.blue,
                  title: 'Reset App',
                  subtitle: 'Clear all app data and settings',
                  onTap: () {
                    // Handle reset app action
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.qr_code,
                  iconColor: Colors.blue,
                  title: 'Scan QR code',
                  subtitle:
                      'Scan your QR code to proceed with \nblood donation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanQRCodeScreen(
                          userId: widget.userId,
                          userName: widget.userName,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.local_grocery_store_rounded,
                  iconColor: Colors.blue,
                  title: 'MediMart',
                  subtitle:
                      'Explore the Store for all your \nessential medicines',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreScreen(
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(thickness: 1.0),
                _buildListTile(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: 'Log Out',
                  subtitle: null,
                  onTap: () {
                    // Handle log out action
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      onTap: onTap,
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text('Privacy settings coming soon!'),
      ),
    );
  }
}

class ManageAccountScreen extends StatefulWidget {
  final TextEditingController nameController;
  final LatLng? currentLatLng;
  final String locationName;
  final String userId;
  final Function(LatLng) onLocationTap;
  final VoidCallback onSaveProfile;
  final VoidCallback onSignOut;

  const ManageAccountScreen({
    Key? key,
    required this.nameController,
    required this.currentLatLng,
    required this.locationName,
    required this.userId,
    required this.onLocationTap,
    required this.onSaveProfile,
    required this.onSignOut,
  }) : super(key: key);

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  LatLng? _selectedLatLng;
  String _selectedLocationName = "";
  bool _isLoading = false;

  String buildingName = "";
  String roadName = "";
  String subLocality = "";
  String locality = "";
  String administrativeArea = "";
  String country = "";

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.currentLatLng;
    _selectedLocationName = widget.locationName;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user data from Firestore using the userId
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        // Extract data from Firestore
        var userData = userDoc.data() as Map<String, dynamic>;

        // Extract location fields from the Firestore document
        var location = userData['location'] ?? {};

        // Update the state with the location data
        setState(() {
          buildingName = location['buildingName'] ?? '';
          roadName = location['roadName'] ?? '';
          subLocality = location['subLocality'] ?? '';
          locality = location['locality'] ?? '';
          administrativeArea = location['administrativeArea'] ?? '';
          country = location['country'] ?? '';
          _selectedLatLng = LatLng(location['latitude'], location['longitude']);
          _selectedLocationName =
              "${location['buildingName']}, ${location['roadName']}, ${location['locality']}, ${location['administrativeArea']}, ${location['country']}";
        });
      } else {
        // Handle case where user data does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
      }
    } catch (error) {
      print('Error fetching user data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedLatLng = point;
    });

    // Fetch location details and update location name
    await _getLocationNameFromCoordinates(point);
  }

  Future<void> _getLocationNameFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks =
          await GeocodingPlatform.instance!.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];

        // Update the address fields with the fetched values
        setState(() {
          _selectedLocationName =
              "${placemark.name}, ${placemark.thoroughfare}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";

          // Use fetched values to update location fields
          buildingName = placemark.name ?? '';
          roadName = placemark.thoroughfare ?? '';
          subLocality = placemark.subLocality ?? '';
          locality = placemark.locality ?? '';
          administrativeArea = placemark.administrativeArea ?? '';
          country = placemark.country ?? '';
        });
      } else {
        setState(() {
          _selectedLocationName = "Unknown Location";
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $error')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location before saving.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': widget.nameController.text,
        'location': {
          'buildingName': buildingName,
          'roadName': roadName,
          'subLocality': subLocality,
          'locality': locality,
          'administrativeArea': administrativeArea,
          'country': country,
          'latitude': _selectedLatLng!.latitude,
          'longitude': _selectedLatLng!.longitude,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedLatLng == null
                  ? const Center(
                      child: Text(
                        'Fetching your location...',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        center: _selectedLatLng!,
                        zoom: 15,
                        onTap: (tapPosition, point) {
                          _onMapTap(point);
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
                              point: _selectedLatLng!,
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
              _selectedLatLng == null
                  ? 'No location selected'
                  : 'Location: $_selectedLocationName (${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)})',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _saveProfile(),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onSignOut,
              child: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
