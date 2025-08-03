import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';
import '../../services/medication_service.dart';

class LogMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const LogMedicationScreen({
    super.key,
    this.medication,
  });

  @override
  State<LogMedicationScreen> createState() => _LogMedicationScreenState();
}

class _LogMedicationScreenState extends State<LogMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late MedicationService _medicationService;
  bool _isLoading = false;
  
  // Controllers for all input fields
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedMedicineType = 'Tablet';
  String _selectedFrequency = 'Once daily';
  TimeOfDay _selectedTime1 = TimeOfDay.now();
  TimeOfDay _selectedTime2 = TimeOfDay.now();
  TimeOfDay _selectedTime3 = TimeOfDay.now();
  TimeOfDay _selectedTime4 = TimeOfDay.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  final List<String> _medicineTypes = [
    'Tablet',
    'Syrup',
    'Capsule',
    'Injection',
    'Inhaler',
    'Drops',
    'Cream',
    'Gel'
  ];

  final List<String> _frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
  ];

  int get _timeFieldCount {
    switch (_selectedFrequency) {
      case 'Once daily':
        return 1;
      case 'Twice daily':
        return 2;
      case 'Three times daily':
        return 3;
      case 'Four times daily':
        return 4;
      default:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _medicationService = MedicationService.instance;
    
    if (widget.medication != null) {
      _medicationNameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _selectedMedicineType = widget.medication!.medicineType;
      _selectedFrequency = widget.medication!.frequency;
      _selectedTime1 = widget.medication!.times.isNotEmpty ? widget.medication!.times.first : TimeOfDay.now();
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate ?? DateTime.now().add(const Duration(days: 30));
      _notesController.text = widget.medication!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
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
        title: Text(
          widget.medication != null ? 'Edit Medication' : 'Add Medication',
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveMedication,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Name
                    const Text(
                      'Medication Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _medicationNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter medication name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dosage
                    const Text(
                      'Dosage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 500mg, 1 tablet',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Medicine Type
                    const Text(
                      'Medicine Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMedicineType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _medicineTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMedicineType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Frequency
                    const Text(
                      'Frequency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _frequencyOptions.map((String frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFrequency = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Time Selection
                    const Text(
                      'Time(s)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_timeFieldCount, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTimeField(index + 1),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Start Date
                    const Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDateField(
                      date: _startDate,
                      onTap: () => _selectDate(isStartDate: true),
                    ),
                    const SizedBox(height: 24),

                    // End Date
                    const Text(
                      'End Date (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDateField(
                      date: _endDate,
                      onTap: () => _selectDate(isStartDate: false),
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.medication != null ? 'Update Medication' : 'Save Medication',
                                style: const TextStyle(
                                  fontSize: 16,
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

  Widget _buildTimeField(int timeNumber) {
    TimeOfDay time;
    switch (timeNumber) {
      case 1:
        time = _selectedTime1;
        break;
      case 2:
        time = _selectedTime2;
        break;
      case 3:
        time = _selectedTime3;
        break;
      case 4:
        time = _selectedTime4;
        break;
      default:
        time = _selectedTime1;
    }

    return GestureDetector(
      onTap: () => _selectTime(timeNumber),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.access_time,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(int timeNumber) async {
    TimeOfDay initialTime;
    switch (timeNumber) {
      case 1:
        initialTime = _selectedTime1;
        break;
      case 2:
        initialTime = _selectedTime2;
        break;
      case 3:
        initialTime = _selectedTime3;
        break;
      case 4:
        initialTime = _selectedTime4;
        break;
      default:
        initialTime = _selectedTime1;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        switch (timeNumber) {
          case 1:
            _selectedTime1 = picked;
            break;
          case 2:
            _selectedTime2 = picked;
            break;
          case 3:
            _selectedTime3 = picked;
            break;
          case 4:
            _selectedTime4 = picked;
            break;
        }
      });
    }
  }

  Widget _buildDateField({
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime(2025),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, update it
          if (_endDate.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build times list based on frequency
      final List<TimeOfDay> times = [];
      if (_timeFieldCount >= 1) times.add(_selectedTime1);
      if (_timeFieldCount >= 2) times.add(_selectedTime2);
      if (_timeFieldCount >= 3) times.add(_selectedTime3);
      if (_timeFieldCount >= 4) times.add(_selectedTime4);

      final medication = Medication(
        id: widget.medication?.id,
        name: _medicationNameController.text,
        dosage: _dosageController.text,
        times: times,
        isTaken: false,
        takenAt: null,
        startDate: _startDate,
        endDate: _endDate,
        medicineType: _selectedMedicineType,
        frequency: _selectedFrequency,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isActive: true,
      );

      if (widget.medication != null) {
        // Update existing medication
        await _medicationService.updateMedication(medication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication updated successfully!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else {
        // Create new medication
        await _medicationService.createMedication(medication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication added successfully!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save medication: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 