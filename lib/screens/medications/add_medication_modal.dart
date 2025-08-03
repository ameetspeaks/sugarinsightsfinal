import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';

class AddMedicationModal extends StatefulWidget {
  final Function(Medication) onAdd;

  const AddMedicationModal({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _dosageController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 7)); // Default to 7 days

  @override
  void initState() {
    super.initState();
    _startDateController.text = _formatDate(_selectedStartDate);
    _endDateController.text = _formatDate(_selectedEndDate);
    _timeController.text = _formatTime(_selectedTime);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = _formatDate(picked);
        
        // Update end date to maintain 7-day duration if it's still the default
        final currentEndDate = _selectedEndDate;
        final expectedEndDate = picked.add(const Duration(days: 7));
        
        // If end date is exactly 7 days from the old start date, update it
        if (currentEndDate.difference(_selectedStartDate).inDays == 7) {
          _selectedEndDate = expectedEndDate;
          _endDateController.text = _formatDate(expectedEndDate);
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = _formatDate(picked);
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final medication = Medication(
        name: _nameController.text,
        dosage: _dosageController.text,
        times: [_selectedTime],
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        medicineType: 'Tablet',
        frequency: 'Once daily',
      );
      widget.onAdd(medication);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _dosageController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
              'Add Medication',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeController,
              readOnly: true,
              onTap: _selectTime,
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select time';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              onTap: _selectStartDate,
              onChanged: (value) {
                // Allow manual date entry
                if (value.isNotEmpty) {
                  try {
                    final parts = value.split('/');
                    if (parts.length == 3) {
                      final day = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final year = int.parse(parts[2]);
                      final date = DateTime(year, month, day);
                      if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                        setState(() {
                          _selectedStartDate = date;
                          
                          // Update end date to maintain 7-day duration if it's still the default
                          final currentEndDate = _selectedEndDate;
                          final expectedEndDate = date.add(const Duration(days: 7));
                          
                          // If end date is exactly 7 days from the old start date, update it
                          if (currentEndDate.difference(_selectedStartDate).inDays == 7) {
                            _selectedEndDate = expectedEndDate;
                            _endDateController.text = _formatDate(expectedEndDate);
                          }
                        });
                      }
                    }
                  } catch (e) {
                    // Invalid date format, ignore
                  }
                }
              },
              decoration: const InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                hintText: 'DD/MM/YYYY or tap to pick',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select start date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              onTap: _selectEndDate,
              onChanged: (value) {
                // Allow manual date entry
                if (value.isNotEmpty) {
                  try {
                    final parts = value.split('/');
                    if (parts.length == 3) {
                      final day = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final year = int.parse(parts[2]);
                      final date = DateTime(year, month, day);
                      if (date.isAfter(_selectedStartDate.subtract(const Duration(days: 1)))) {
                        setState(() {
                          _selectedEndDate = date;
                        });
                      }
                    }
                  } catch (e) {
                    // Invalid date format, ignore
                  }
                }
              },
              decoration: const InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                helperText: 'Default: 7 days from start date',
                hintText: 'DD/MM/YYYY or tap to pick',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select end date';
                }
                if (_selectedEndDate.isBefore(_selectedStartDate)) {
                  return 'End date cannot be before start date';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // Duration indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_selectedEndDate.difference(_selectedStartDate).inDays + 1} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quick duration presets
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = _selectedStartDate.add(const Duration(days: 6)); // 7 days
                        _endDateController.text = _formatDate(_selectedEndDate);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('7 Days', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = _selectedStartDate.add(const Duration(days: 13)); // 14 days
                        _endDateController.text = _formatDate(_selectedEndDate);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('14 Days', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = _selectedStartDate.add(const Duration(days: 29)); // 30 days
                        _endDateController.text = _formatDate(_selectedEndDate);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('30 Days', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Medication'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 