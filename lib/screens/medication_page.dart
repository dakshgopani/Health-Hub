import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicineScannerPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MedicineScannerPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MedicineScanner(),
    MedicationManagement(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF432C81)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(child: _buildNavButton('Medicine Scanner', 0)),
          const SizedBox(width: 10),
          Expanded(child: _buildNavButton('Medication Management', 1)),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _currentIndex == index
                ? Colors.white
                : Theme.of(context).primaryColor,
            fontWeight: FontWeight.w900,
            fontFamily: 'Raleway',
          ),
          textAlign: TextAlign.center,
        ),
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
  }

  Future<void> _pickImage(ImageSource source) async {
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

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      setState(() {
        _prescription = jsonResponse['prescription'];
      });
    } else {
      setState(() {
        _prescription = "Failed to generate information.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_prescription != null)
                  _buildPrescriptionCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Medicine Scanner',
      style: TextStyle(
          fontSize: 28,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w900,
          color: Color(0xFF432C81)),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: _image != null
          ? Image.file(_image!, fit: BoxFit.cover)
          : const Icon(Icons.add_a_photo, size: 50),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF6B4EFF),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF6B4EFF)),
              )),
          label: const Text('Gallery',
              style: TextStyle(
                  fontFamily: 'Raleway', fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF6B4EFF),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF6B4EFF)),
              )),
          label: const Text('Camera',
              style: TextStyle(
                  fontFamily: 'Raleway', fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildPrescriptionCard() {
    List<String> responses = _prescription?.split("\n\n") ?? [];
    return Column(
      children: responses.map((response) {
        String cleanedResponse = response.replaceAll("-", "").trim();
        List<String> parts = cleanedResponse.split(":");
        String title = parts.isNotEmpty ? parts.first.trim() : "";
        String content =
            parts.length > 1 ? parts.sublist(1).join(":").trim() : "";

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF432C81),
                  fontFamily: 'Raleway',
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class MedicationManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Medication Management',
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Raleway'),
      ),
    );
  }
}
