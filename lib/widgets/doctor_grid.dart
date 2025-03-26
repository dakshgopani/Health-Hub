import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class SpecializationGrid extends StatelessWidget {
  final Function(String specialization) onSpecializationSelected;

  SpecializationGrid({required this.onSpecializationSelected, Key? key})
      : super(key: key);

  final List<Map<String, dynamic>> specializations = [
    {'name': 'General Physician', 'icon': FontAwesomeIcons.stethoscope},
    // General health
    {'name': 'Dermatologist', 'icon': FontAwesomeIcons.bacteria},
    // Skin specialist
    {'name': 'Cardiologist', 'icon': FontAwesomeIcons.heartPulse},
    // Heart specialist
    {'name': 'Neurologist', 'icon': FontAwesomeIcons.brain},
    // Brain & nervous system specialist
    {'name': 'Psychiatrist', 'icon': FontAwesomeIcons.userDoctor},
    // Mental health doctor
    {
      'name': 'Internal Medicine Specialist',
      'icon': FontAwesomeIcons.hospitalUser
    },
    // General internal medicine
    {'name': 'Rheumatologist', 'icon': FontAwesomeIcons.handHoldingMedical},
    // Joint & arthritis specialist
    {'name': 'Gynecologist', 'icon': FontAwesomeIcons.personPregnant},
    // Pregnancy & women's health
    {'name': 'Pediatrician', 'icon': Icons.child_care},
    // Childcare specialist
    {'name': 'Bariatric Surgeon', 'icon': FontAwesomeIcons.weightScale},
    // Weight loss surgery
    {'name': 'Hematologist', 'icon': FontAwesomeIcons.droplet},
    // Blood specialist
    {'name': 'Ophthalmologist', 'icon': FontAwesomeIcons.eye},
    // Eye specialist
    {'name': 'Orthopedic Surgeon', 'icon': FontAwesomeIcons.bone},
    // Bone & joint specialist
    {'name': 'Endocrinologist', 'icon': FontAwesomeIcons.dna},
    // Hormonal disorders
    {'name': 'Plastic Surgeon', 'icon': FontAwesomeIcons.user},
    // Cosmetic surgery
    {'name': 'Nephrologist', 'icon': FontAwesomeIcons.handHoldingDroplet},
    // Kidney specialist (Alternative: FontAwesomeIcons.prescriptionBottle)
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 items per row
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Slightly taller
      ),
      itemCount: specializations.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            onSpecializationSelected(specializations[index]['name']);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 2,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.deepPurple.withOpacity(0.1),
                  child: Icon(
                    specializations[index]['icon'],
                    size: 32,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  specializations[index]['name'],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
