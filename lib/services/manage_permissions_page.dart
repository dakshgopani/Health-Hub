import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class ManagePermissionsPage extends StatefulWidget {
  @override
  _ManagePermissionsPageState createState() => _ManagePermissionsPageState();
}

class _ManagePermissionsPageState extends State<ManagePermissionsPage> {
  final Map<Permission, String> _permissions = {
    Permission.location: 'Location',
    Permission.camera: 'Camera',
    Permission.storage: 'Storage',
  };

  Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    for (var permission in _permissions.keys) {
      statuses[permission] = await permission.status;
    }
    setState(() {
      _statuses = statuses;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      _statuses[permission] = status;
    });

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Permission permanently denied. Please enable it from app settings."),
          backgroundColor: Colors.red[400],
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  Widget _buildPermissionTile(Permission permission, String name) {
    final status = _statuses[permission];
    final isGranted = status?.isGranted ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isGranted ? Colors.green : Colors.redAccent,
          size: 30,
        ),
        title: Text(name, style: AppTextStyles.body),
        subtitle: Text(
          isGranted ? "Permission granted" : "Permission not granted",
          style:
              TextStyle(color: isGranted ? Colors.green[700] : Colors.red[700]),
        ),
        trailing: ElevatedButton(
          onPressed: () => _requestPermission(permission),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            "Request",
            style:
                TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Raleway'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text("Manage Permissions",
            style: AppTextStyles.whiteHeading
                .copyWith(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _statuses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                ..._permissions.entries.map(
                    (entry) => _buildPermissionTile(entry.key, entry.value)),
              ],
            ),
    );
  }
}
