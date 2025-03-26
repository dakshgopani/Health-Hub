import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart'; // For bookmarking

class MedicineRecommender extends StatefulWidget {
  @override
  _MedicineRecommenderState createState() => _MedicineRecommenderState();
}

class _MedicineRecommenderState extends State<MedicineRecommender> {
  String? selectedSymptom;
  Map<String, dynamic>? selectedMedicineData;
  Map<String, List<String>> categorizedSymptoms =
      {}; // Symptoms grouped by category
  Map<String, dynamic> medicineData = {};
  List<String> allSymptoms = []; // Add this to store all unique symptoms
  List<String> bookmarkedSymptoms = [];
  bool isDarkMode = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMedicineData();
    loadBookmarks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadMedicineData() async {
    String jsonString =
    await rootBundle.loadString('assets/json/medicine_recommendation.json');
    Map<String, dynamic> rawData = json.decode(jsonString);

    setState(() {
      medicineData = rawData;
      categorizedSymptoms = categorizeSymptoms(rawData);
      // Extract all unique symptoms from medicineData
      allSymptoms = rawData.keys.toList();
    });
  }
  Future<void> loadBookmarks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      bookmarkedSymptoms = (prefs.getStringList('bookmarkedSymptoms') ?? [])
          .toSet()
          .toList(); // Ensure no duplicates in bookmarks
    });
  }
  Future<void> toggleBookmark(String symptom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (bookmarkedSymptoms.contains(symptom)) {
        bookmarkedSymptoms.remove(symptom);
      } else {
        bookmarkedSymptoms.add(symptom);
      }
      prefs.setStringList('bookmarkedSymptoms', bookmarkedSymptoms);
    });
  }

  Map<String, List<String>> categorizeSymptoms(Map<String, dynamic> data) {
    Map<String, List<String>> categories = {
      "Digestive Issues": [],
      "Respiratory Problems": [],
      "Pain & Discomfort": [],
      "Skin Conditions": [],
      "Neurological & Mental Health": [],
      "Circulatory & Heart Conditions": [],
      "General Health": [],
    };

    for (var symptom in data.keys) {
      if ([
        "Diarrhea",
        "Constipation",
        "Nausea",
        "Vomiting",
        "Acidity",
        "Stomach Pain",
        "Heartburn",
        "Gas",
      ].contains(symptom)) {
        categories["Digestive Issues"]!.add(symptom);
      } else if ([
        "Cough",
        "Cold",
        "Sore Throat",
      ].contains(symptom)) {
        categories["Respiratory Problems"]!.add(symptom);
      } else if ([
        "Headache",
        "Migraine",
        "Muscle Pain",
        "Back Pain",
        "Toothache",
        "Ear Pain",
      ].contains(symptom)) {
        categories["Pain & Discomfort"]!.add(symptom);
      } else if ([
        "Skin Rash",
        "Sunburn",
        "Burns",
        "Cold Sores",
        "Allergy",
      ].contains(symptom)) {
        categories["Skin Conditions"]!.add(symptom);
      } else if ([
        "Dizziness",
        "Insomnia",
        "Anxiety",
        "Fatigue",
      ].contains(symptom)) {
        categories["Neurological & Mental Health"]!.add(symptom);
      } else if ([
        "Eye Redness",
        "PMS Symptoms",
        "Motion Sickness",
      ].contains(symptom)) {
        categories["General Health"]!.add(symptom);
      } else {
        categories["General Health"]!.add(symptom);
      }
    }
    return categories;
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use system dark mode or our toggle
    bool effectiveDarkMode =
        Theme.of(context).brightness == Brightness.dark || isDarkMode;

    ThemeData theme = effectiveDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.tealAccent,
            cardColor: Colors.grey[850],
            scaffoldBackgroundColor: Colors.black,
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            cardColor: Colors.white,
            scaffoldBackgroundColor: Colors.grey[100],
          );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Medicine Recommender",
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.bold,
              color: Colors.white, // Ensures good contrast
            ),
          ),
          backgroundColor: effectiveDarkMode ? Colors.black : Colors.deepPurple,
          elevation: 4, // Adds a slight shadow for better depth
          shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark, color: Colors.amber),
              onPressed: () => showBookmarkedSymptoms(),
              tooltip: "Bookmarked Symptoms",
            ),
            IconButton(
              icon: Icon(
                effectiveDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white, // Ensures it matches the theme
              ),
              onPressed: toggleDarkMode,
              tooltip: "Toggle Dark Mode",
            ),
          ],
        ),

        body: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(10),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: effectiveDarkMode
                      ? Colors.grey[900]
                      : Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I have...",
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.bold,
                        color: effectiveDarkMode
                            ? Colors.deepPurpleAccent
                            : Colors.deepPurple[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Symptom Dropdown grouped by category
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), // Increased for better UI
                        border: Border.all(
                          color: effectiveDarkMode
                              ? Colors.deepPurpleAccent.withOpacity(0.6)
                              : Colors.deepPurple.withOpacity(0.6),
                          width: 1.5, // Slightly thicker for visibility
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedSymptom,
                        hint: Text(
                          "Select a symptom",
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: effectiveDarkMode
                                ? Colors.deepPurpleAccent
                                : Colors.deepPurple[700],
                          ),
                        ),
                        items: buildDropdownItems(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedSymptom = value;
                            selectedMedicineData = medicineData[value];
                          });
                        },
                        decoration: const InputDecoration(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        dropdownColor:
                        effectiveDarkMode ? Colors.grey[900] : Colors.white,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: effectiveDarkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurple[700],
                        ),
                        isExpanded: true, // Prevents overflow
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Selected symptom display
              if (selectedSymptom != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: effectiveDarkMode
                        ? Colors.deepPurpleAccent.withOpacity(0.2) // Dark mode color
                        : Colors.deepPurple[700]!.withOpacity(0.1), // Light mode color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        getSymptomIcon(selectedSymptom!),
                        size: 28,
                        color:
                            effectiveDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "📌 You have selected: $selectedSymptom",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.bold,
                            color: effectiveDarkMode
                                ? Colors.white
                                : Colors.deepPurple[900],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          bookmarkedSymptoms.contains(selectedSymptom)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => toggleBookmark(selectedSymptom!),
                        tooltip: "Bookmark this symptom",
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Medicine details
              if (selectedMedicineData != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMedicineHeader(selectedMedicineData!["medicine"],
                            effectiveDarkMode),
                        const Divider(height: 24, thickness: 1),
                        _buildInfoSection(
                            "💊 Recommended Medicine",
                            selectedMedicineData!["medicine"],
                            effectiveDarkMode),
                        _buildInfoSection("📏 Dosage",
                            selectedMedicineData!["dosage"], effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildSeverityLevels(
                            selectedMedicineData!["severity_levels"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildListSection(
                            "⚠️ Precautions",
                            selectedMedicineData!["precautions"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildListSection(
                            "❌ Side Effects",
                            selectedMedicineData!["side_effects"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildListSection(
                            "🔀 Drug Interactions",
                            selectedMedicineData!["drug_interactions"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildListSection(
                            "✅ Alternative Treatments",
                            selectedMedicineData!["alternative_treatments"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildAgeSpecificRecommendations(
                            selectedMedicineData![
                                "age_specific_recommendations"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                            "🏪 Availability",
                            selectedMedicineData!["availability"],
                            effectiveDarkMode),
                        const SizedBox(height: 16),
                        _buildBrandNames(selectedMedicineData!["brand_names"],
                            effectiveDarkMode),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> buildDropdownItems() {
    List<DropdownMenuItem<String>> items = [];

    // Add bookmarked section at the top if there are bookmarks
    if (bookmarkedSymptoms.isNotEmpty) {
      items.add(const DropdownMenuItem<String>(
        enabled: false,
        child: Text("⭐ Bookmarked",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber,fontFamily: 'Raleway')),
      ));

      items.addAll(bookmarkedSymptoms.map((symptom) {
        return DropdownMenuItem<String>(
          value: symptom,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(
                  bookmarkedSymptoms.contains(symptom)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 5),
                Icon(
                  getSymptomIcon(symptom),
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    symptom,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }));

      // Add a separator
      items.add(const DropdownMenuItem<String>(
        enabled: false,
        child: Divider(),
      ));
    }

    // Add all categories and their symptoms
    // Track symptoms already added to avoid duplicates
    Set<String> addedSymptoms = bookmarkedSymptoms.toSet();

    categorizedSymptoms.forEach((category, symptoms) {
      if (symptoms.isNotEmpty) {
        items.add(DropdownMenuItem<String>(
          enabled: false,
          child: Text(category,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.teal,fontFamily: 'Raleway')),
        ));

        items.addAll(symptoms.where((symptom) => !addedSymptoms.contains(symptom)).map((symptom) {
          addedSymptoms.add(symptom); // Add to tracking set
          return DropdownMenuItem<String>(
            value: symptom,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    bookmarkedSymptoms.contains(symptom)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    getSymptomIcon(symptom),
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      symptom,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }));
      }
    });

    return items;
  }
  IconData getSymptomIcon(String symptom) {
    Map<String, IconData> icons = {
      "Headache": Icons.sick,
      "Cough": Icons.coronavirus,
      "Cold": Icons.ac_unit,
      "Fever": Icons.thermostat,
      "Nausea": Icons.sick,
      "Diarrhea": Icons.wc,
      "Vomiting": Icons.sick,
      "Constipation": Icons.do_not_disturb_on,
      "Sunburn": Icons.wb_sunny,
      "Sore Throat": Icons.record_voice_over, // Changed from mic
      "Muscle Pain": Icons.fitness_center,
      "Toothache": Icons.medical_services, // Changed from emoji_food_beverage
      "Insomnia": Icons.nightlight_round,
      "Anxiety": Icons.psychology,
      "Acidity": Icons.local_fire_department,
      "Stomach Pain": Icons.medical_services,
      "Allergy": Icons.grass, // Changed from spa
      "Back Pain": Icons.accessibility_new, // Changed from chair
      "Migraine": Icons.flash_on, // Changed from lightbulb
      "Heartburn": Icons.local_fire_department,
      "Dizziness": Icons.sync_problem,
      "Gas": Icons.cloud,
      "Eye Redness": Icons.remove_red_eye,
      "Skin Rash": Icons.texture, // Changed from brush
      "Ear Pain": Icons.hearing,
      "Burns": Icons.whatshot,
      "Motion Sickness": Icons.directions_car,
      "Cold Sores": Icons.tag_faces, // Changed from mood
      "PMS Symptoms": Icons.female,
      "Fatigue": Icons.hourglass_empty, // Changed from battery_alert
    };
    return icons[symptom] ?? Icons.medical_services;
  }

  void showBookmarkedSymptoms() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Title
            Text(
              "📌 Bookmarked Symptoms",
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[700],
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Stylish Divider
            Divider(
              color: Colors.deepPurple[300],
              thickness: 1.5,
            ),

            // 🔹 No Bookmarks - Animated Placeholder
            if (bookmarkedSymptoms.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.bookmark_border, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    "No bookmarked symptoms yet!",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,

                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              )
            else
            // 🔹 Bookmarked List
              SizedBox(
                height: 300, // Limits height for smooth scrolling
                child: ListView.builder(
                  itemCount: bookmarkedSymptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = bookmarkedSymptoms[index];
                    return Card(
                      color: Colors.deepPurple[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          getSymptomIcon(symptom),
                          color: Colors.teal[700],
                        ),
                        title: Text(
                          symptom,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔹 View Recommendations
                            IconButton(
                              icon: const Icon(Icons.medical_services, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  selectedSymptom = symptom;
                                  selectedMedicineData = medicineData[symptom];
                                });
                                Navigator.pop(context);
                              },
                              tooltip: "View recommendations",
                            ),
                            // 🔹 Remove Bookmark
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                toggleBookmark(symptom);
                                Navigator.pop(context);
                                showBookmarkedSymptoms();
                              },
                              tooltip: "Remove bookmark",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineHeader(String medicine, bool darkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.deepPurpleAccent.withOpacity(0.2)
            : Colors.deepPurple[700]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medical_services,
            size: 28,
            color: darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              medicine,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Raleway',
                color:
                    darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, dynamic value, bool darkMode) {
    if (value == null) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title: ",
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
          ),
        ),
        Expanded(
          child: Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, dynamic list, bool darkMode) {
    if (list == null || list.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: darkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color:
                  darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          ...list
              .map<Widget>((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        Expanded(
                            child: Text(item,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway', // Apply Raleway font
                                ))),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSeverityLevels(dynamic data, bool darkMode) {
    if (data == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: darkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🔥 Severity Levels",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color:
                  darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          ...data.keys.map<Widget>((key) {
            Color severityColor;
            IconData severityIcon;

            if (key.toString().toLowerCase().contains("mild")) {
              severityColor = Colors.green;
              severityIcon = Icons.check_circle;
            } else if (key.toString().toLowerCase().contains("moderate")) {
              severityColor = Colors.orange;
              severityIcon = Icons.warning;
            } else {
              severityColor = Colors.red;
              severityIcon = Icons.error;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Fix for overflow
                children: [
                  Icon(severityIcon, size: 16, color: severityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    // Ensures text does not overflow
                    child: Text(
                      "$key: ${data[key]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                        fontSize: 16,
                        fontFamily: 'Raleway',
                      ),
                      softWrap: true, // Enables wrapping
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAgeSpecificRecommendations(dynamic data, bool darkMode) {
    if (data == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: darkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👶 Age-Specific Recommendations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
              color:
                  darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          ...data.keys.map<Widget>((key) {
            IconData ageIcon;

            if (key.toString().toLowerCase().contains("child")) {
              ageIcon = Icons.child_care;
            } else if (key.toString().toLowerCase().contains("adult")) {
              ageIcon = Icons.person;
            } else if (key.toString().toLowerCase().contains("elderly")) {
              ageIcon = Icons.elderly;
            } else {
              ageIcon = Icons.people;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ageIcon, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          color: darkMode ? Colors.white : Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: key.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          TextSpan(text: ": ${data[key]}"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBrandNames(dynamic brands, bool darkMode) {
    if (brands == null || brands.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: darkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💊 Brand Names",
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.bold,
              color:
                  darkMode ? Colors.deepPurpleAccent : Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brands
                .map<Widget>((brand) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? Colors.deepPurpleAccent.withOpacity(0.2)
                            : Colors.deepPurple[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: darkMode
                              ? Colors.deepPurpleAccent.withOpacity(0.3)
                              : Colors.deepPurple[700]!.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        brand,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          color: darkMode
                              ? Colors.deepPurpleAccent
                              : Colors.deepPurple[700],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
