import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scratcher/scratcher.dart';
import 'package:confetti/confetti.dart';
import 'store_screen.dart';

class RewardsSystem extends StatefulWidget {
  final String userId;
  final String requestId;

  const RewardsSystem({
    super.key,
    required this.userId,
    required this.requestId,
  });

  @override
  _RewardsSystemState createState() => _RewardsSystemState();

  static void showScratchCardPopup(
      BuildContext context, String userId, String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ScratchCardDialog(userId: userId, requestId: requestId),
    );
  }
}

class _RewardsSystemState extends State<RewardsSystem> {
  bool _showScratchCard = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        _showScratchCard = true;
      });
      RewardsSystem.showScratchCardPopup(
          context, widget.userId, widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text("Rewards & Points"),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: _showScratchCard
              ? ElevatedButton(
            onPressed: () => RewardsSystem.showScratchCardPopup(
                context, widget.userId, widget.requestId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("🎉 Open Scratch Card!",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )
              : const Text("🎁 Stay Tuned for Your Surprise!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _ScratchCardDialog extends StatefulWidget {
  final String userId;
  final String requestId;

  const _ScratchCardDialog({required this.userId, required this.requestId});

  @override
  _ScratchCardDialogState createState() => _ScratchCardDialogState();
}

class _ScratchCardDialogState extends State<_ScratchCardDialog> {
  int? _scratchPoints;
  bool _isScratched = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _fetchOrGenerateScratchPoints();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  Future<void> _fetchOrGenerateScratchPoints() async {
    try {
      DocumentSnapshot scratchDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('rewards')
          .doc(widget.requestId)
          .get();

      if (scratchDoc.exists && scratchDoc.data() != null) {
        setState(() {
          _scratchPoints =
          (scratchDoc.data() as Map<String, dynamic>)['points'];
        });
      } else {
        _generateScratchPoints();
      }
    } catch (e) {
      print("❌ Error fetching scratch points: $e");
    }
  }

  Future<void> _generateScratchPoints() async {
    int newPoints = (Random().nextInt(10) + 1) * 10;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('rewards')
        .doc(widget.requestId)
        .set({'points': newPoints});

    setState(() {
      _scratchPoints = newPoints;
    });

    print(
        "✅ Scratch Points Generated: $newPoints for Request ID: ${widget.requestId}");
  }

  Future<void> _addScratchPoints(int points, String requestId) async {
    try {
      DocumentReference userRef =
      FirebaseFirestore.instance.collection('users').doc(widget.userId);

      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        List<dynamic> rewardedRequests = userData['rewardedRequests'] ?? [];

        if (rewardedRequests.contains(requestId)) {
          print("⚠️ User already claimed points for requestId: $requestId");
          return;
        }

        rewardedRequests.add(requestId);

        await userRef.update({
          'points': FieldValue.increment(points),
          'rewardedRequests': rewardedRequests,
        });

        print("✅ Scratch Points ($points) added for requestId: $requestId!");
      }
    } catch (e) {
      print("❌ Error adding scratch points: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(top: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎊 You Got a Reward! 🎊",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
                const SizedBox(height: 15),
                Scratcher(
                  brushSize: 40,
                  threshold: 50,
                  color: Colors.grey.shade400,
                  onScratchEnd: () {
                    setState(() {
                      _isScratched = true;
                    });
                    if (_scratchPoints != null) {
                      _addScratchPoints(_scratchPoints!, widget.requestId);
                    }
                    _confettiController.play();
                  },
                  child: Container(
                    width: 180,
                    height: 90,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isScratched ? "🎉 +$_scratchPoints Points" : "Scratch Me!",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              StoreScreen(userId: widget.userId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text("🛍 Go to Store"),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
