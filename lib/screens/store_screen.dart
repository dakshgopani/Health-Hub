import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StoreScreen extends StatefulWidget {
  final String userId;

  const StoreScreen({super.key, required this.userId});

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  int _userPoints = 0; // Stores total user points
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredMedicines = [];

  List<Map<String, dynamic>> medicines = [
    {
      'name': 'Paracetamol',
      'points': 10,
      'image': 'assets/images/medicine_img/paracetamol_medicine.jpg',
      'description':
          'Pain reliever and fever reducer for mild to moderate pain.',
      'category': 'Pain Relief'
    },
    {
      'name': 'Ibuprofen',
      'points': 20,
      'image': 'assets/images/medicine_img/ibuprofen_medicine.jpg',
      'description':
          'Non-steroidal anti-inflammatory drug (NSAID) for pain and inflammation.',
      'category': 'Pain Relief'
    },
    {
      'name': 'Amoxicillin',
      'points': 30,
      'image': 'assets/images/medicine_img/Amoxicillin_medicine.png',
      'description': 'Antibiotic used to treat bacterial infections.',
      'category': 'Antibiotics'
    },
    {
      'name': 'Ciprofloxacin',
      'points': 40,
      'image': 'assets/images/medicine_img/Ciprofloxacin_medicine.jpeg',
      'description':
          'Broad-spectrum antibiotic for various bacterial infections.',
      'category': 'Antibiotics'
    },
    {
      'name': 'Azithromycin',
      'points': 50,
      'image': 'assets/images/medicine_img/azithromycin_medicine.jpg',
      'description':
          'Macrolide antibiotic used to treat respiratory infections.',
      'category': 'Antibiotics'
    },
    {
      'name': 'Cetirizine',
      'points': 60,
      'image': 'assets/images/medicine_img/cetirizine_medicine.jpg',
      'description':
          'Antihistamine for allergy symptoms like sneezing and itching.',
      'category': 'Allergy'
    },
    {
      'name': 'Metformin',
      'points': 70,
      'image': 'assets/images/medicine_img/metformin_medicine.png',
      'description':
          'Oral medication to control blood sugar levels in type 2 diabetes.',
      'category': 'Diabetes'
    },
    {
      'name': 'Losartan',
      'points': 80,
      'image': 'assets/images/medicine_img/losartan_medicine.jpg',
      'description':
          'Angiotensin II receptor blocker (ARB) for high blood pressure.',
      'category': 'Blood Pressure'
    },
    {
      'name': 'Amlodipine',
      'points': 90,
      'image': 'assets/images/medicine_img/Amlodipine_medicine.jpg',
      'description':
          'Calcium channel blocker for high blood pressure and chest pain.',
      'category': 'Blood Pressure'
    },
    {
      'name': 'Omeprazole',
      'points': 100,
      'image': 'assets/images/medicine_img/Omeprazole_medicine.jpg',
      'description':
          'Proton pump inhibitor (PPI) for acid reflux and stomach ulcers.',
      'category': 'Digestive'
    }
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _fetchUserPoints();
    _filteredMedicines = List.from(medicines);
  }

  Future<void> _fetchUserPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userPoints = (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching points: $e");
      setState(() {
        _isLoading = false;
      });
    }

    _animationController.forward();
  }

  void _filterMedicines(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMedicines = List.from(medicines);
      } else {
        _filteredMedicines = medicines
            .where((medicine) =>
                medicine['name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                medicine['category']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _redeemReward(int cost, String medicineName) async {
    if (_userPoints >= cost) {
      _showLoadingDialog(); // ✅ Show loader first

      setState(() {
        _userPoints -= cost;
      });

      // ✅ Perform Firestore update in the background
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'points': _userPoints});

      Navigator.pop(context); // ✅ Close the loader
      Navigator.pop(context); // ✅ Close bottom sheet immediately

      _showSuccessDialog(medicineName); // ✅ Show success pop-up
    } else {
      Navigator.pop(
          context); // ✅ Close the bottom sheet BEFORE showing Snackbar

      Future.delayed(const Duration(milliseconds: 200), () {
        // ✅ Ensure UI update before showing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Not enough points!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      });
    }
  }

  // ✅ Loader Dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                strokeWidth: 6.0,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Processing your request...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Raleway',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Success Dialog
  void _showSuccessDialog(String medicineName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.2 * 255).toInt()),
      // Background dimming
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // ✅ Blur Effect
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🎉 Header with Gradient Background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF432C81), Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: Text(
                    "🎉 Success!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Success Icon
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 12),

              // 💊 Success Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "You have successfully purchased $medicineName",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🆗 OK Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                // Add spacing around the button
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF432C81),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // Rounded corners
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF432C81).withOpacity(0.5),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicineDetails(Map<String, dynamic> medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Transparent for Glassmorphism effect
      builder: (context) => Stack(
        children: [
          // Blurred Background Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withAlpha((0.2 * 255).toInt()), // 🔹 Fixed
            ),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            minChildSize: 0.3,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar for dragging
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Medicine Image with Gradient Overlay
                        Stack(
                          children: [
                            Hero(
                              tag: 'medicine-${medicine['name']}',
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(medicine['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      medicine['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Raleway',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EAFA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            medicine['category'],
                            style: const TextStyle(
                              color: Color(0xFF6B4EFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          constraints: const BoxConstraints(maxWidth: 120),
                        ),
                        const SizedBox(height: 16),

                        // Points with Star Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${medicine['points']} Points",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber[800],
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description Section
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF432C81),
                            fontFamily: 'Raleway',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          medicine['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Points Comparison
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _userPoints >= medicine['points']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _userPoints >= medicine['points']
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your Points",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontFamily: 'Raleway',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_userPoints",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF432C81),
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _userPoints >= medicine['points']
                                    ? Icons.check_circle
                                    : Icons.remove_circle,
                                color: _userPoints >= medicine['points']
                                    ? Colors.green
                                    : Colors.red,
                                size: 28,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Required",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[700],
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${medicine['points']}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF432C81),
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Redeem Button
                        ElevatedButton(
                          onPressed: () => _redeemReward(
                              medicine['points'], medicine['name']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4EFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor:
                                const Color(0xFF6B4EFF).withOpacity(0.5),
                          ),
                          child: const Text(
                            "Redeem Now",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cancel Button
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                      ],
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

  void _showPointsPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF432C81),
                Color(0xFF6B4EFF),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Points Animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Points Display
                    Text(
                      "$_userPoints",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Raleway',
                      ),
                    ),
                    Text(
                      "REWARD POINTS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 2,
                        fontFamily: 'Raleway',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Encouraging Message
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Keep earning points by scanning medicines and completing health tasks!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.5,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Close Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF432C81),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Continue Shopping",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    List<String> categories = [
      'All',
      'Pain Relief',
      'Antibiotics',
      'Allergy',
      'Diabetes',
      'Blood Pressure',
      'Digestive'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filter by Category",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF432C81),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                return FilterChip(
                  label: Text(category),
                  selected: _searchQuery ==
                      (category == 'All' ? '' : category.toLowerCase()),
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterMedicines(category == 'All' ? '' : category);
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6B4EFF),
                  labelStyle: TextStyle(
                    color: _searchQuery ==
                            (category == 'All' ? '' : category.toLowerCase())
                        ? const Color(0xFF6B4EFF)
                        : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _searchQuery ==
                              (category == 'All' ? '' : category.toLowerCase())
                          ? const Color(0xFF6B4EFF)
                          : Colors.transparent,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sort by",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF432C81),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Color(0xFF6B4EFF)),
              title: const Text(
                "Price: Low to High",
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredMedicines
                      .sort((a, b) => a['points'].compareTo(b['points']));
                });
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.arrow_downward, color: Color(0xFF6B4EFF)),
              title: const Text(
                "Price: High to Low",
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _filteredMedicines
                      .sort((a, b) => b['points'].compareTo(a['points']));
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = '';
                  _filteredMedicines = List.from(medicines);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Reset All Filters",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                        ),
                      )
                    : _buildMedicineGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context), // ✅ Navigate back
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF6B4EFF),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🎁 Rewards Shop",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Raleway',
                  color: Color(0xFF432C81),
                ),
              ),
              Text(
                "Redeem your points for medicines",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showPointsPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "$_userPoints",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Raleway',
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                onChanged: _filterMedicines,
                decoration: InputDecoration(
                  hintText: "Search medicines...",
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                  icon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterOptions,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineGrid() {
    return _filteredMedicines.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No medicines found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontFamily: 'Raleway',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try a different search term",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Raleway',
                  ),
                ),
              ],
            ),
          )
        : AnimationLimiter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredMedicines.length,
                itemBuilder: (context, index) {
                  var medicine = _filteredMedicines[index];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildMedicineCard(medicine),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    bool canAfford = _userPoints >= medicine['points'];

    return GestureDetector(
      onTap: () => _showMedicineDetails(medicine),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          // Prevents overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            // Ensures column takes minimal space
            children: [
              // Medicine Image with Category Badge
              Stack(
                children: [
                  Hero(
                    tag: 'medicine-${medicine['name']}',
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        image: DecorationImage(
                          image: AssetImage(medicine['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        medicine['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Medicine Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Prevents extra space
                    children: [
                      // Medicine Name
                      Text(
                        medicine['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF432C81),
                          fontFamily: 'Raleway',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Points & Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${medicine['points']} Points",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(), // Pushes button to the bottom

                      // Buy Now Button
                      SizedBox(
                        width: double.infinity,
                        // Ensures button takes full width
                        height: 36,
                        // Fixes height issue
                        child: ElevatedButton(
                          onPressed: () => _showMedicineDetails(medicine),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford
                                ? const Color(0xFF6B4EFF)
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: canAfford ? 3 : 0,
                            shadowColor: canAfford
                                ? const Color(0xFF6B4EFF).withOpacity(0.3)
                                : Colors.transparent,
                          ),
                          child: FittedBox(
                            // Prevents text overflow
                            child: Text(
                              canAfford ? "Buy Now" : "Not Enough",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
