import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final VoidCallback onClear;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Raleway',
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blueGrey,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1F41BB)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFF1F41BB)),
          onPressed: onClear,
        ),
      ),
    );
  }
}

class CustomPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const CustomPasswordField({
    Key? key,
    required this.label,
    required this.controller,
    required this.icon,
  }) : super(key: key);

  @override
  _CustomPasswordFieldState createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Raleway',
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blueGrey,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(widget.icon, color: const Color(0xFF1F41BB)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF1F41BB),
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? assetPath; // For Google Image
  final IconData? icon; // For Facebook & Apple Icons
  final Color? iconColor;

  const SocialLoginButton({
    Key? key,
    required this.onTap,
    this.assetPath,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: assetPath != null
              ? Image.asset(assetPath!, width: 50, height: 50) // Google Image
              : FaIcon(icon,
                  size: 30, color: iconColor), // Facebook & Apple Icon
        ),
      ),
    );
  }
}
