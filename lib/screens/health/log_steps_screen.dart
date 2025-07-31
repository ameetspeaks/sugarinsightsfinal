import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/steps_service.dart';

class LogStepsScreen extends StatefulWidget {
  const LogStepsScreen({super.key});

  @override
  State<LogStepsScreen> createState() => _LogStepsScreenState();
}

class _LogStepsScreenState extends State<LogStepsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _stepsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String _selectedActivityType = 'walking';
  String _selectedSource = 'manual';

  final List<String> _activityTypes = ['walking', 'running', 'hiking', 'cycling', 'swimming', 'other'];
  final List<String> _sourceTypes = ['manual', 'device', 'app', 'import'];

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeController.text = _selectedTime.format(context);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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
        _dateController.text = _formatDate(_selectedDate);
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
        _timeController.text = _selectedTime.format(context);
      });
    }
  }

  Future<void> _saveSteps() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        final stepsService = StepsService();
        final stepsCount = int.parse(_stepsController.text);

        await stepsService.addStepsReading(
          stepsCount: stepsCount,
          activityType: _selectedActivityType,
          source: _selectedSource,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          readingDate: _selectedDate,
          readingTime: _selectedTime,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('$stepsCount steps saved successfully!'),
                ],
              ),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate data was updated
        }
      } catch (e) {
        print('❌ Error saving steps: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Error saving steps: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
          'Log Steps',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: 'Date',
                controller: _dateController,
                placeholder: 'DD-MM-YYYY',
                icon: Icons.calendar_today,
                onTap: _selectDate,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Time',
                controller: _timeController,
                placeholder: '00:00 AM',
                icon: Icons.access_time,
                onTap: _selectTime,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Steps Count',
                controller: _stepsController,
                placeholder: 'Enter number of steps',
                icon: Icons.directions_walk,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter steps count';
                  }
                  final steps = int.tryParse(value);
                  if (steps == null || steps <= 0) {
                    return 'Please enter a valid number of steps';
                  }
                  if (steps > 100000) {
                    return 'Steps count cannot exceed 100,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Activity Type',
                value: _selectedActivityType,
                items: _activityTypes.map((type) => 
                  DropdownMenuItem(value: type, child: Text(type.toUpperCase()))
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedActivityType = value;
                    });
                  }
                },
                icon: Icons.fitness_center,
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Source',
                value: _selectedSource,
                items: _sourceTypes.map((type) => 
                  DropdownMenuItem(value: type, child: Text(type.toUpperCase()))
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSource = value;
                    });
                  }
                },
                icon: Icons.source,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Notes (Optional)',
                controller: _notesController,
                placeholder: 'Add any notes about your activity',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSteps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Saving...'),
                          ],
                        )
                      : const Text(
                          'Save Steps',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: maxLines != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    keyboardType: keyboardType,
                    maxLines: maxLines ?? 1,
                    validator: validator,
                    inputFormatters: keyboardType == TextInputType.number
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
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
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  underline: const SizedBox(),
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 