import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_entry.dart';

class AddDietModal extends StatefulWidget {
  final Function(FoodEntry) onAdd;

  const AddDietModal({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddDietModal> createState() => _AddDietModalState();
}

class _AddDietModalState extends State<AddDietModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedImagePath;

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final entry = FoodEntry(
        name: _nameController.text,
        description: _descriptionController.text,
        timestamp: DateTime.now(),
        imageUrl: _selectedImagePath,
        calories: 0, // Added missing required parameter (default value)
        carbs: 0.0, // Added missing required parameter (default value)
        protein: 0.0, // Added missing required parameter (default value)
        fat: 0.0, // Added missing required parameter (default value)
        mealType: 'Breakfast', // Added missing required parameter (default value)
      );
      widget.onAdd(entry);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Diet Entry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Food Image Picker
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Food Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter food name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Enter food description in Hindi...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Add Button
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }
} 