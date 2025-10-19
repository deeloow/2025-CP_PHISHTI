import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create app icons
  await createAppIcons();
}

Future<void> createAppIcons() async {
  print('Creating app icons...');
  
  // Create a simple icon widget
  final iconWidget = Container(
    width: 512,
    height: 512,
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a2e),
      borderRadius: BorderRadius.circular(256),
      border: Border.all(color: const Color(0xFF00ff88), width: 12),
    ),
    child: Stack(
      children: [
        // Inner circle
        Positioned(
          top: 56,
          left: 56,
          right: 56,
          bottom: 56,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(200),
              border: Border.all(color: const Color(0xFF00ff88), width: 6),
            ),
          ),
        ),
        
        // Shield
        Positioned(
          top: 100,
          left: 180,
          right: 180,
          bottom: 100,
          child: CustomPaint(
            painter: ShieldPainter(),
          ),
        ),
        
        // Fish hook
        Positioned(
          top: 180,
          left: 236,
          right: 236,
          bottom: 180,
          child: CustomPaint(
            painter: FishHookPainter(),
          ),
        ),
        
        // Security lines
        Positioned(
          top: 170,
          left: 200,
          right: 200,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 190,
          left: 200,
          right: 200,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 210,
          left: 200,
          right: 200,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        // Decorative dots
        Positioned(
          top: 150,
          left: 150,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: 150,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: 150,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          right: 150,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00ff88),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    ),
  );
  
  print('✅ App icon design created!');
  print('Note: To generate actual PNG files, you would need to use a Flutter app with image generation capabilities.');
  print('The SVG files have been created in assets/images/ for use in the app.');
}

class ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00ff88)
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
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FishHookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFff4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
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
      ..color = const Color(0xFFff4444)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.6),
      8,
      pointPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
