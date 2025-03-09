import 'package:flutter/material.dart';

class AddRequestScreen extends StatefulWidget {
  @override
  _AddRequestScreenState createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController quantityController = TextEditingController();
  TextEditingController hospitalController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  List<String> bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];
  String? selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    // Show the dialog as soon as the screen is built
    Future.delayed(Duration.zero, () => _showAddRequestDialog());
  }

  void _showAddRequestDialog() {
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
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
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
                        prefixIcon: Icon(Icons.bloodtype, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                      value: selectedBloodGroup,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
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
                        setState(() {
                          selectedBloodGroup = newValue!;
                        });
                      },
                      validator: (value) =>
                      value == null ? "Please select a blood group" : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Fields
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
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(), // Returning an empty container instead of throwing an error
    );
  }
}
