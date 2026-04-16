import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<gmap.BitmapDescriptor> createColoredMarker(Color color, {double size = 24.0}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Size markerSize = Size(size, size);
  
  // Draw pin shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.2)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);
  canvas.drawPath(
    _getPinPath(size),
    shadowPaint,
  );
  
  // Draw pin body
  final pinPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawPath(
    _getPinPath(size),
    pinPaint,
  );
  
  // Draw inner circle
  final circlePaint = Paint()
    ..color = Colors.white.withOpacity(0.8)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(size / 2, size * 0.35),
    size * 0.08,
    circlePaint,
  );
  
  final ui.Picture picture = pictureRecorder.endRecording();
  final ui.Image markerImage = await picture.toImage(
    markerSize.width.toInt(), 
    markerSize.height.toInt()
  );
  
  final ByteData? byteData = await markerImage.toByteData(
    format: ui.ImageByteFormat.png
  );
  if (byteData == null) throw Exception('Could not convert image to bytes');
  
  return gmap.BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}

ui.Path _getPinPath(double size) {
  final path = ui.Path();
  final center = size / 2;
  final radius = size * 0.4;
  
  // Draw circle part - create rectangle manually
  final circleCenter = Offset(center, center - radius * 0.3);
  final circleRect = Rect.fromLTWH(
    circleCenter.dx - radius,
    circleCenter.dy - radius,
    radius * 2,
    radius * 2,
  );
  path.addOval(circleRect);
  
  // Draw point part
  path.moveTo(center - radius * 0.7, center + radius * 0.5);
  path.lineTo(center, size);
  path.lineTo(center + radius * 0.7, center + radius * 0.5);
  path.close();
  
  return path;
}
