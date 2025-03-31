import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'doctor_code_entry_screen.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchSharedHistories() async {
    final snapshot = await _firestore
        .collection('shared_history')
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'share_id': doc.id,
        'user_id': doc['user_id'],
        'created_at': doc['created_at'],
        'expires_at': doc['expires_at'],
        'data': doc['data'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        // centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        title: Text(
          'Doctor Dashboard',
          style:
              AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900,fontSize: 22),
        ),
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.vpn_key, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DoctorCodeEntryScreen()),
                );
              },
              tooltip: 'Enter Share Code',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Patient Records',
              style:
                  AppTextStyles.heading.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSharedHistories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.deepPurple,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60,
                            color: AppColors.deepPurple.withOpacity(0.7)),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                final sharedHistories = snapshot.data ?? [];
                if (sharedHistories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open,
                            size: 80,
                            color: AppColors.deepPurple.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No shared histories available',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a share code to view patient records',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: sharedHistories.length,
                    itemBuilder: (context, index) {
                      final share = sharedHistories[index];
                      final expiresAt = DateTime.parse(share['expires_at']);
                      final isExpired = DateTime.now().isAfter(expiresAt);

                      return FutureBuilder<String>(
                        future: _getPatientName(share['user_id']),
                        builder: (context, nameSnapshot) {
                          final patientName =
                              nameSnapshot.data ?? 'Unknown Patient';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isExpired
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DoctorHistoryPage(
                                                shareId: share['share_id']),
                                          ),
                                        );
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isExpired
                                              ? Colors.grey.withOpacity(0.2)
                                              : AppColors.deepPurple
                                                  .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 30,
                                            color: isExpired
                                                ? Colors.grey
                                                : AppColors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patientName,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Raleway',
                                                color: isExpired
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('MMM d, yyyy')
                                                      .format(DateTime.parse(
                                                          share['created_at'])),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Raleway',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: isExpired
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Expires: ${DateFormat('MMM d, yyyy').format(expiresAt)}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: isExpired
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontFamily: 'Raleway',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isExpired)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.deepPurple
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            color: AppColors.deepPurple,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorCodeEntryScreen()),
          );
        },
      ),
    );
  }

  Future<String> _getPatientName(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['name'] ?? 'Unknown Patient';
  }
}

class DoctorHistoryPage extends StatelessWidget {
  final String shareId;

  const DoctorHistoryPage({required this.shareId});

  Future<Map<String, dynamic>> _fetchSharedHistory() async {
    final doc = await FirebaseFirestore.instance
        .collection('shared_history')
        .doc(shareId)
        .get();
    if (!doc.exists) {
      throw Exception('Shared history not found');
    }
    final data = doc.data()!;
    final expiresAt = DateTime.parse(data['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Link has expired');
    }
    final decoded = jsonDecode(utf8.decode(base64Decode(data['data'])));
    return decoded;
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
          color: Colors.white, // Change this to any color
        ),
        title: Text('Patient Medical History',
          style: AppTextStyles.whiteHeading.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),),
        backgroundColor: AppColors.deepPurple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSharedHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.deepPurple,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: AppColors.deepPurple.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          final userName = data['user_name'] ?? 'Unknown User';
          final history =
              List<Map<String, dynamic>>.from(data['history'] ?? []);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.deepPurple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.deepPurple,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Raleway',
                              ),
                            ),
                            Text(
                              userName,
                              style: AppTextStyles.heading,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.deepPurple,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Medical History',
                      style: AppTextStyles.heading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: AppColors.deepPurple.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No medical records found',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          bool isDocument = entry['type'] == 'document';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDocument
                                              ? Colors.orange.withOpacity(0.1)
                                              : AppColors.deepPurple
                                                  .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isDocument
                                              ? Icons.description
                                              : Icons.medical_services,
                                          color: isDocument
                                              ? Colors.orange
                                              : AppColors.deepPurple,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          isDocument
                                              ? entry['file_name']
                                              : entry['disease'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Raleway',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.deepPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Date: ${DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date']))}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepPurple,
                                        fontFamily: 'Raleway',
                                      ),
                                    ),
                                  ),
                                  if (!isDocument &&
                                      entry['confidence'] != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Confidence: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Raleway',
                                          ),
                                        ),
                                        Container(
                                          width: 180,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: entry['confidence'],
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _getConfidenceColor(
                                                    entry['confidence']),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(entry['confidence'] * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Raleway',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (!isDocument &&
                                      entry['symptoms'] != null) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Symptoms:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Raleway',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (entry['symptoms'] as List)
                                          .map((s) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.deepPurple
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  s,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.deepPurple,
                                                    fontFamily: 'Raleway',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                  if (isDocument) ...[
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () async {
                                        final url = entry['file_url'];
                                        if (await canLaunch(url)) {
                                          await launch(url);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Cannot open URL: $url'),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.link,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'View Document',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Raleway',
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.open_in_new,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security,
                                            color: Colors.grey[700],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Blockchain Hash: ${entry['blockchain_hash'].substring(0, 16)}...',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontFamily: 'Raleway',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.4) return Colors.red;
    if (confidence < 0.7) return Colors.orange;
    return Colors.green;
  }
}
