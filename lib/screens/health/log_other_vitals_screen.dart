import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../services/other_vitals_service.dart';

class LogOtherVitalsScreen extends StatefulWidget {
  const LogOtherVitalsScreen({super.key});

  @override
  State<LogOtherVitalsScreen> createState() => _LogOtherVitalsScreenState();
}

class _LogOtherVitalsScreenState extends State<LogOtherVitalsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all input fields
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _hba1cController = TextEditingController();
  final _uacrController = TextEditingController();
  final _hbController = TextEditingController();
  final _creatinineController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

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
    _hba1cController.dispose();
    _uacrController.dispose();
    _hbController.dispose();
    _creatinineController.dispose();
    _cholesterolController.dispose();
    _triglyceridesController.dispose();
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
      lastDate: DateTime.now(), // Prevent future dates
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
        _timeController.text = _selectedTime.format(context);
      });
    }
  }

  Future<void> _saveVitals() async {
    if (_formKey.currentState!.validate()) {
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
        final vitalsService = OtherVitalsService();

        // Save each vital that has a value
        final vitalsToSave = <Map<String, dynamic>>[];

        // HBA1C
        if (_hba1cController.text.isNotEmpty) {
          final value = double.tryParse(_hba1cController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'hba1c',
              'value': value,
              'unit': '%',
              'notes': 'HBA1C reading',
              'reading_date': readingDate,
            });
          }
        }

        // UACR
        if (_uacrController.text.isNotEmpty) {
          final value = double.tryParse(_uacrController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'uacr',
              'value': value,
              'unit': 'mg/g',
              'notes': 'UACR reading',
              'reading_date': readingDate,
            });
          }
        }

        // Hemoglobin
        if (_hbController.text.isNotEmpty) {
          final value = double.tryParse(_hbController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'hb',
              'value': value,
              'unit': 'g/dL',
              'notes': 'Hemoglobin reading',
              'reading_date': readingDate,
            });
          }
        }

        // Creatinine
        if (_creatinineController.text.isNotEmpty) {
          final value = double.tryParse(_creatinineController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'creatinine',
              'value': value,
              'unit': 'mg/dL',
              'notes': 'Creatinine reading',
              'reading_date': readingDate,
            });
          }
        }

        // Cholesterol
        if (_cholesterolController.text.isNotEmpty) {
          final value = double.tryParse(_cholesterolController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'cholesterol',
              'value': value,
              'unit': 'mg/dL',
              'notes': 'Total cholesterol reading',
              'reading_date': readingDate,
            });
          }
        }

        // Triglycerides
        if (_triglyceridesController.text.isNotEmpty) {
          final value = double.tryParse(_triglyceridesController.text);
          if (value != null && value > 0) {
            vitalsToSave.add({
              'vital_type': 'triglycerides',
              'value': value,
              'unit': 'mg/dL',
              'notes': 'Triglycerides reading',
              'reading_date': readingDate,
            });
          }
        }

        // Save all vitals
        for (final vital in vitalsToSave) {
          await vitalsService.addVitalReading(
            vitalType: vital['vital_type'],
            value: vital['value'],
            unit: vital['unit'],
            notes: vital['notes'],
            readingDate: vital['reading_date'],
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vitalsToSave.length} vitals saved successfully!'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving vitals: $e'),
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
          'Log Other Vitals',
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
              _buildInputField(
                label: 'Measurement Date',
                controller: _dateController,
                placeholder: 'DD-MM-YYYY',
                icon: Icons.calendar_today,
                onTap: _selectDate,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Measurement Time',
                controller: _timeController,
                placeholder: '00:00 AM',
                icon: Icons.access_time,
                onTap: _selectTime,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'HBA1C (%)',
                controller: _hba1cController,
                placeholder: 'Enter HBA1C value',
                icon: Icons.science,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'UACR (mg/g)',
                controller: _uacrController,
                placeholder: 'Enter UACR value',
                icon: Icons.grid_on,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Hemoglobin (g/dL)',
                controller: _hbController,
                placeholder: 'Enter HB value',
                icon: Icons.bloodtype,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Creatinine (mg/dL)',
                controller: _creatinineController,
                placeholder: 'Enter creatinine value',
                icon: Icons.thermostat,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Total Cholesterol (mg/dL)',
                controller: _cholesterolController,
                placeholder: 'Enter cholesterol value',
                icon: Icons.settings,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Triglycerides (mg/dL)',
                controller: _triglyceridesController,
                placeholder: 'Enter triglycerides value',
                icon: Icons.radio_button_checked,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Notes (Optional)',
                controller: _notesController,
                placeholder: 'Add any notes about these readings...',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
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
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    keyboardType: keyboardType,
                    inputFormatters: keyboardType == TextInputType.numberWithOptions(decimal: true)
                        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                        : null,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
} 