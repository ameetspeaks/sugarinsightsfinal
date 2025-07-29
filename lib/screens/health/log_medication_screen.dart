import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';
import '../../providers/health_data_provider.dart';
import 'package:provider/provider.dart';

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
  
  // Controllers for all input fields
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  
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
    if (widget.medication != null) {
      _medicationNameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _selectedMedicineType = widget.medication!.medicineType;
      _selectedFrequency = widget.medication!.frequency;
      _selectedTime1 = widget.medication!.time;
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
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
          'Log Medication Reminders Details',
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
              // Medicine Name
              _buildInputField(
                label: 'Medicine Name',
                controller: _medicationNameController,
                placeholder: 'Generic and brand name if applicable',
                icon: Icons.search,
                suffixIcon: Icons.medication,
              ),
              
              const SizedBox(height: 24),
              
              // Medicine Type
              _buildDropdownField(
                label: 'Medicine Type',
                value: _selectedMedicineType,
                items: _medicineTypes,
                placeholder: 'Select Medicine type e.g. tablet, syrup',
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMedicineType = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Medicine Dosage
              _buildInputField(
                label: 'Medicine Dosage',
                controller: _dosageController,
                placeholder: '(e.g., 500 mg, 1 tablet)',
                icon: Icons.medication,
              ),
              
              const SizedBox(height: 24),
              
              // Frequency
              _buildDropdownField(
                label: 'Frequency',
                value: _selectedFrequency,
                items: _frequencyOptions,
                placeholder: 'How many times a day (e.g. twice daily)',
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFrequency = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Start Date
              Text(
                'Start Date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(isStartDate: true),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_startDate.day}-${_startDate.month}-${_startDate.year}',
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
              ),

              const SizedBox(height: 24),
              
              // End Date
              Text(
                'End Date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(isStartDate: false),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_endDate.day}-${_endDate.month}-${_endDate.year}',
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
              ),
              
              const SizedBox(height: 24),
              
              // Specific Times
              Text(
                'Specific Times',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              
              // Dynamic Time Fields
              _buildDynamicTimeFields(),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
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

  Widget _buildDynamicTimeFields() {
    if (_timeFieldCount == 1) {
      return _buildTimeField(
        label: 'Time',
        time: _selectedTime1,
        placeholder: 'Exact time',
        onTap: () => _selectTime(1),
      );
    } else if (_timeFieldCount == 2) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Time 1',
                  time: _selectedTime1,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  label: 'Time 2',
                  time: _selectedTime2,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(2),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_timeFieldCount == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Time 1',
                  time: _selectedTime1,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  label: 'Time 2',
                  time: _selectedTime2,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeField(
            label: 'Time 3',
            time: _selectedTime3,
            placeholder: 'Exact time',
            onTap: () => _selectTime(3),
          ),
        ],
      );
    } else if (_timeFieldCount == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Time 1',
                  time: _selectedTime1,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  label: 'Time 2',
                  time: _selectedTime2,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Time 3',
                  time: _selectedTime3,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  label: 'Time 4',
                  time: _selectedTime4,
                  placeholder: 'Exact time',
                  onTap: () => _selectTime(4),
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    IconData? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
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
            height: 56,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      if (suffixIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          suffixIcon,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ],
                    ],
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildTimeField({
    required String label,
    required TimeOfDay time,
    required String placeholder,
    required VoidCallback onTap,
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
            height: 56,
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
        ),
      ],
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

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final medication = Medication(
        name: _medicationNameController.text,
        dosage: _dosageController.text,
        time: _selectedTime1,
        isTaken: false,
        takenAt: null,
        startDate: _startDate,
        endDate: _endDate,
        medicineType: _selectedMedicineType,
        frequency: _selectedFrequency,
      );

      context.read<HealthDataProvider>().addMedication(medication);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication logged successfully!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

      Navigator.pop(context);
    }
  }
} 