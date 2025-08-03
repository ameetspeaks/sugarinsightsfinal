import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/constants/app_colors.dart';
import '../../models/education_category.dart';
import '../../services/education_service.dart';
import '../../providers/education_provider.dart';
import 'package:provider/provider.dart';

class EducationCategoryCard extends StatelessWidget {
  final EducationCategory category;
  final Color backgroundColor;
  final VoidCallback onTap;

  const EducationCategoryCard({
    super.key,
    required this.category,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon (Circular, teal background)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildCategoryIcon(context),
                ),
                const SizedBox(width: 16),
                // Category Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name (teal, bold)
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Description (gray subtitle)
                      if (category.description != null && category.description!.isNotEmpty)
                        Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          category.contentSummary,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _getCategoryIcon(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          );
        }

        // Fallback to asset icon
        if (category.iconName != null && category.iconName!.isNotEmpty) {
          return ClipOval(
            child: Image.asset(
              category.iconName!,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon();
              },
            ),
          );
        }

        // Use fallback icon
        return _buildFallbackIcon();
      },
    );
  }

  Future<Uint8List?> _getCategoryIcon(BuildContext context) async {
    try {
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      final educationService = educationProvider.educationService;
      
      return await educationService.getCategoryIcon(category.id, category.imagePath);
    } catch (e) {
      print('❌ Error getting category icon: $e');
      return null;
    }
  }

  Widget _buildFallbackIcon() {
    // Use category icon if available, otherwise use default
    final iconData = category.icon ?? Icons.category;
    return Icon(
      iconData,
      color: Colors.white,
      size: 28,
    );
  }
} 