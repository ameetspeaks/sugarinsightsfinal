import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum MedicalButtonType {
  primary,
  secondary,
  danger,
  success,
}

class MedicalButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final MedicalButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;

  const MedicalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = MedicalButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 48,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case MedicalButtonType.primary:
        return AppColors.primaryColor;
      case MedicalButtonType.secondary:
        return AppColors.white;
      case MedicalButtonType.danger:
        return AppColors.highRange;
      case MedicalButtonType.success:
        return AppColors.successColor;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case MedicalButtonType.primary:
      case MedicalButtonType.danger:
      case MedicalButtonType.success:
        return AppColors.white;
      case MedicalButtonType.secondary:
        return AppColors.primaryColor;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case MedicalButtonType.primary:
      case MedicalButtonType.danger:
      case MedicalButtonType.success:
        return Colors.transparent;
      case MedicalButtonType.secondary:
        return AppColors.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          side: BorderSide(
            color: _getBorderColor(),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: type == MedicalButtonType.secondary ? 0 : 2,
          shadowColor: AppColors.black.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Lufga',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: _getTextColor(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Lufga',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 