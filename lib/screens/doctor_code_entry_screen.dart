import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'doctor_dashboard_screen.dart'; // Adjust path

class DoctorCodeEntryScreen extends StatefulWidget {
  @override
  _DoctorCodeEntryScreenState createState() => _DoctorCodeEntryScreenState();
}

class _DoctorCodeEntryScreenState extends State<DoctorCodeEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _validateAndNavigate() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a share code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot = await _firestore
          .collection('shared_history')
          .where('share_code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid share code';
          _isLoading = false;
        });
        return;
      }

      final doc = querySnapshot.docs.first;
      final expiresAt = DateTime.parse(doc['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() {
          _errorMessage = 'Share code has expired';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      final shareId = doc.id;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorHistoryPage(shareId: shareId)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating code: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        // 🔹 Set the back button color here
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        title: Text(
          'Enter Share Code',
          style: AppTextStyles.whiteHeading
              .copyWith(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon and title
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key,
                  size: 50,
                  color: AppColors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Patient Records',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the share code provided by the patient to view their medical history',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Code input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Raleway',
                        color: AppColors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Enter code (e.g., X7K9P)',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'Raleway',
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: AppColors.deepPurple,
                        ),
                        filled: true,
                        fillColor: AppColors.deepPurple.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.deepPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Raleway',
                        letterSpacing: 2,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _validateAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                            : const Text(
                                'Access Records',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The share code is a unique identifier provided by the patient to grant you temporary access to their medical records.',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
