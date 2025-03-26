import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaitingRoomScreen extends StatelessWidget {
  final String requestId;
  final String userName;

  const WaitingRoomScreen(
      {super.key, required this.requestId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFEDECF4),
        appBar: AppBar(
          title: const Text(
            "Waiting Room",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway', // Applying Raleway font
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/waiting_room_second.jpg',
                  height: 225,
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blood_requests')
                    .doc(requestId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print("Error fetching blood request: ${snapshot.error}");
                    return _buildErrorMessage("Error: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    print("No such request found with ID: $requestId");
                    return _buildErrorMessage(
                        "No such request found. Please check the Request ID.");
                  }

                  var waitingList =
                      snapshot.data!['waiting_list'] as List<dynamic>?;

                  if (waitingList == null || waitingList.isEmpty) {
                    return _buildEmptyMessage(
                        "No one is waiting yet. You could be the first!");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    shrinkWrap: true,
                    // Important: Allows ListView to fit within SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    // Prevents nested scrolling issues
                    itemCount: waitingList.length,
                    itemBuilder: (context, index) {
                      final user = waitingList[index];

                      if (user is String) {
                        return _buildUserCard(
                            userId: user,
                            status: "Pending",
                            context: context,
                            index: index,
                            waitingList: waitingList);
                      } else if (user is Map<String, dynamic>) {
                        final userId = user['user_id'] ?? 'Unknown';
                        final status = user['status'] ?? 'Pending';
                        return _buildUserCard(
                            userId: userId,
                            status: status,
                            context: context,
                            index: index,
                            waitingList: waitingList);
                      } else {
                        return _buildUserCard(
                            userId: "Unknown",
                            status: "Invalid Data",
                            context: context,
                            index: index,
                            waitingList: waitingList);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildUserCard({
    required String userId,
    required String status,
    required BuildContext context,
    required int index,
    required List<dynamic> waitingList,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildUserCardSkeleton(userId: userId);
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildUserCardSkeleton(userId: userId);
        }

        final userData = snapshot.data!;
        final userName = userData['name'] ?? 'Unknown User';
        final userAvatar =
            userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: scale,
                child: GestureDetector(
                  onTap: () {
                    _showUserDetails(context, userId, index, waitingList);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(4, 4),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFF432C81), Color(0xFF6546A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Text(
                                userAvatar,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ),
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Raleway',
                              ),
                            ),
                            subtitle: Text(
                              "Status: $status",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Raleway',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, String userId, int index,
      List<dynamic> waitingList) async {
    final aheadCount = index;
    List<String> usersAheadNames = [];

    // Fetch user names for those ahead in the queue
    for (var user in waitingList.take(aheadCount)) {
      String userId;
      if (user is Map<String, dynamic>) {
        userId = user['user_id'] ?? 'Unknown';
      } else {
        userId = user;
      }

      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String userName =
          userDoc.exists ? (userDoc['name'] ?? 'Unknown User') : 'Unknown User';

      usersAheadNames.add(userName);
    }

    // Show dialog after fetching names
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "User Details for $userName",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway', // Applying Raleway font
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your position in the waiting list:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: 'Raleway',
                ),
              ),
              Text(
                "#${index + 1}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 12),
              if (usersAheadNames.isNotEmpty) ...[
                const Text(
                  "Users ahead of you:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Raleway',
                  ),
                ),
                Text(
                  usersAheadNames.join(', '),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                ),
              ],
              if (usersAheadNames.isEmpty)
                const Text(
                  "You are at the top of the waiting list! 🎉",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                    fontFamily: 'Raleway',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                ), // Applying font here too
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCardSkeleton({required String userId}) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            userId.isNotEmpty ? userId[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: const Text("Loading...",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Status: Loading..."),
      ),
    );
  }

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
}
