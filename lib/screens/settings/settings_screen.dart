import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/health_data_provider.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('App Preferences'),
                const SizedBox(height: 16),
                
                // Language Setting
                _buildSettingTile(
                  title: 'Language',
                  subtitle: settingsProvider.settings.language.toUpperCase(),
                  icon: Icons.language,
                  onTap: () => _showLanguageDialog(context, settingsProvider),
                ),
                
                // Theme Setting
                _buildSettingTile(
                  title: 'Theme',
                  subtitle: settingsProvider.settings.theme == 'light' ? 'Light' : 'Dark',
                  icon: Icons.palette,
                  onTap: () => _showThemeDialog(context, settingsProvider),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Health Units'),
                const SizedBox(height: 16),
                
                // Glucose Unit
                _buildSettingTile(
                  title: 'Glucose Unit',
                  subtitle: settingsProvider.getGlucoseUnitDisplay(),
                  icon: Icons.monitor_heart,
                  onTap: () => _showGlucoseUnitDialog(context, settingsProvider),
                ),
                
                // Weight Unit
                _buildSettingTile(
                  title: 'Weight Unit',
                  subtitle: settingsProvider.getWeightUnitDisplay(),
                  icon: Icons.fitness_center,
                  onTap: () => _showWeightUnitDialog(context, settingsProvider),
                ),
                
                // Height Unit
                _buildSettingTile(
                  title: 'Height Unit',
                  subtitle: settingsProvider.getHeightUnitDisplay(),
                  icon: Icons.height,
                  onTap: () => _showHeightUnitDialog(context, settingsProvider),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Notifications'),
                const SizedBox(height: 16),
                
                // Notifications Toggle
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive app notifications',
                  icon: Icons.notifications,
                  value: settingsProvider.settings.notificationsEnabled,
                  onChanged: (value) => settingsProvider.setNotificationsEnabled(value),
                ),
                
                // Glucose Reminders
                _buildSwitchTile(
                  title: 'Glucose Reminders',
                  subtitle: 'Remind me to check glucose',
                  icon: Icons.monitor_heart_outlined,
                  value: settingsProvider.settings.glucoseRemindersEnabled,
                  onChanged: (value) => settingsProvider.setGlucoseRemindersEnabled(value),
                ),
                
                // Medication Reminders
                _buildSwitchTile(
                  title: 'Medication Reminders',
                  subtitle: 'Remind me to take medications',
                  icon: Icons.medication,
                  value: settingsProvider.settings.medicationRemindersEnabled,
                  onChanged: (value) => settingsProvider.setMedicationRemindersEnabled(value),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Features'),
                const SizedBox(height: 16),
                
                // Diet Tracking
                _buildSwitchTile(
                  title: 'Diet Tracking',
                  subtitle: 'Track food and nutrition',
                  icon: Icons.restaurant,
                  value: settingsProvider.settings.dietTrackingEnabled,
                  onChanged: (value) => settingsProvider.setDietTrackingEnabled(value),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Data Management'),
                const SizedBox(height: 16),
                
                // Export Data
                _buildSettingTile(
                  title: 'Export Data',
                  subtitle: 'Backup your health data',
                  icon: Icons.upload,
                  onTap: () => _exportData(context),
                ),
                
                // Clear Data
                _buildSettingTile(
                  title: 'Clear All Data',
                  subtitle: 'Delete all stored data',
                  icon: Icons.delete_forever,
                  onTap: () => _showClearDataDialog(context),
                ),
                
                // Reset Settings
                _buildSettingTile(
                  title: 'Reset Settings',
                  subtitle: 'Restore default settings',
                  icon: Icons.restore,
                  onTap: () => _showResetSettingsDialog(context, settingsProvider),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: settingsProvider.settings.language,
                onChanged: (value) {
                  settingsProvider.setLanguage(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Hindi'),
              leading: Radio<String>(
                value: 'hi',
                groupValue: settingsProvider.settings.language,
                onChanged: (value) {
                  settingsProvider.setLanguage(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio<String>(
                value: 'light',
                groupValue: settingsProvider.settings.theme,
                onChanged: (value) {
                  settingsProvider.setTheme(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: settingsProvider.settings.theme,
                onChanged: (value) {
                  settingsProvider.setTheme(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlucoseUnitDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Glucose Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('mg/dL'),
              leading: Radio<String>(
                value: 'mg/dL',
                groupValue: settingsProvider.settings.glucoseUnit,
                onChanged: (value) {
                  settingsProvider.setGlucoseUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('mmol/L'),
              leading: Radio<String>(
                value: 'mmol/L',
                groupValue: settingsProvider.settings.glucoseUnit,
                onChanged: (value) {
                  settingsProvider.setGlucoseUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightUnitDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Weight Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('kg'),
              leading: Radio<String>(
                value: 'kg',
                groupValue: settingsProvider.settings.weightUnit,
                onChanged: (value) {
                  settingsProvider.setWeightUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('lbs'),
              leading: Radio<String>(
                value: 'lbs',
                groupValue: settingsProvider.settings.weightUnit,
                onChanged: (value) {
                  settingsProvider.setWeightUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightUnitDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Height Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('cm'),
              leading: Radio<String>(
                value: 'cm',
                groupValue: settingsProvider.settings.heightUnit,
                onChanged: (value) {
                  settingsProvider.setHeightUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('ft'),
              leading: Radio<String>(
                value: 'ft',
                groupValue: settingsProvider.settings.heightUnit,
                onChanged: (value) {
                  settingsProvider.setHeightUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
    // This would implement actual data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon!'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your health data, user information, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData(context);
            },
            child: const Text(
              'Clear Data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final healthDataProvider = Provider.of<HealthDataProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    await Future.wait([
      appStateProvider.clearAllUserData(),
      healthDataProvider.clearAllData(),
      settingsProvider.resetToDefaults(),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been cleared'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  void _showResetSettingsDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all app settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings have been reset'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 