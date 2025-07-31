import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_entry.dart';
import '../../services/food_service.dart';
import '../../widgets/diet/food_entry_card.dart';
import '../../widgets/diet/add_diet_modal.dart';
import 'add_diet_intake_screen.dart';
import 'edit_food_entry_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late FoodService _foodService;
  List<FoodEntry> _foodEntries = [];
  bool _isLoading = false;
  Map<String, dynamic>? _nutritionSummary;

  @override
  void initState() {
    super.initState();
    _foodService = FoodService(Supabase.instance.client);
    _testDatabaseAndLoadData();
  }

  Future<void> _testDatabaseAndLoadData() async {
    try {
      // Test database connection first
      await _foodService.testDatabaseConnection();
      // If successful, load food entries
      await _loadFoodEntries();
    } catch (e) {
      print('Database test failed: $e');
      // Still try to load food entries even if test fails
      await _loadFoodEntries();
    }
  }

  void _showAddDietModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => AddDietModal(
        onAdd: (entry) {
          setState(() {
            _foodEntries.insert(0, entry);
          });
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadFoodEntries(); // Reload data for the new date
    }
  }

  Future<void> _loadFoodEntries() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _foodService.getFoodEntries(date: _selectedDate);
      final summary = await _foodService.getDailyNutritionSummary(_selectedDate);
      
      if (mounted) {
        setState(() {
          _foodEntries = entries;
          _nutritionSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading food entries: $e')),
        );
      }
    }
  }

  Future<void> _handleEdit(FoodEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoodEntryScreen(foodEntry: entry),
      ),
    );
    
    // If edit was successful, reload the data
    if (result == true) {
      await _loadFoodEntries();
    }
  }

  Future<void> _handleDelete(FoodEntry entry) async {
    if (entry.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete entry without ID')),
      );
      return;
    }

    try {
      await _foodService.deleteFoodEntry(entry.id!);
      await _loadFoodEntries(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food entry deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting food entry: $e')),
        );
      }
    }
  }

  Widget _buildNutritionCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
          'Diet Intake',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddDietIntakeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Diet'),
                ),
              ],
            ),
          ),

          // Search and Date Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search added food',
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
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Nutrition Summary
          if (_nutritionSummary != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Nutrition Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutritionCard(
                          'Calories',
                          '${_nutritionSummary!['total_calories']}',
                          'kcal',
                          Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNutritionCard(
                          'Carbs',
                          '${_nutritionSummary!['total_carbs'].toStringAsFixed(1)}',
                          'g',
                          Icons.grain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNutritionCard(
                          'Protein',
                          '${_nutritionSummary!['total_protein'].toStringAsFixed(1)}',
                          'g',
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNutritionCard(
                          'Fat',
                          '${_nutritionSummary!['total_fat'].toStringAsFixed(1)}',
                          'g',
                          Icons.opacity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Food Entries List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foodEntries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No food entries for today',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first meal to start tracking',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _foodEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _foodEntries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FoodEntryCard(
                              entry: entry,
                              onEdit: () => _handleEdit(entry),
                              onDelete: () => _handleDelete(entry),
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