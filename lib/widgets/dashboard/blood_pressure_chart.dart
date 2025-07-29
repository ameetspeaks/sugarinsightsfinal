import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BloodPressureChart extends StatelessWidget {
  final Map<String, dynamic>? latestReading;

  const BloodPressureChart({
    super.key,
    this.latestReading,
  });

  @override
  Widget build(BuildContext context) {
    final systolic = latestReading?['systolic'] as int? ?? 0;
    final diastolic = latestReading?['diastolic'] as int? ?? 0;
    final pulseRate = latestReading?['pulse_rate'] as int?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$systolic/$diastolic',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Text(
                ' mmHg',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (pulseRate != null) ...[
                const SizedBox(width: 16),
                Text(
                  'Pulse: $pulseRate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Latest Reading',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _BPChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mon', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Tue', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Wed', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Thu', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Fri', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Sat', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Sun', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _BPChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Sample data points (normalized to fit the chart height)
    final points = [
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.17, size.height * 0.3),
      Offset(size.width * 0.33, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.67, size.height * 0.6),
      Offset(size.width * 0.83, size.height * 0.3),
      Offset(size.width, size.height * 0.5),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      
      // Create a smooth curve
      path.cubicTo(
        p0.dx + (p1.dx - p0.dx) / 3,
        p0.dy,
        p1.dx - (p1.dx - p0.dx) / 3,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 