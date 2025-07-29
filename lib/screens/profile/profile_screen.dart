import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/supabase_auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../settings/settings_screen.dart';
import '../reports/reports_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _onMyProfileTap() {
    print('🔄 My Profile button tapped');
    print('🔄 Navigating to /profile-details');
    Navigator.pushNamed(context, '/profile-details');
  }

  void _onReportsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsScreen(),
      ),
    );
  }

  void _onSettingsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _onLogoutTap(BuildContext context) {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    appStateProvider.signOut();
    Navigator.pushReplacementNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Header Section
              _buildProfileHeader(),
              
              const SizedBox(height: 40),
              
              // Menu Options Section
              _buildMenuOptions(),
              
              const Spacer(),
              
              // Logout Button
              _buildLogoutButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image with Edit Icon
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _onMyProfileTap, // Navigate to profile details when tapped
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE5E5), // Light peach background
                ),
                child: Consumer<SupabaseAuthService>(
                  builder: (context, authService, child) {
                    final userProfile = authService.getUserProfile();
                    final profileImageUrl = userProfile?['profile_image_url'];
                    
                    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                      return ClipOval(
                        child: Image.network(
                          profileImageUrl,
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
                      );
                    } else {
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
                    }
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _onMyProfileTap, // Navigate to profile details for image update
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
        
        const SizedBox(height: 24),
        
        // User Name
        Consumer<SupabaseAuthService>(
          builder: (context, authService, child) {
            final userProfile = authService.getUserProfile();
            final userName = userProfile?['name'] ?? 'User';
            return Text(
              userName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49454F),
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Unique ID
        Consumer<SupabaseAuthService>(
          builder: (context, authService, child) {
            final userProfile = authService.getUserProfile();
            final uniqueId = userProfile?['unique_id'] ?? 'N/A';
            return Text(
              'Unique Id- $uniqueId',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    return Column(
      children: [
        // My Profile Option
        _buildMenuCard(
          icon: Icons.person,
          title: 'My Profile',
          subtitle: 'View And Update Your Profile',
          onTap: _onMyProfileTap,
        ),
        
        const SizedBox(height: 16),
        
        // Reports Option
        _buildMenuCard(
          icon: Icons.bar_chart,
          title: 'Reports',
          subtitle: 'View Your Health Reports',
          onTap: _onReportsTap,
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onLogoutTap(context),
          borderRadius: BorderRadius.circular(14),
          child: const Center(
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 