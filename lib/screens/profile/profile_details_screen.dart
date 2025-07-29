import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../providers/app_state_provider.dart';
import '../../services/supabase_auth_service.dart';
import '../../core/constants/app_colors.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _uniqueIdController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedDiabetesType = 'Type 2';
  String _selectedUnits = 'mg/dL';
  DateTime? _diagnosisDate;
  DateTime? _selectedDate;
  String _selectedDiabetesStatus = 'None';
  String? _age; // Calculated age from date of birth
  String? _profileImageUrl; // Profile image URL from storage
  File? _selectedImageFile; // Selected image file for upload
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🔄 ProfileDetailsScreen initialized');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading user data for profile details screen');
      
      // Get user profile from the simplified schema
      final userProfile = SupabaseAuthService.instance.getUserProfile();
      
      if (userProfile != null) {
        print('📊 Loaded user profile: $userProfile');
        
        // Populate form fields with user data
        _nameController.text = userProfile['name'] ?? '';
        _emailController.text = userProfile['email'] ?? '';
        _phoneController.text = userProfile['phone'] ?? '';
        _heightController.text = userProfile['height_cm']?.toString() ?? '';
        _weightController.text = userProfile['weight_kg']?.toString() ?? '';
        _uniqueIdController.text = userProfile['unique_id'] ?? '';
        
        // Set diabetes status with proper mapping
        if (userProfile['diabetes_status'] != null) {
          final status = userProfile['diabetes_status'];
          switch (status) {
            case 'diabetic':
              _selectedDiabetesStatus = 'Diabetic';
              break;
            case 'pre_diabetic':
              _selectedDiabetesStatus = 'Pre-diabetic';
              break;
            case 'non_diabetic':
              _selectedDiabetesStatus = 'Non-diabetic';
              break;
            default:
              _selectedDiabetesStatus = 'None';
          }
        }
        
        // Set diabetes type with proper mapping
        if (userProfile['diabetes_type'] != null) {
          final type = userProfile['diabetes_type'];
          switch (type) {
            case 'type_1':
              _selectedDiabetesType = 'Type 1';
              break;
            case 'type_2':
              _selectedDiabetesType = 'Type 2';
              break;
            case 'gestational':
              _selectedDiabetesType = 'Gestational';
              break;
            case 'pre_diabetic':
              _selectedDiabetesType = 'Pre-diabetes';
              break;
            case 'other':
              _selectedDiabetesType = 'Other';
              break;
            default:
              _selectedDiabetesType = 'Type 2';
          }
        } else {
          // For non-diabetic users, set to "Not Applicable"
          _selectedDiabetesType = 'Not Applicable';
        }
        
        // Set gender with proper mapping
        if (userProfile['gender'] != null) {
          final gender = userProfile['gender'];
          switch (gender.toLowerCase()) {
            case 'male':
              _selectedGender = 'Male';
              break;
            case 'female':
              _selectedGender = 'Female';
              break;
            case 'other':
              _selectedGender = 'Other';
              break;
            case 'prefer_not_to_say':
              _selectedGender = 'Prefer not to say';
              break;
            default:
              _selectedGender = 'Male';
          }
        }
        
        // Set date of birth
        if (userProfile['date_of_birth'] != null) {
          try {
            _selectedDate = DateTime.parse(userProfile['date_of_birth']);
            // Calculate age from date of birth
            if (_selectedDate != null) {
              final now = DateTime.now();
              final age = now.year - _selectedDate!.year;
              if (now.month < _selectedDate!.month || 
                  (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
                _age = (age - 1).toString();
              } else {
                _age = age.toString();
              }
            }
          } catch (e) {
            print('❌ Error parsing date of birth: $e');
          }
        }
        
        // Set diagnosis date
        if (userProfile['diagnosis_date'] != null) {
          try {
            _diagnosisDate = DateTime.parse(userProfile['diagnosis_date']);
          } catch (e) {
            print('❌ Error parsing diagnosis date: $e');
          }
        }
        
        // Load profile image URL
        _profileImageUrl = userProfile['profile_image_url'];
        
        print('✅ Form fields populated with user data');
        print('📊 Diabetes Status: $_selectedDiabetesStatus');
        print('📊 Diabetes Type: $_selectedDiabetesType');
        print('📊 Gender: $_selectedGender');
        print('📊 Date of Birth: $_selectedDate');
        print('📊 Diagnosis Date: $_diagnosisDate');
        print('📊 Profile Image URL: $_profileImageUrl');
      } else {
        print('⚠️ No user profile data found');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Map diabetes status back to database format
      String diabetesStatus;
      switch (_selectedDiabetesStatus) {
        case 'Diabetic':
          diabetesStatus = 'diabetic';
          break;
        case 'Pre-diabetic':
          diabetesStatus = 'pre_diabetic';
          break;
        case 'Non-diabetic':
          diabetesStatus = 'non_diabetic';
          break;
        default:
          diabetesStatus = 'non_diabetic';
      }

      // Map diabetes type back to database format
      String? diabetesType;
      switch (_selectedDiabetesType) {
        case 'Type 1':
          diabetesType = 'type_1';
          break;
        case 'Type 2':
          diabetesType = 'type_2';
          break;
        case 'Gestational':
          diabetesType = 'gestational';
          break;
        case 'Pre-diabetes':
          diabetesType = 'pre_diabetic';
          break;
        case 'Other':
          diabetesType = 'other';
          break;
        case 'Not Applicable':
          diabetesType = null; // null for non-diabetic users
          break;
        default:
          diabetesType = 'type_2';
      }

      // Map gender back to database format
      String gender;
      switch (_selectedGender.toLowerCase()) {
        case 'male':
          gender = 'male';
          break;
        case 'female':
          gender = 'female';
          break;
        case 'other':
          gender = 'other';
          break;
        case 'prefer not to say':
          gender = 'prefer_not_to_say';
          break;
        default:
          gender = 'male';
      }

      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'height_cm': int.tryParse(_heightController.text) ?? 0,
        'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
        'unique_id': _uniqueIdController.text.trim(),
        'diabetes_status': diabetesStatus,
        'diabetes_type': diabetesType, // Can be null for non-diabetic users
        'gender': gender,
        'date_of_birth': _selectedDate?.toIso8601String(),
        'diagnosis_date': _diagnosisDate?.toIso8601String(), // Can be null for non-diabetic users
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('💾 Saving profile data: $data');
      await SupabaseAuthService.instance.updateProfile(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _diagnosisDate) {
      setState(() {
        _diagnosisDate = picked;
      });
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Recalculate age
        final now = DateTime.now();
        final age = now.year - picked.year;
        if (now.month < picked.month || 
            (now.month == picked.month && now.day < picked.day)) {
          _age = (age - 1).toString();
        } else {
          _age = age.toString();
        }
      });
    }
  }

  // Photo upload methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85, // Compress to reduce file size
      );
      
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        // Check file size (1MB = 1024 * 1024 bytes)
        if (fileSize > 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size must be less than 1MB')),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImageFile = file;
        });
        
        await _uploadProfileImage();
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final currentUser = SupabaseAuthService.instance.currentUser;
    if (_selectedImageFile == null || currentUser == null) return;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      print('🔄 Uploading profile image...');
      
      // Generate unique filename
      final extension = path.extension(_selectedImageFile!.path);
      final fileName = 'profile_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Upload to Supabase storage
      final response = await SupabaseAuthService.instance.client.storage
          .from('profile-images')
          .upload(fileName, _selectedImageFile!);
      
      // Get public URL
      final imageUrl = SupabaseAuthService.instance.client.storage
          .from('profile-images')
          .getPublicUrl(fileName);
      
      print('✅ Image uploaded successfully: $imageUrl');
      
      // Update profile with new image URL
      await SupabaseAuthService.instance.updateProfile({
        'profile_image_url': imageUrl,
      });
      
      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              
              const SizedBox(height: 30),
              
              // Basic Information Section
              _buildSection(
                title: 'Basic Information',
                children: [
                  _buildTextField(
                    label: 'Name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    label: 'Date of Birth',
                    value: _selectedDate,
                    onTap: () => _selectDateOfBirth(context),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Age',
                    controller: TextEditingController(text: _age ?? ''),
                    keyboardType: TextInputType.number,
                    enabled: false, // Make it read-only
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Age will be calculated from date of birth';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Gender',
                    value: _selectedGender,
                    items: ['Male', 'Female', 'Other', 'Prefer not to say'],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Height',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    suffixText: 'cm',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Weight',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    suffixText: 'kg',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Contact Details Section
              _buildSection(
                title: 'Contact Details',
                children: [
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Phone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Diabetes Information Section
              _buildSection(
                title: 'Diabetes Information',
                children: [
                  _buildDropdownField(
                    label: 'Diabetes Status',
                    value: _selectedDiabetesStatus,
                    items: ['None', 'Diabetic', 'Pre-diabetic', 'Non-diabetic'],
                    onChanged: (value) {
                      setState(() {
                        _selectedDiabetesStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Type of Diabetes',
                    value: _selectedDiabetesType,
                    items: ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetes', 'Other', 'Not Applicable'],
                    onChanged: (value) {
                      setState(() {
                        _selectedDiabetesType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    label: 'Diagnosis Date',
                    value: _diagnosisDate,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Preferred Units',
                    value: _selectedUnits,
                    items: ['mg/dL', 'mmol/L'],
                    onChanged: (value) {
                      setState(() {
                        _selectedUnits = value!;
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18,
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

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image with Upload Functionality
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE5E5),
                ),
                child: _isUploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                      )
                    : _profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profileImageUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage('assets/images/profile.avif'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/images/profile.avif'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
              ),
            ),
            // Upload Icon
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // User Name
        Consumer<AppStateProvider>(
          builder: (context, appStateProvider, child) {
            final user = appStateProvider.currentUser;
            return Text(
              user?.name ?? 'Sophia Carter',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Edit Profile Link
        GestureDetector(
          onTap: () {
            // TODO: Implement edit profile functionality
          },
          child: const Text(
            'Edit profile',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Section Content
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
    bool enabled = true, // Add enabled parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled, // Apply enabled
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: value != null ? Colors.black : Colors.grey[600],
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 