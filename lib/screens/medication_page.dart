import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';

class MedicineScannerPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MedicineScannerPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MedicineScanner(),
  ];

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
              Expanded(child: _pages[_currentIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Set the status bar color to match AppBar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.deepPurple, // Make status bar color deep purple
      statusBarIconBrightness: Brightness.light, // White icons
    ));
    return AppBar(
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
        weight: 900,
        size: 26,
      ),
      title: const Text(
        'Medicine Scanner',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Raleway',
        ),
      ),
      backgroundColor: AppColors.deepPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

}

class MedicineScanner extends StatefulWidget {
  @override
  _MedicineScannerState createState() => _MedicineScannerState();
}

class _MedicineScannerState extends State<MedicineScanner>
    with SingleTickerProviderStateMixin {
  File? _image;
  String? _prescription;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _showImageOptions = false;

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
    _animationController.forward();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _showImageOptions = false;
    });

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prescription = null;
        _isLoading = true;
      });
      await _getPrescription();
      setState(() {
        _isLoading = false;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _getPrescription() async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://rudraaaa76-medicine-scanner.hf.space/generate_prescription'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('image', _image!.path),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _prescription = jsonResponse['prescription'];
        });
      } else {
        setState(() {
          _prescription = "Failed to generate information. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _prescription = "An error occurred. Please check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_prescription != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildPrescriptionCard(),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _showImageOptions
          ? _buildExpandedFab()
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            _showImageOptions = true;
          });
        },
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF432C81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "Medicine Scanner",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Take a photo of your medicine or prescription to get detailed information",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Raleway',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showImageOptions = true;
        });
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _image != null
              ? Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_image!, fit: BoxFit.cover),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _image = null;
                      _prescription = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                size: 60,
                color: const Color(0xFF6B4EFF).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tap to add a photo",
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Take a clear photo of your medicine",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          onTap: () => _pickImage(ImageSource.gallery),
          isPrimary: false,
        ),
        _buildActionButton(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          onTap: () => _pickImage(ImageSource.camera),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            foregroundColor: isPrimary ? Colors.white : const Color(0xFF6B4EFF),
            backgroundColor: isPrimary ? const Color(0xFF6B4EFF) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF6B4EFF).withOpacity(isPrimary ? 0 : 0.5),
                width: 1.5,
              ),
            ),
            elevation: isPrimary ? 5 : 0,
            shadowColor: isPrimary ? const Color(0xFF6B4EFF).withOpacity(0.5) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : const Color(0xFF6B4EFF), // FIXED: Explicit color
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
              strokeWidth: 6.0,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Analyzing your medicine...",
            style: TextStyle(
              color: Color(0xFF432C81),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Raleway',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This may take a moment",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Raleway',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    List<String> responses = _prescription?.split("\n\n") ?? [];

    if (responses.isEmpty) {
      return _buildErrorCard("No information found. Please try with a clearer image.");
    }

    return Column(
      children: [
        const Text(
          "Medicine Information",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF432C81),
            fontFamily: 'Raleway',
          ),
        ),
        const SizedBox(height: 16),
        ...responses.map((response) {
          String cleanedResponse = response.replaceAll("-", "").trim();
          List<String> parts = cleanedResponse.split(":");
          String title = parts.isNotEmpty ? parts.first.trim() : "";
          String content = parts.length > 1 ? parts.sublist(1).join(":").trim() : "";

          if (title.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.all(16),
                childrenPadding: EdgeInsets.zero,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EAFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForTitle(title),
                        color: const Color(0xFF6B4EFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF432C81),
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F8FF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        _buildDisclaimerText(),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            "Oops!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF432C81),
              fontFamily: 'Raleway',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontFamily: 'Raleway',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _image = null;
                _prescription = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Try Again",
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This information is for reference only. Always consult with a healthcare professional before taking any medication.",
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 14,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedFab() {
    return Container(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            bottom: 70,
            right: 8,
            child: _buildFabOption(
              icon: Icons.photo_library_rounded,
              label: "Gallery",
              onTap: () => _pickImage(ImageSource.gallery),
              color: Colors.green,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 70,
            child: _buildFabOption(
              icon: Icons.camera_alt_rounded,
              label: "Camera",
              onTap: () => _pickImage(ImageSource.camera),
              color: Colors.blue,
            ),
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showImageOptions = false;
              });
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label, // Ensures each FAB has a unique hero tag
          onPressed: onTap,
          backgroundColor: color,
          mini: true,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }


  IconData _getIconForTitle(String title) {
    title = title.toLowerCase();

    if (title.contains("symptom")) {
      return Icons.coronavirus_rounded; // Represents health issues/symptoms
    } else if (title.contains("primary") || title.contains("diagnosis")) {
      return Icons.medical_services_rounded; // Medical diagnosis
    } else if (title.contains("usage") || title.contains("use")) {
      return Icons.healing_rounded; // Treatment/Usage
    } else if (title.contains("name") || title.contains("medicine")) {
      return Icons.medication_rounded; // Medicine
    } else if (title.contains("side") || title.contains("effect")) {
      return Icons.warning_rounded; // Warning for side effects
    } else if (title.contains("dose") || title.contains("dosage")) {
      return Icons.timer_rounded; // Timer for dosage schedule
    } else if (title.contains("precaution") || title.contains("warning")) {
      return Icons.shield_rounded; // Protection/Precaution
    } else if (title.contains("storage") || title.contains("keep")) {
      return Icons.inventory_2_rounded; // Storage
    } else if (title.contains("ingredient") || title.contains("composition")) {
      return Icons.science_rounded; // Scientific composition
    } else {
      return Icons.info_outline_rounded; // Default information icon
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}