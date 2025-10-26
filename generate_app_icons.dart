import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  print('Generating PhishTi Detector app icons...');
  
  // Create Android icons
  await generateAndroidIcons();
  
  print('✅ App icons generated successfully!');
  print('\nNext steps:');
  print('1. Update AndroidManifest.xml to use launcher_icon');
  print('2. Run flutter clean and flutter pub get');
  print('3. Build and test the app');
}

Future<void> generateAndroidIcons() async {
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  final basePath = 'android/app/src/main/res';
  
  for (final entry in androidSizes.entries) {
    final folder = entry.key;
    final size = entry.value;
    
    final folderPath = Directory('$basePath/$folder');
    await folderPath.create(recursive: true);
    
    // Create the icon
    final icon = await createPhishtiLogo(size);
    
    // Save as ic_launcher.png
    final iconFile = File('${folderPath.path}/ic_launcher.png');
    await iconFile.writeAsBytes(icon);
    print('Generated ${iconFile.path} (${size}x$size)');
    
    // Also save as launcher_icon.png
    final launcherIconFile = File('${folderPath.path}/launcher_icon.png');
    await launcherIconFile.writeAsBytes(icon);
    print('Generated ${launcherIconFile.path} (${size}x$size)');
  }
}

Future<Uint8List> createPhishtiLogo(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Calculate dimensions
  final margin = size ~/ 8;
  final shieldWidth = size - 2 * margin;
  final shieldHeight = (shieldWidth * 1.2).round();
  final shieldX = margin.toDouble();
  final shieldY = margin.toDouble();
  
  // Draw outer circle (border)
  final borderWidth = size ~/ 20;
  final outerPaint = Paint()
    ..color = const Color(0xFF006496) // Dark teal
    ..style = PaintingStyle.fill;
  final borderPaint = Paint()
    ..color = const Color(0xFF00C864) // Bright green
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth.toDouble();
  
  canvas.drawCircle(Offset(size/2, size/2), size/2 - borderWidth/2, outerPaint);
  canvas.drawCircle(Offset(size/2, size/2), size/2 - borderWidth/2, borderPaint);
  
  // Draw shield (green)
  final shieldPaint = Paint()
    ..color = const Color(0xFF00C864) // Bright green
    ..style = PaintingStyle.fill;
  
  final shieldPath = Path();
  shieldPath.moveTo(shieldX + shieldWidth/2, shieldY); // Top center
  shieldPath.lineTo(shieldX, shieldY + shieldHeight/3); // Left middle
  shieldPath.lineTo(shieldX, shieldY + shieldHeight); // Left bottom
  shieldPath.lineTo(shieldX + shieldWidth, shieldY + shieldHeight); // Right bottom
  shieldPath.lineTo(shieldX + shieldWidth, shieldY + shieldHeight/3); // Right middle
  shieldPath.close();
  
  canvas.drawPath(shieldPath, shieldPaint);
  
  // Draw red detection element
  final detectionSize = shieldWidth ~/ 6;
  final detectionX = shieldX + shieldWidth/2 - detectionSize/2;
  final detectionY = shieldY + shieldHeight/2 - detectionSize/2;
  
  final redPaint = Paint()
    ..color = const Color(0xFFC80000) // Red
    ..style = PaintingStyle.fill;
  
  // Red circle
  canvas.drawCircle(
    Offset(detectionX + detectionSize/2, detectionY + detectionSize/2),
    detectionSize/2,
    redPaint,
  );
  
  // Red line extending upward
  final lineWidth = detectionSize ~/ 4;
  final linePaint = Paint()
    ..color = const Color(0xFFC80000) // Red
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineWidth.toDouble();
  
  final lineStartX = shieldX + shieldWidth/2;
  final lineStartY = detectionY;
  final lineEndX = shieldX + shieldWidth/2;
  final lineEndY = shieldY + shieldHeight/4;
  
  canvas.drawLine(
    Offset(lineStartX, lineStartY),
    Offset(lineEndX, lineEndY),
    linePaint,
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}
