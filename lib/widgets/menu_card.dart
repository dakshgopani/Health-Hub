import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 10,
        shadowColor: Color(0xFFF5F3FF),
        color: const Color(0xFFF5F3FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Raleway',
                    color: Color(0xFF432C81),
                  ),
                ),
              ),
              Image.asset(
                imagePath,
                width: 144,
                height: 108,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
