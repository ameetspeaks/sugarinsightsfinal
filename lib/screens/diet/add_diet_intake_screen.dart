import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_entry.dart';
import '../../providers/health_data_provider.dart';
import 'package:provider/provider.dart';

class AddDietIntakeScreen extends StatefulWidget {
  const AddDietIntakeScreen({super.key});

  @override
  State<AddDietIntakeScreen> createState() => _AddDietIntakeScreenState();
}

class _AddDietIntakeScreenState extends State<AddDietIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedUnit = 'Piece';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedImagePath;
  bool _isUploading = false;

  final List<String> _unitOptions = [
    'Piece',
    'Gram',
    'Kilogram',
    'Cup',
    'Tablespoon',
    'Teaspoon',
    'Slice',
    'Portion',
    'Bowl',
    'Glass'
  ];

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Diet Intake',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Input
              _buildInputField(
                label: 'Food',
                controller: _foodNameController,
                placeholder: 'Enter food name',
                icon: Icons.mic,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
                                                                                                                     // Unit and Quantity Row
                 Row(
                   children: [
                     // Unit Dropdown
                     Expanded(
                       child: _buildDropdownField(
                         label: 'Unit',
                         value: _selectedUnit,
                         items: _unitOptions,
                         placeholder: 'Eg: Piece',
                         onChanged: (String? newValue) {
                           if (newValue != null) {
                             setState(() {
                               _selectedUnit = newValue;
                             });
                           }
                         },
                       ),
                     ),
                     
                     const SizedBox(width: 15),
                     
                     // Quantity Input
                     Expanded(
                       child: _buildInputField(
                         label: 'Quantity',
                         controller: _quantityController,
                         placeholder: 'Enter Quantity',
                         keyboardType: TextInputType.number,
                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Please enter quantity';
                           }
                           return null;
                         },
                       ),
                     ),
                   ],
                 ),
              
              const SizedBox(height: 24),
              
                             // Date and Time Row
               Column(
                 children: [
                   // Date Input
                   _buildInputField(
                     label: 'Date',
                     controller: TextEditingController(
                       text: '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                     ),
                     placeholder: 'DD-MM-YYYY',
                     icon: Icons.calendar_today,
                     onTap: _selectDate,
                     readOnly: true,
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Time Input
                   _buildInputField(
                     label: 'Time',
                     controller: TextEditingController(
                       text: _selectedTime.format(context),
                     ),
                     placeholder: 'HH:MM:AM',
                     icon: Icons.access_time,
                     onTap: _selectTime,
                     readOnly: true,
                   ),
                 ],
               ),
              
              const SizedBox(height: 24),
              
              // Description
              _buildInputField(
                label: 'Description',
                controller: _descriptionController,
                placeholder: 'Enter Description',
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Image Upload Section
              Text(
                'Upload Image',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              
                             Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   ElevatedButton.icon(
                     onPressed: _uploadImage,
                     icon: const Icon(Icons.upload_file),
                     label: const Text('Upload File'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primaryColor,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(
                         child: Text(
                           _selectedImagePath ?? 'No file chosen',
                           style: TextStyle(
                             fontSize: 14,
                             color: Colors.grey[600],
                           ),
                         ),
                       ),
                       if (_selectedImagePath != null)
                         GestureDetector(
                           onTap: () {
                             setState(() {
                               _selectedImagePath = null;
                             });
                           },
                           child: Icon(
                             Icons.close,
                             color: Colors.red,
                             size: 20,
                           ),
                         ),
                     ],
                   ),
                 ],
               ),
              
              const SizedBox(height: 8),
              
                             // File format warning
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.green[50],
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.green[200]!),
                 ),
                 child: Row(
                   children: [
                     Icon(
                       Icons.check_circle,
                       color: Colors.green[700],
                       size: 20,
                     ),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'file should be in Jpg/png format (5 mb).',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.green[700],
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
              
              const SizedBox(height: 40),
              
                             // Action Buttons
               Column(
                 children: [
                   // Cancel Button
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton(
                       onPressed: () => Navigator.pop(context),
                       style: OutlinedButton.styleFrom(
                         foregroundColor: Colors.red,
                         side: const BorderSide(color: Colors.red),
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                       ),
                       child: const Text(
                         'Cancel',
                         style: TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 12),
                   
                   // Update Button
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: _createDietEntry,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.orange,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                         elevation: 0,
                       ),
                       child: const Text(
                         'Update',
                         style: TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    IconData? icon,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: maxLines > 1 ? null : 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      readOnly: readOnly,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      maxLines: maxLines,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      icon,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required String placeholder,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 43,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
              icon: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    // Simulate image upload
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _selectedImagePath = 'food_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image uploaded successfully!'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _createDietEntry() {
    if (_formKey.currentState!.validate()) {
      final foodEntry = FoodEntry(
        name: _foodNameController.text,
        description: _descriptionController.text,
        timestamp: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        imageUrl: _selectedImagePath,
        calories: 0, // Will be calculated based on food
        carbs: 0,
        protein: 0,
        fat: 0,
        mealType: 'Custom',
      );

      // Save to provider
      final healthDataProvider = Provider.of<HealthDataProvider>(context, listen: false);
      healthDataProvider.addFoodEntry(foodEntry);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diet entry created successfully!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

      Navigator.pop(context);
    }
  }
} 