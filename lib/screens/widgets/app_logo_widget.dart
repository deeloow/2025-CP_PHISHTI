import 'package:flutter/material.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? backgroundColor;
  
  const AppLogoWidget({
    super.key,
    this.size = 100,
    this.showText = true,
    this.primaryColor,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF00ff88);
    final background = backgroundColor ?? const Color(0xFF1a1a2e);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: primary, width: size * 0.02),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner circle
              Positioned(
                top: size * 0.11,
                left: size * 0.11,
                right: size * 0.11,
                bottom: size * 0.11,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213e),
                    borderRadius: BorderRadius.circular(size * 0.39),
                    border: Border.all(color: primary, width: size * 0.012),
                  ),
                ),
              ),
              
              // Shield
              Positioned(
                top: size * 0.2,
                left: size * 0.35,
                right: size * 0.35,
                bottom: size * 0.2,
                child: CustomPaint(
                  painter: ShieldPainter(
                    color: primary,
                    strokeWidth: size * 0.008,
                  ),
                ),
              ),
              
              // Fish hook
              Positioned(
                top: size * 0.35,
                left: size * 0.46,
                right: size * 0.46,
                bottom: size * 0.35,
                child: CustomPaint(
                  painter: FishHookPainter(
                    color: const Color(0xFFff4444),
                    strokeWidth: size * 0.012,
                  ),
                ),
              ),
              
              // Security lines
              ...List.generate(3, (index) {
                final lineY = size * (0.33 + index * 0.08);
                return Positioned(
                  top: lineY,
                  left: size * 0.39,
                  right: size * 0.39,
                  child: Container(
                    height: size * 0.006,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(size * 0.003),
                    ),
                  ),
                );
              }),
              
              // Decorative dots
              ...List.generate(4, (index) {
                final positions = [
                  Offset(size * 0.29, size * 0.29), // Top left
                  Offset(size * 0.71, size * 0.29), // Top right
                  Offset(size * 0.29, size * 0.71), // Bottom left
                  Offset(size * 0.71, size * 0.71), // Bottom right
                ];
                
                return Positioned(
                  left: positions[index].dx - size * 0.016,
                  top: positions[index].dy - size * 0.016,
                  child: Container(
                    width: size * 0.032,
                    height: size * 0.032,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(size * 0.016),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        
        // App Name
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'PhishTi Detector',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI-Powered Protection',
            style: TextStyle(
              fontSize: size * 0.12,
              color: primary.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class ShieldPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  
  ShieldPainter({
    required this.color,
    this.strokeWidth = 2.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height * 0.2);
    path.lineTo(0, size.height * 0.8);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.2);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Inner shield
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final innerPath = Path();
    innerPath.moveTo(size.width / 2, size.height * 0.1);
    innerPath.lineTo(size.width * 0.15, size.height * 0.25);
    innerPath.lineTo(size.width * 0.15, size.height * 0.75);
    innerPath.lineTo(size.width / 2, size.height * 0.9);
    innerPath.lineTo(size.width * 0.85, size.height * 0.75);
    innerPath.lineTo(size.width * 0.85, size.height * 0.25);
    innerPath.close();
    
    canvas.drawPath(innerPath, innerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FishHookPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  
  FishHookPainter({
    required this.color,
    this.strokeWidth = 3.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Hook line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * 0.4),
      paint,
    );
    
    // Hook arc
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.6),
      width: size.width * 0.6,
      height: size.height * 0.6,
    );
    canvas.drawArc(rect, 0, 3.14159, false, paint);
    
    // Hook point
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.6),
      strokeWidth * 1.5,
      pointPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
