import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/manage_permissions_page.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'auth/welcome_screen.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white,
          weight: 900,
          size: 26,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Account"),
          _buildSettingsTile(
            icon: Icons.person,
            title: "Edit Profile",
            subtitle: "Update your name and email",
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => EditProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
              ));
            },
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
          const SizedBox(height: 20),
          _buildSectionTitle("Privacy & Permissions"),
          _buildSettingsTile(
            icon: Icons.security,
            title: "Manage Permissions",
            subtitle: "Control location, camera & storage access",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManagePermissionsPage()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: "Delete Account",
            subtitle: "Permanently remove all data",
            onTap: () {
              _confirmDeleteAccount(context);
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              "HealthHub v1.0.0",
              style: AppTextStyles.body.copyWith(color: Colors.grey[700], fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Raleway',
                ),
              ),
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
        style: AppTextStyles.heading.copyWith(color: AppColors.deepPurple),
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
      leading: Icon(icon, color: AppColors.textPurple),
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle,style: TextStyle(fontWeight: FontWeight.w700,
        fontFamily: 'Raleway',    fontSize: 14,
      ),),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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
      secondary: Icon(icon, color: AppColors.textPurple),
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle,style: TextStyle(fontWeight: FontWeight.w700,
        fontFamily: 'Raleway',    fontSize: 14,
      ),),      value: value,
      onChanged: onChanged,
    );
  }

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


  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: AppColors.scaffoldBackground,
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color: AppColors.deepPurple,
            ),
          ),
          content: const Text(
            'This action is irreversible. Are you sure you want to delete your account and all associated data?',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Raleway',
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                User? user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  try {
                    await user.delete();

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                          (route) => false,
                    );

                    _showSnackBar("Account deleted successfully.");

                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'requires-recent-login') {
                      _showSnackBar('Please log in again and try deleting your account.');
                    } else {
                      _showSnackBar("Error: ${e.message}");
                    }
                  } catch (e) {
                    _showSnackBar("Failed to delete account.");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
