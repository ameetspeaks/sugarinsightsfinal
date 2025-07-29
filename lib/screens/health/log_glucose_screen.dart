import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/glucose_service.dart';

class LogGlucoseScreen extends StatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  State<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends State<LogGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glucoseValueController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'fasting';
  bool _isLoading = false;

  final List<String> _readingTypes = [
    'fasting',
    'post_meal',
    'random',
    'before_meal',
    'after_meal'
  ];

  @override
  void dispose() {
    _glucoseValueController.dispose();
    _notesController.dispose();
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
          'Log Glucose Reading',
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
              // Glucose Type Selection
              _buildDropdownField(
                label: 'Reading Type',
                value: _selectedType,
                items: _readingTypes,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
                itemBuilder: (String type) {
                  return Text(_getReadingTypeDisplayName(type));
                },
              ),
              
              const SizedBox(height: 24),
              
              // Glucose Value
              _buildInputField(
                label: 'Glucose Value (mg/dL)',
                controller: _glucoseValueController,
                placeholder: '120',
                icon: Icons.monitor_heart,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              
              const SizedBox(height: 24),
              
              // Measurement Date
              _buildInputField(
                label: 'Measurement Date',
                controller: TextEditingController(
                  text: '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                ),
                placeholder: 'DD-MM-YYYY',
                icon: Icons.calendar_today,
                onTap: _selectDate,
                readOnly: true,
              ),
              
              const SizedBox(height: 24),
              
              // Measurement Time
              _buildInputField(
                label: 'Measurement Time',
                controller: TextEditingController(
                  text: _selectedTime.format(context),
                ),
                placeholder: '00:00 AM',
                icon: Icons.access_time,
                onTap: _selectTime,
                readOnly: true,
              ),
              
              const SizedBox(height: 24),
              
              // Notes
              _buildInputField(
                label: 'Notes (Optional)',
                controller: _notesController,
                placeholder: 'Add any notes about this reading...',
                icon: Icons.note,
                maxLines: 3,
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGlucoseReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReadingTypeDisplayName(String type) {
    switch (type) {
      case 'fasting':
        return 'Fasting';
      case 'post_meal':
        return 'Post Meal';
      case 'random':
        return 'Random';
      case 'before_meal':
        return 'Before Meal';
      case 'after_meal':
        return 'After Meal';
      default:
        return type;
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: itemBuilder(item),
                  ),
                );
              }).toList(),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
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
      lastDate: DateTime.now(), // Prevent future dates
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
      // Check if selected date is today and time is in the future
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );
      
      if (selectedDateTime.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot select future time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedTime = picked;
      });
    }
  }



  Future<void> _saveGlucoseReading() async {
    if (_formKey.currentState!.validate()) {
      final glucoseValue = int.tryParse(_glucoseValueController.text);
      
      if (glucoseValue == null || glucoseValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid glucose value'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for future date/time
      final readingDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      if (readingDate.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save readings for future date/time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final glucoseService = GlucoseService();
        final readingDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        await glucoseService.addGlucoseReading(
          readingType: _selectedType,
          glucoseValue: glucoseValue,
          unit: 'mg/dL',
          mealContext: _selectedType == 'post_meal' ? 'After meal' : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          readingDate: readingDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Glucose reading logged successfully!'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving glucose reading: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
} 