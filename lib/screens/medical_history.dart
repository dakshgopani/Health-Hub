import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Added for URL launching
import 'package:uuid/uuid.dart'; // Add this import
import 'dart:convert';
import 'dart:io';

class MedicalHistoryPage extends StatefulWidget {
  @override
  _MedicalHistoryPageState createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  File? _selectedFile;

  // Pinata API keys
  final String pinataApiKey = '29e74c8898cc7770b410';
  final String pinataSecretApiKey =
      '799deef38f4aa2b5300c2312c2c21c966b5405ef0a466252aa0ecefbaf18479f';

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

  // Pick a file from the device
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      await _uploadFileToPinata();
    }
  }

  // Upload file to Pinata and save metadata to Firestore
  Future<void> _uploadFileToPinata() async {
    if (_selectedFile == null) return;

    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      if (!await _selectedFile!.exists()) {
        throw Exception('File does not exist at path: ${_selectedFile!.path}');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS'),
      );
      request.headers['pinata_api_key'] = pinataApiKey;
      request.headers['pinata_secret_api_key'] = pinataSecretApiKey;
      request.files
          .add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final ipfsHash = jsonDecode(responseData)['IpfsHash'];
      final downloadUrl = 'https://gateway.pinata.cloud/ipfs/$ipfsHash';

      String fileName = _selectedFile!.path.split('/').last;
      Map<String, dynamic> metadata = {
        'file_name': fileName,
        'file_url': downloadUrl,
        'date': DateTime.now().toIso8601String(),
        'type': 'document',
        'user_id': user.uid,
      };

      String blockchainHash = _generateBlockchainHash(metadata);
      metadata['blockchain_hash'] = blockchainHash;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('med_history')
          .add(metadata);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully')),
      );
      setState(() {
        _selectedFile = null;
      });
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  String _generateBlockchainHash(Map<String, dynamic> data) {
    String dataString = jsonEncode(data);
    return sha256.convert(utf8.encode(dataString)).toString();
  }

  Future<List<Map<String, dynamic>>> getMedicalHistory() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('med_history')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _generateShareCode() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final history = await getMedicalHistory();
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown User';

    final shareData = {
      'user_name': userName,
      'user_id': user.uid,
      'history': history,
    };
    final historyJson = jsonEncode(shareData);
    final encryptedHistory = base64Encode(utf8.encode(historyJson));

    // Generate a unique share code
    const uuid = Uuid();
    final shareCode = uuid.v4().substring(0, 5).toUpperCase(); // e.g., X7K9P

    await _firestore.collection('shared_history').add({
      'share_code': shareCode,
      'user_id': user.uid,
      'data': encryptedHistory,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
    });

    return shareCode;
  }

  Future<void> _shareWithDoctor() async {
    try {
      final shareCode = await _generateShareCode();
      await Share.share('My medical history share code: $shareCode');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  String formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: getMedicalHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildHistoryList(history);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Flexible(
            // Added to prevent overflow
            child: const Text(
              'Medical History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'Raleway',
                color: Color(0xFF432C81),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickFile,
            tooltip: 'Upload File',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWithDoctor,
            tooltip: 'Share with Doctor',
          ),
        ],
      ),
    );
  }

  String formatFileName(String fileName) {
    const int maxCharsPerLine = 20;
    String formatted = '';

    for (int i = 0; i < fileName.length; i += maxCharsPerLine) {
      formatted += fileName.substring(
        i,
        i + maxCharsPerLine > fileName.length ? fileName.length : i + maxCharsPerLine,
      ) + '\n';  // Add line break
    }

    return formatted.trim();  // Remove extra new line at the end
  }


  Widget _buildHistoryList(List<Map<String, dynamic>> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        bool isDocument = entry['type'] == 'document';
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showDetailsDialog(context, entry),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isDocument
                                  ? formatFileName(entry['file_name'])
                                  : entry['disease'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Color(0xFF6B4EFF),
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatDate(entry['date']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!isDocument && entry['confidence'] != null)
                        Text(
                          'Confidence: ${(entry['confidence'] * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!isDocument && entry['symptoms'] != null) ...[
                        const Text(
                          'Symptoms:',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (entry['symptoms'] as List)
                              .map((symptom) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              symptom,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ] else ...[
                        GestureDetector(
                          // Make URL clickable
                          onTap: () async {
                            final url = entry['file_url'];
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Cannot open URL: $url')),
                              );
                            }
                          },
                          child: Text(
                            'Document URL: ${entry['file_url']}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Blockchain Hash: ${entry['blockchain_hash'].substring(0, 16)}...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Medical History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Your medical history will appear here',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Error Loading History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> entry) {
    bool isDocument = entry['type'] == 'document';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isDocument ? entry['file_name'] : entry['disease'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B4EFF),
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatDate(entry['date']),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (!isDocument && entry['confidence'] != null)
                Text(
                  'Confidence: ${(entry['confidence'] * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 20),
              if (!isDocument && entry['symptoms'] != null) ...[
                const Text(
                  'Symptoms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    fontFamily: 'Raleway',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (entry['symptoms'] as List)
                      .map((symptom) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      symptom,
                      style: const TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ] else ...[
                GestureDetector(
                  // Make URL clickable in dialog
                  onTap: () async {
                    final url = entry['file_url'];
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cannot open URL: $url')),
                      );
                    }
                  },
                  child: Text(
                    'Document URL: ${entry['file_url']}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Blockchain Hash: ${entry['blockchain_hash']}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
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