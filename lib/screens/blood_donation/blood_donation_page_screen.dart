import 'dart:io';
import 'dart:ui';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'donation_screen.dart';
import '../emergency_services_screen.dart';
import 'qr_code_scanner.dart';
import 'qr_code_screen.dart';
import '../store_screen.dart';

class BloodDonationPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const BloodDonationPage(
      {super.key,
        required this.userId,
        required this.userName,
        required this.userEmail});

  @override
  State<BloodDonationPage> createState() => _BloodDonationPageState();
}

class _BloodDonationPageState extends State<BloodDonationPage> {
  @override
  void initState() {
    super.initState();

    // Existing function calls
    storeBloodRequests(bloodRequests);
    _fetchBloodRequestsFromFirestore();

    _pages = [
      // StoreScreen(userId: widget.userId),

      BloodDonationPage( // Replace `SelfScreen` with the actual name of your current screen
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),


      ScanQRCodeScreen(userId: widget.userId, userName: widget.userName),
      EmergencyServicesScreen(
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail),
      StoreScreen(userId: widget.userId),
    ];

    // Navigate to QR Code screen if data is available
    if (qrCodeData.isNotEmpty) {
      Future.delayed(Duration.zero, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRCodeScreen(qrCodeData: qrCodeData),
          ),
        );
      });
    }
  }

  Future<void> storeBloodRequests(
      List<Map<String, dynamic>> bloodRequests) async {
    CollectionReference donationRequestsRef =
    FirebaseFirestore.instance.collection("donation_requests");

    for (var request in bloodRequests) {
      String requestId =
      request["requestId"]; // Use requestId as the document ID
      await donationRequestsRef.doc(requestId).set(request);
    }

    print("Blood donation requests stored successfully!");
  }

  Future<void> _fetchBloodRequestsFromFirestore() async {
    CollectionReference donationRequestsRef =
    FirebaseFirestore.instance.collection("donation_requests");

    try {
      QuerySnapshot snapshot = await donationRequestsRef.get();
      List<Map<String, dynamic>> requests = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        bloodRequests = requests; // Update UI with Firestore data
      });

      print("Fetched blood donation requests successfully!");
    } catch (e) {
      print("Error fetching blood requests: $e");
    }
  }

  // Class-level variable for requestId
  String? _currentRequestId;

  int _page = 0;
  late final List<Widget> _pages;


  List<Map<String, dynamic>> bloodRequests = [
    {
      "bloodGroup": "A+",
      "requiredQuantity": 2,
      "hospitalName": "City Hospital",
      "hospitalLocation": "Downtown, XYZ",
      "requestId": "req_1"
    },
    {
      "bloodGroup": "B-",
      "requiredQuantity": 3,
      "hospitalName": "Green Valley Clinic",
      "hospitalLocation": "Uptown, ABC",
      "requestId": "req_2"
    },
    {
      "bloodGroup": "O+",
      "requiredQuantity": 1,
      "hospitalName": "HealthCare Center",
      "hospitalLocation": "Midtown, LMN",
      "requestId": "req_3"
    },
  ];

  String qrCodeData = ""; // Holds the QR data to display
  Map<String, dynamic> parsedData = {}; // Holds parsed data from QR code

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline, // Icon indicating info
              color: Colors.white,
            ),
            const SizedBox(width: 8), // Space between the icon and text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Make text bold for emphasis
                  fontSize: 16, // Slightly larger font size
                  fontFamily: 'Raleway',
                ),
                overflow: TextOverflow.ellipsis, // Prevent text overflow
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF432C81),
        // Deep purple background
        behavior: SnackBarBehavior.floating,
        // Change to floating behavior
        duration: const Duration(seconds: 3),
        // Duration for the SnackBar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        margin: const EdgeInsets.all(16),
        // Margin around the SnackBar
        elevation: 6, // Slight elevation for a 3D effect
      ),
    );
  }

  void _showAddRequestDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // Key for form validation

    TextEditingController quantityController = TextEditingController();
    TextEditingController hospitalController = TextEditingController();
    TextEditingController locationController = TextEditingController();

    // Dynamic Blood Group List
    List<String> bloodGroups = [
      "A+",
      "A-",
      "B+",
      "B-",
      "O+",
      "O-",
      "AB+",
      "AB-"
    ];
    String? selectedBloodGroup; // Holds selected value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Assign form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Gradient Background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF432C81), Colors.deepPurpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(
                      child: Text(
                        "Add Blood Donation Request",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Blood Group Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Blood Group",
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Raleway',
                          color: Colors.black87,
                        ),
                        prefixIcon: Icon(Icons.bloodtype,
                            color: _getIconColor(Icons.bloodtype)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: Colors.deepPurple),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.deepPurpleAccent, width: 2),
                        ),
                      ),
                      value: selectedBloodGroup,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.deepPurple),
                      items: bloodGroups.map((String bloodGroup) {
                        return DropdownMenuItem<String>(
                          value: bloodGroup,
                          child: Text(
                            bloodGroup,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        selectedBloodGroup = newValue!;
                      },
                      validator: (value) =>
                      value == null ? "Please select a blood group" : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Fields with Validation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: quantityController,
                          label: "Required Quantity",
                          icon: Icons.water_drop,
                          keyboardType: TextInputType.number,
                        ),
                        _buildInputField(
                          controller: hospitalController,
                          label: "Hospital Name",
                          icon: Icons.local_hospital,
                        ),
                        _buildInputField(
                          controller: locationController,
                          label: "Location",
                          icon: Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // If form is valid, proceed with adding request
                              num requiredQuantity =
                                  num.tryParse(quantityController.text) ?? 0;
                              String hospitalName = hospitalController.text;
                              String hospitalLocation = locationController.text;
                              String requestId =
                                  "req_${bloodRequests.length + 1}";

                              Map<String, dynamic> newRequest = {
                                "bloodGroup": selectedBloodGroup,
                                "requiredQuantity": requiredQuantity,
                                "hospitalName": hospitalName,
                                "hospitalLocation": hospitalLocation,
                                "requestId": requestId,
                              };

                              try {
                                await FirebaseFirestore.instance
                                    .collection("donation_requests")
                                    .doc(requestId)
                                    .set(newRequest);

                                _fetchBloodRequestsFromFirestore();
                              } catch (e) {
                                print("Error adding donation request: $e");
                              }

                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF432C81),
                              fontFamily: 'Raleway',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Navigation methods for each page
  void _navigateToBloodDonationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BloodDonationPage(
          userId: widget.userId,
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
      ),
    );
  }

  void _navigateToScanQRCodePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanQRCodeScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void _navigateToStorePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _navigateToEmergencyServicesPage() {
    // Go back one page in the navigation stack
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If there's no page to pop, you can show a message or do nothing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous page to go back to')),
      );
    }
  }


// Updated Reusable Input Field with Validation
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required"; // Error message if empty
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Raleway',
            color: Colors.black87,
          ),
          prefixIcon: Icon(icon, color: _getIconColor(icon)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Colors.deepPurpleAccent, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDECF4),
      // appBar: AppBar(
      //   title: _buildUserNameStream(),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.settings),
      //       onPressed: () {
      //         // Navigate to Profile Screen
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => ProfileScreen(
      //               userId: widget.userId,
      //               userName: widget.userName,
      //             ),
      //           ),
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildDonationList(), // Display donation details
            const SizedBox(height: 30),
            // ✅ Properly formatted `if` condition
            if (qrCodeData.isNotEmpty)
              const SizedBox.shrink() // Prevents empty condition errors
            else
              const SizedBox(height: 10),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRequestDialog(context);
        },
        child: const Icon(Icons.add, size: 30),
        backgroundColor: const Color(0xFFFFFFFF), // Same as buttonBackgroundColor
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: const Color(0xFF432C81),
        buttonBackgroundColor: const Color(0xFF6B4EFF),
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _page, // Still needed for visual feedback
        onTap: (index) {
          setState(() {
            _page = index; // Update selected index for visual feedback
          });

          // Navigate to the corresponding page
          switch (index) {
            case 0:
              _navigateToBloodDonationPage();
              break;
            case 1:
              _navigateToScanQRCodePage();
              break;
            case 2:
              _navigateToEmergencyServicesPage();
              break;
            case 3:
              _navigateToStorePage();
              break;
          }
        },
        items: const [
          Icon(Icons.grid_view, color: Colors.white), // Blood Donation
          Icon(Icons.qr_code_scanner_outlined, color: Colors.white), // Scan QR Code
          Icon(Icons.emergency_outlined, color: Colors.white), // Emergency Services
          Icon(Icons.local_grocery_store_outlined, color: Colors.white), // Store
        ],
      ),
    );
  }



  /// Extracted StreamBuilder for User Name
  Widget _buildUserNameStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User not found');
        }

        String userName = snapshot.data?.get('name') ?? 'User';
        return Text('Welcome, $userName');
      },
    );
  }

  Future<void> checkPermissions() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      // Permissions already granted, proceed with accessing photos
    } else {
      // Request permissions
      var statusRequest = await Permission.storage.request();
      if (statusRequest.isGranted) {
        // Permissions granted, proceed with accessing photos
      } else {
        // Handle permission denied
        print("Permission denied");
      }
    }
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print("Storage permission granted");
      // Proceed with accessing storage
    } else if (status.isDenied) {
      print("Storage permission denied");
      // Handle permission denial
    } else if (status.isPermanentlyDenied) {
      print("Storage permission permanently denied. Open app settings.");
      await openAppSettings();
    }
  }

  Future<void> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery access permission denied")),
      );
    }
  }

  Future<void> _saveQRCodeToGallery() async {
    try {
      // Request permission before attempting to save the image
      final permissionStatus = await Permission.photos.request();

      if (!permissionStatus.isGranted) {
        // Handle permission denied case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery access permission denied")),
        );
        return;
      }

      // Define QR code painter
      final qrCode = QrPainter(
        data: qrCodeData,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final tempDir = await getTemporaryDirectory();
      final qrFile = File('${tempDir.path}/qr_code.png');

      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      const double qrSize = 300; // QR code actual size
      const double padding = 50; // White border around the QR code
      const double totalSize = qrSize + (2 * padding); // Total image size

      // Draw a white background (full square)
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, totalSize, totalSize), paint);

      // Move the canvas to position the QR code properly
      canvas.translate(padding, padding);

      // Draw the QR code on the translated canvas
      qrCode.paint(canvas, const Size(qrSize, qrSize));

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      await qrFile.writeAsBytes(buffer);

      // Save the image to the gallery using photo_manager
      final assetEntity = await PhotoManager.editor.saveImage(
        buffer,
        title: "qr_code_${DateTime.now().millisecondsSinceEpoch}.png",
        filename: 'qrCode.png',
      );

      if (assetEntity != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR Code saved to gallery!")),
        );
      } else {
        throw Exception("Failed to save the QR Code.");
      }
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildDonationList() {
    return ListView.builder(
      shrinkWrap: true,
      // Ensures ListView takes only the required height
      physics: const NeverScrollableScrollPhysics(),
      // Prevents nested scrolling conflicts
      itemCount: bloodRequests.length,
      itemBuilder: (context, index) {
        var request = bloodRequests[index];
        return _buildDonationCard(
          request["bloodGroup"],
          request["requiredQuantity"],
          request["hospitalName"],
          request["hospitalLocation"],
          request,
        );
      },
    );
  }

  /// Show Donation Details Dialog

  void _showDonationDialog(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          // No background to enhance the effect
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              // Glassmorphism Effect Container
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      // Semi-transparent white
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gradient Header with Deep Purple
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF432C81), Color(0xFF6546A0)],
                              // Deep Purple Gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "Blood Donation Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway', // Applying Raleway font
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // **Styled Info Rows** with the applied styles
                        _buildDialogContent(request),
                        // Now uses the new content structure

                        const SizedBox(height: 20),

                        // Buttons Row (Fixed & Stylish)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (qrCodeData.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _donateBlood(request);
                                  // Delay navigation to new page
                                  Future.delayed(
                                      const Duration(milliseconds: 500), () {
                                    if (qrCodeData.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QRCodeScreen(
                                              qrCodeData: qrCodeData),
                                        ),
                                      );
                                    }
                                  });
                                  // Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.favorite,
                                    color: Colors.white),
                                label: const Text("Donate"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF432C81),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                ),
                              ),
                            if (qrCodeData.isNotEmpty)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Wrap Close Button in a Stack to Overlay the Lightbulb Icon
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        label: const Text(
                                          "Close",
                                          style: TextStyle(
                                            fontSize: 16,
                                            // Adjust font size
                                            fontWeight: FontWeight.w700,
                                            // Make it bold
                                            color: Colors.white,
                                            // Ensure it's white

                                            fontFamily:
                                            'Raleway', // Custom font if available
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.grey[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                        ),
                                      ),

                                      // Small Info Icon at Bottom of Close Icon
                                      Positioned(
                                        bottom: -1,
                                        // Adjust position slightly below the close icon
                                        right: 1,
                                        // Adjust to the right side

                                        child: GestureDetector(
                                          onTap: () {
                                            // ✅ Close any existing dialog before showing the QR Code Info dialog
                                            if (Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }

                                            showDialog(
                                              context: context,
                                              barrierColor: Colors.transparent,
                                              // ✅ Make barrier fully transparent
                                              builder: (context) => Stack(
                                                children: [
                                                  // ✅ Background Blur Effect
                                                  BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 10, sigmaY: 10),
                                                    // ✅ Apply blur
                                                    child: Container(
                                                      color: Colors.black
                                                          .withAlpha((0.2 * 255)
                                                          .toInt()), // ✅ Dark overlay
                                                    ),
                                                  ),

                                                  // ✅ Alert Dialog
                                                  Center(
                                                    child: AlertDialog(
                                                      shape:
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(20),
                                                      ),
                                                      contentPadding:
                                                      EdgeInsets.zero,
                                                      // Remove default padding
                                                      content: Column(
                                                        mainAxisSize:
                                                        MainAxisSize.min,
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                        children: [
                                                          // 🎨 Header with Gradient Background
                                                          Container(
                                                            width:
                                                            double.infinity,
                                                            padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical:
                                                                16),
                                                            decoration:
                                                            const BoxDecoration(
                                                              gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                      0xFF432C81),
                                                                  Colors
                                                                      .deepPurpleAccent
                                                                ],
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                              ),
                                                              borderRadius:
                                                              BorderRadius.vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                      20)),
                                                            ),
                                                            child: const Center(
                                                              child: Text(
                                                                "ℹ️ QR Code Info",
                                                                style:
                                                                TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                                  fontFamily:
                                                                  'Raleway',
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                              height: 20),

                                                          // 📌 Information Message
                                                          const Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                20),
                                                            child: Text(
                                                              "The QR code has already been generated.",
                                                              textAlign:
                                                              TextAlign
                                                                  .center,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                                fontFamily:
                                                                'Raleway',
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                              height: 20),

                                                          // 🆗 OK Button
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical:
                                                                12),
                                                            child: TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context); // ✅ Close Dialog First
                                                              },
                                                              style: TextButton
                                                                  .styleFrom(
                                                                foregroundColor:
                                                                Colors
                                                                    .white,
                                                                backgroundColor:
                                                                const Color(
                                                                    0xFF432C81),
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                    24,
                                                                    vertical:
                                                                    10),
                                                                shape:
                                                                RoundedRectangleBorder(
                                                                  borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                      12),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                "OK",
                                                                style:
                                                                TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                                  fontFamily:
                                                                  'Raleway',
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Icon(
                                            Icons.info,
                                            color: Colors.black,
                                            size: 18, // Make it small
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Function to return unique colors for each icon
  Color _getIconColor(IconData icon) {
    if (icon == Icons.bloodtype) {
      return const Color(0xFFF44336); // Red for Location Icon
    } else if (icon == Icons.local_hospital) {
      return const Color(0xFF4CAF50); // Green for Hospital Icon
    } else if (icon == Icons.water_drop) {
      return const Color(0xFF2196F3); // Blue for Water Drop Icon
    } else if (icon == Icons.location_on) {
      return const Color(0xFF432C81); // Deep Purple for Blood Icon
    } else {
      return Colors.black; // Default color (if any unknown icon is passed)
    }
  }

  /// Dialog Content for Donation Details
  Widget _buildDialogContent(Map<String, dynamic> request) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **Styled Info Rows** like in _buildInfoRow
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.bloodtype, color: _getIconColor(Icons.bloodtype)),
              const SizedBox(width: 10),
              const Text(
                "Blood Group: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              Text(
                request['bloodGroup'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.water_drop, color: _getIconColor(Icons.water_drop)),
              const SizedBox(width: 10),
              const Text(
                "Required Quantity: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              Text(
                "${request['requiredQuantity']} Units",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.local_hospital,
                  color: _getIconColor(Icons.local_hospital)),
              const SizedBox(width: 10),
              const Text(
                "Hospital: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              Expanded(
                child: Text(
                  request['hospitalName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.location_on, color: _getIconColor(Icons.location_on)),
              const SizedBox(width: 10),
              const Text(
                "Location: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Raleway',
                ),
              ),
              Expanded(
                child: Text(
                  request['hospitalLocation'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // **Show parsed data when QR code data is present**
        if (qrCodeData.isNotEmpty)
          Center(
            child: Column(
              children: parsedData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${entry.key}: ${entry.value}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Raleway',
                      color: Color(0xFF432C81), // Deep Purple Text Color
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Generate Unique Request ID (based on timestamp only)
  String _generateUniqueRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "req_$timestamp"; // Using timestamp only for uniqueness
  }

  void _donateBlood(Map<String, dynamic> request) async {
    // Extract data dynamically from the clicked request
    final String bloodGroup = request["bloodGroup"];
    final int requiredQuantity = request["requiredQuantity"];
    final String hospitalName = request["hospitalName"];
    final String hospitalLocation = request["hospitalLocation"];

    // Generate a unique requestId for this donation
    final requestId = _generateUniqueRequestId();

    // Save the requestId to the state
    setState(() {
      _currentRequestId = requestId; // Save the requestId for later use
    });

    // Generate QR Code data using this requestId
    setState(() {
      qrCodeData = _generateQRData(
          requestId: requestId,
          bloodGroup: bloodGroup,
          requiredQuantity: requiredQuantity,
          hospitalName: hospitalName,
          hospitalLocation: hospitalLocation);
    });

    // Create the Firestore map with relevant fields
    final firestoreData = {
      // "donorId": widget.userId,
      "bloodGroup": bloodGroup,
      "required_quantity": requiredQuantity,
      "hospitalName": hospitalName,
      "hospitalLocation": hospitalLocation,
      "timestamp": Timestamp.now(),
      "requestId": requestId, // Ensure requestId is consistent
      "qrCodeData": qrCodeData, // Store generated QR code
      "donation_list": [],
      "scanned_count": 0,
      "waiting_list": [],
    };

    try {
      // Save to Firestore with requestId as document ID
      await FirebaseFirestore.instance
          .collection("blood_requests")
          .doc(requestId)
          .set(firestoreData);
      // Show QR Code in a Dialog
      // _showQRCodeDialog(qrCodeData);
      // Show success message
      _showSnackBar("QR Code generated Successfully!");
    } catch (e) {
      // Handle Firestore errors
      print("Error saving to Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving QR Code: $e")),
      );
    }
  }

  Widget _buildDonationCard(
      String bloodGroup,
      int requiredQuantity,
      String hospitalName,
      String hospitalLocation,
      Map<String, dynamic> request) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF432C81).withOpacity(0.3),
              // Soft deep purple tint
              blurRadius: 20,
              // Soft blur to spread the color
              spreadRadius: -5,
              // Controls how much it spreads at the edges
              offset: const Offset(0, 0), // Evenly spread glow around the edges
            ),
          ],
        ),
        child: Card(
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          color: Colors.white, // Keeps the card background clean
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header with Deep Purple
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF432C81), Colors.deepPurpleAccent],
                      // Deep Purple Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Blood Donation Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Raleway', // Applying Raleway font
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Blood Group
                Row(
                  children: [
                    const Icon(Icons.bloodtype, color: Colors.redAccent),
                    // Deep Purple Icon
                    const SizedBox(width: 8),
                    const Text(
                      "Blood Group: ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Raleway'), // Apply Raleway font
                    ),
                    Text(
                      bloodGroup,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Raleway'), // Apply Raleway font
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Required Quantity
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      "Required Quantity: ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Raleway'), // Apply Raleway font
                    ),
                    Text(
                      "$requiredQuantity Units",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Raleway'), // Apply Raleway font
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Hospital Name
                Row(
                  children: [
                    Icon(Icons.local_hospital, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Hospital: $hospitalName",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway'), // Apply Raleway font
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Hospital Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.deepPurple[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Location: $hospitalLocation",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway'), // Apply Raleway font
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Buttons (Updated Colors)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Donate Button with Deep Purple Color
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDonationDialog(context, request),
                        icon: const Icon(Icons.favorite, color: Colors.white),
                        label: const Text(
                          "Donate Blood",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway'),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF432C81),
                          // Deep Purple
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF432C81),
                              // Border color (Deep Purple)
                              width:
                              2, // Border width (you can adjust this as needed)
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Submitted Button with White Background and Purple Text
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonationSuccessScreen(
                                userId: widget.userId,
                                requestId: _currentRequestId,
                                //! was passed earlier
                                hospitalName: hospitalName,
                                hospitalLocation: hospitalLocation,
                                userEmail: widget.userEmail,
                              ),
                            ),
                          );
                          print("Request ID: $_currentRequestId");
                        },
                        icon: const Icon(Icons.check_circle,
                            color: Color(0xFF432C81)),
                        // Purple Icon
                        label: const Text(
                          "Submitted",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Raleway'),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF432C81),
                          // Purple Text
                          backgroundColor: Colors.white,
                          // White Background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF432C81),
                              // Border color (Deep Purple)
                              width:
                              2, // Border width (you can adjust this as needed)
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  String _generateQRData(
      {required String requestId,
        required String bloodGroup,
        required int requiredQuantity,
        required String hospitalName,
        required String hospitalLocation,
        bool encryptData = true}) {
    final requestData = [
      "Request ID: $requestId",
      // "Donor ID: ${widget.userId}",
      "Timestamp: ${DateTime.now().toIso8601String()}",
      "Blood Group: $bloodGroup",
      "Required Quantity: $requiredQuantity",
      "Hospital: $hospitalName",
      "Location: $hospitalLocation",
    ];
    return requestData.join("\n");
  }


}

