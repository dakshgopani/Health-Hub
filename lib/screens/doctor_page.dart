import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:csv/csv.dart';
import '../models/doctor_data_model.dart';
import 'doctor_profile_screen.dart';
import 'home/home_page.dart';

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
    );
  }).toList();

  return doctors;
}

class DoctorListScreen extends StatefulWidget {
  final List<Doctor> allDoctors;
  final String name;
  final double fee;
  const DoctorListScreen(
      {super.key,
      required this.allDoctors,
      required this.name,
      required this.fee});

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
  final String userEmail = FirebaseAuth.instance.currentUser!.email??"Email";

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
    searchController.dispose();
    super.dispose();
  }

  void filterDoctors(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        filteredDoctors = widget.allDoctors;
      } else {
        filteredDoctors = widget.allDoctors.where((doctor) {
          return doctor.name.toLowerCase().contains(searchQuery) ||
              doctor.specialization.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
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
                child: filteredDoctors.isEmpty
                    ? _buildEmptyState()
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
                          builder: (context) =>
                              HomePage(userId: userId, userName: userName,userEmail: userEmail,))),
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
                            fontWeight: FontWeight.w600),
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
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF432C81)),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Color(0xFF432C81)),
                          onPressed: () {
                            searchController.clear();
                            filterDoctors('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              fontWeight: FontWeight.w600,
              fontFamily: 'Raleway',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    return AnimationLimiter(
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
    );
  }

  Widget _buildDoctorCard(int index) {
    final doctor = filteredDoctors[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(doctor: doctor),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Raleway'),
                      children: _highlightText(
                          "${doctor.name} (${doctor.specialization})",
                          searchQuery),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
