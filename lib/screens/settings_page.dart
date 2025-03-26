import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/welcome_screen.dart'; // Ensure correct import

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricLogin = false;

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDECF4), // Matching theme
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF432C81), // Theme color
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Account"),
          _buildSettingsTile(
            icon: Icons.person,
            title: "Edit Profile",
            subtitle: "Update your name, email, and profile picture",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: "Security",
            subtitle: "Change password & manage security settings",
            onTap: () {},
          ),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: "Push Notifications",
            subtitle: "Receive health updates & reminders",
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: "Biometric Login",
            subtitle: "Enable fingerprint/Face ID login",
            value: _biometricLogin,
            onChanged: (value) {
              setState(() {
                _biometricLogin = value;
              });
            },
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Privacy & Permissions"),
          _buildSettingsTile(
            icon: Icons.security,
            title: "Manage Permissions",
            subtitle: "Control location, camera & storage access",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: "Delete Account",
            subtitle: "Permanently remove all data",
            onTap: () {
              _confirmDeleteAccount(context);
            },
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Health Preferences"),
          _buildSettingsTile(
            icon: Icons.medical_services,
            title: "Medical History",
            subtitle: "Manage your past diagnoses & reports",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.local_hospital,
            title: "Preferred Doctors",
            subtitle: "Set preferred healthcare providers",
            onTap: () {},
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Emergency"),
          _buildSettingsTile(
            icon: Icons.contact_phone,
            title: "Emergency Contacts",
            subtitle: "Set up contacts for medical emergencies",
            onTap: () {},
          ),

          const SizedBox(height: 30),
          Center(
            child: Text(
              "HealthHub v1.0.0",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),

          const SizedBox(height: 20),

          // 🚀 Logout Button
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text("Logout", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF432C81),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B4EFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF6B4EFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action is irreversible. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Perform delete operation
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
