import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:csv/csv.dart';
import '../../models/doctor_data_model.dart';
import '../../widgets/doctor_grid.dart';
import 'doctor_profile_screen.dart';
import '../home/home_page.dart';

class DoctorPage extends StatelessWidget {
  const DoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doctor Finder',
      // theme: ThemeData(
      //   primaryColor: const Color(0xFF432C81),
      //   scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      //   fontFamily: 'Raleway',
      // ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<Doctor>>(
          future: loadDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text("Error loading doctors data");
            } else {
              final doctors = snapshot.data ?? [];
              return DoctorListScreen(allDoctors: doctors, name: '', fee: 0);
            }
          },
        ),
      ),
    );
  }
}

Future<List<Doctor>> loadDoctors() async {
  final rawData = await rootBundle.loadString("assets/csv/doctors_data.csv");
  List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

  List<Doctor> doctors = listData.skip(1).map((data) {
    return Doctor(
      doctorId: data[0].toString(),
      name: data[1].toString(),
      specialization: data[2].toString(),
      hospital: data[3].toString(),
      area: data[4].toString(),
      daysAvailable: data[5].toString(),
      timeAvailable: data[6].toString(),
      rating: double.parse(data[7].toString()),
      fee: data[8].toString(),
      contactNumber: data[9].toString(),
      reviews: data[10].toString(),
      experience: int.parse(data[11].toString()),
      languages: data[12].toString(),
      appointmentLink: data[13].toString(),
      gender: data[14].toString()
    );
  }).toList();

  return doctors;
}

// ... (Previous imports and DoctorPage, SplashScreen classes remain unchanged)

class DoctorListScreen extends StatefulWidget {
  final List<Doctor> allDoctors;
  final String name;
  final double fee;

  const DoctorListScreen({
    super.key,
    required this.allDoctors,
    required this.name,
    required this.fee,
  });

  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen>
    with SingleTickerProviderStateMixin {
  List<Doctor> filteredDoctors = [];
  String searchQuery = '';
  late AnimationController _animationController;
  late TextEditingController searchController;
  late Animation<double> _fadeAnimation;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String userName = FirebaseAuth.instance.currentUser?.displayName ?? '';
  final String userEmail = FirebaseAuth.instance.currentUser!.email ?? "Email";
  bool showSpecializations = true;
  String selectedSpecialization = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredDoctors = widget.allDoctors;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void filterDoctors(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        filteredDoctors = widget.allDoctors;
        showSpecializations = true; // Show specializations when search is cleared
      } else {
        showSpecializations = false; // Show doctor list when searching
        filteredDoctors = widget.allDoctors.where((doctor) {
          return doctor.name.toLowerCase().contains(searchQuery) ||
              doctor.specialization.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f3ff),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showSpecializations
                    ? SpecializationGrid(
                  onSpecializationSelected: (specialization) {
                    setState(() {
                      selectedSpecialization = specialization;
                      filteredDoctors = widget.allDoctors
                          .where((doctor) =>
                      doctor.specialization.toLowerCase() ==
                          specialization.toLowerCase())
                          .toList();
                      showSpecializations = false;
                    });
                  },
                )
                    : _buildDoctorList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFf5f3ff),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        userId: userId,
                        userName: userName,
                        userEmail: userEmail,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doctor',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Raleway',
                          color: Color(0xFF432C81),
                        ),
                      ),
                      Text(
                        'Finding, Booking & Telemedicine',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                onChanged: filterDoctors,
                decoration: InputDecoration(
                  hintText: 'Search doctors...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF432C81)),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF432C81)),
                    onPressed: () {
                      searchController.clear();
                      filterDoctors('');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
              fontFamily: 'Raleway',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    return Column(
      children: [
        Expanded(
          child: filteredDoctors.isEmpty
              ? _buildEmptyState()
              : AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildDoctorCard(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(int index) {
    final doctor = filteredDoctors[index];

    // Determine gender-based image category
    final String gender = (doctor.gender == "M") ? "men" : "women";

    // Generate a random seed based on doctor's name for consistent image
    final int imageSeed = doctor.name.hashCode.abs() % 100; // Limit to 0-99
    final String randomImageUrl = "https://randomuser.me/api/portraits/$gender/$imageSeed.jpg";
   // final String randomImageUrl = "https://source.unsplash.com/300x300/?doctor";
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Note: 'custom' seems like a typo; should be 'bottom' or another valid property
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DoctorProfileScreen(
                      doctor: doctor,
                      imageUrl: randomImageUrl, // Pass the image URL
                    ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Doctor Avatar with gender-specific random image
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    child: Hero(
                      tag: 'doctor_avatar_${doctor.doctorId}', // Unique tag
                      child: Image.network(
                        randomImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Color(doctor.name.hashCode).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(doctor.name),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Rest of the code remains unchanged
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                          ),
                          children: _highlightText(doctor.name, searchQuery),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                          ),
                          children: _highlightText(doctor.specialization, searchQuery),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRatingStars(doctor.rating),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isAvailable(doctor)
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isAvailable(doctor) ? 'Available Today' : 'Next Slot: Tomorrow',
                              style: TextStyle(
                                fontSize: 10,
                                color: _isAvailable(doctor) ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper function to get initials from name
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      if (nameParts.length > 1) {
        initials += nameParts[1][0];
      }
    }
    return initials.toUpperCase();
  }

// Helper function to build rating stars
  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 16);
        }
      }),
    );
  }

// Generate a random but consistent rating based on doctor's name
  double _generateRandomRating(String name) {
    // Use the hash code of the name to generate a consistent random rating
    final int hash = name.hashCode.abs();
    // Generate a rating between 3.5 and 5.0
    return 3.5 + (hash % 15) / 10;
  }

// Determine if doctor is available (if not specified in model)
  bool _isAvailable(Doctor doctor) {
    final DateTime now = DateTime.now();
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final String currentDay = weekdays[now.weekday - 1];

    final List<String> availableDays = doctor.daysAvailable.split(',').map((day) => day.trim()).toList();
    return availableDays.contains(currentDay);
  }
  List<TextSpan> _highlightText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final matches = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int indexOfMatch;

    while (true) {
      indexOfMatch = text.toLowerCase().indexOf(matches, start);
      if (indexOfMatch < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + matches.length),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = indexOfMatch + matches.length;
    }
    return spans;
  }
}