import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_entry.dart';
import '../../widgets/diet/food_entry_card.dart';
import '../../widgets/diet/add_diet_modal.dart';
import 'add_diet_intake_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Sample data - replace with actual data from backend
  final List<FoodEntry> _foodEntries = [
    FoodEntry(
      name: 'Aloo Paratha',
      description: 'Maine 2 aloo paratha khaya hai achar ke sath, paratha me maine butter lagaya tha.',
      timestamp: DateTime(2025, 1, 20, 22, 25),
      imageUrl: null, // Removed missing image asset
      calories: 300, // Added missing required parameter
      carbs: 45, // Added missing required parameter
      protein: 8, // Added missing required parameter
      fat: 12, // Added missing required parameter
      mealType: 'Breakfast', // Added missing required parameter
    ),
    FoodEntry(
      name: 'Milk Tea',
      description: 'Maine paratha chai ke sath khaya tha. chai me sugar ki dawa dalkar liya tha.',
      timestamp: DateTime(2025, 1, 20, 22, 25),
      imageUrl: null, // Removed missing image asset
      calories: 80, // Added missing required parameter
      carbs: 15, // Added missing required parameter
      protein: 2, // Added missing required parameter
      fat: 3, // Added missing required parameter
      mealType: 'Breakfast', // Added missing required parameter
    ),
    FoodEntry(
      name: 'Dahi',
      description: 'Maine paratha chai ke sath khaya tha. chai me sugar ki dawa dalkar liya tha.',
      timestamp: DateTime(2025, 1, 20, 22, 25),
      imageUrl: null, // Removed missing image asset
      calories: 60, // Added missing required parameter
      carbs: 8, // Added missing required parameter
      protein: 6, // Added missing required parameter
      fat: 2, // Added missing required parameter
      mealType: 'Breakfast', // Added missing required parameter
    ),
    FoodEntry(
      name: 'Gulab Jamun',
      description: 'Maine paratha chai ke sath khaya tha. chai me sugar ki dawa dalkar liya tha.',
      timestamp: DateTime(2025, 1, 20, 22, 25),
      imageUrl: null, // Removed missing image asset
      calories: 150, // Added missing required parameter
      carbs: 25, // Added missing required parameter
      protein: 2, // Added missing required parameter
      fat: 5, // Added missing required parameter
      mealType: 'Dessert', // Added missing required parameter
    ),
  ];

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
    }
  }

  void _handleEdit(FoodEntry entry) {
    // TODO: Implement edit functionality
  }

  void _handleDelete(FoodEntry entry) {
    setState(() {
      _foodEntries.remove(entry);
    });
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
          // Title and Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Diet Intake',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

          // Food Entries List
          Expanded(
            child: ListView.builder(
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