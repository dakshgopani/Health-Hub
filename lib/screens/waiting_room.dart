import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaitingRoomScreen extends StatelessWidget {
  final String requestId;

  const WaitingRoomScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Waiting Room"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorMessage("Error: ${snapshot.error}");
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorMessage("No such request found. Please check the Request ID.");
          }

          // Safely fetch the waiting list
          var waitingList = snapshot.data!['waiting_list'] as List<dynamic>?;

          if (waitingList == null || waitingList.isEmpty) {
            return _buildEmptyMessage("No one is waiting yet. You could be the first!");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: waitingList.length,
            itemBuilder: (context, index) {
              final user = waitingList[index];

              // Handle string or map data types
              if (user is String) {
                // User is stored as a string
                return _buildUserCard(userId: user, status: "Pending");
              } else if (user is Map<String, dynamic>) {
                // User is stored as a map
                final userId = user['user_id'] ?? 'Unknown';
                final status = user['status'] ?? 'Pending';
                return _buildUserCard(userId: userId, status: status);
              } else {
                // Unrecognized data type
                return _buildUserCard(userId: "Unknown", status: "Invalid Data");
              }
            },
          );
        },
      ),
    );
  }

  /// Helper method to build a card for each user
  Widget _buildUserCard({required String userId, required String status}) {
    // Safely get the first character for the avatar
    final avatarChar = (userId.isNotEmpty ? userId[0].toUpperCase() : "?");

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            avatarChar,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          "User ID: $userId",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Status: $status"),
      ),
    );
  }

  /// Helper method to build a generic error message widget
  Widget _buildErrorMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Helper method to build an empty message widget
  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, color: Colors.grey, size: 60),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
