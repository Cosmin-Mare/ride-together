import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

Future<Uint8List> createFlutterIcon({
    required IconData icon,
    required Color color,
    required double size,
  }) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  painter.layout();
  painter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw Exception('Failed to create icon image');
  }
  return bytes.buffer.asUint8List();
}

Future<geolocator.Position?> getCurrentPosition() async {
  bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;
  geolocator.LocationPermission permission =
      await geolocator.Geolocator.checkPermission();
  if (permission == geolocator.LocationPermission.denied) {
    permission = await geolocator.Geolocator.requestPermission();
    if (permission == geolocator.LocationPermission.denied) return null;
  }
  return await geolocator.Geolocator.getCurrentPosition();
}