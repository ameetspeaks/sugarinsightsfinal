import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';
import '../../widgets/dashboard/bottom_nav_bar.dart';
import '../../widgets/education/education_category_card.dart';
import '../../models/education_category.dart';
import 'medical_nutrition_therapy_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final _searchController = TextEditingController();


  // Sample education categories data
  final List<EducationCategory> _categories = [
    EducationCategory(
      id: '1',
      name: 'Medical Nutrition Therapy',
      icon: Icons.restaurant,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '2',
      name: 'Physical Activity & Exercise',
      icon: Icons.fitness_center,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '3',
      name: 'Yoga & Diabetes',
      icon: Icons.self_improvement,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '4',
      name: 'Insulin Management Education',
      icon: Icons.medication,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '5',
      name: 'Weight Management',
      icon: Icons.monitor_weight,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '6',
      name: 'Good Sleep Habits',
      icon: Icons.bedtime,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '7',
      name: 'Diabetes Complications',
      icon: Icons.medical_services,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '8',
      name: 'Psychosocial Care',
      icon: Icons.favorite,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '9',
      name: 'Intermittent Fasting',
      icon: Icons.schedule,
      articleCount: 14,
      blogCount: 10,
    ),
    EducationCategory(
      id: '10',
      name: 'Blood Pressure Management',
      icon: Icons.favorite_border,
      articleCount: 14,
      blogCount: 10,
    ),
  ];

  List<EducationCategory> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _categories;
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddCategoryModal() {
    // TODO: Implement add category modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add New Category functionality coming soon!'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _onCategoryTap(EducationCategory category) {
    if (category.name == 'Medical Nutrition Therapy') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MedicalNutritionTherapyScreen(),
        ),
      );
    } else {
      // TODO: Navigate to other category detail screens
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${category.name} feature coming soon!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Education',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Title and Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Blog Category',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add New',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCategories,
              decoration: InputDecoration(
                hintText: 'Search Patients Name/Unique Number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                final isEven = index % 2 == 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EducationCategoryCard(
                    category: category,
                    backgroundColor: isEven ? Colors.white : Colors.grey[50]!,
                    onTap: () => _onCategoryTap(category),
                  ),
                );
              },
            ),
          ),
        ],
             ),
     );
  }
} 