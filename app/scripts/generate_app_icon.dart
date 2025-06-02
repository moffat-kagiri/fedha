// scripts/generate_app_icon.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate the app icon
  final iconData = await generateWalletIcon();

  // Save to assets folder
  final file = File('assets/icons/fedha_icon.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(iconData);

  print('App icon generated successfully at: ${file.path}');
}

Future<Uint8List> generateWalletIcon() async {
  const size = 512.0; // High resolution for app icon

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Background circle with gradient effect
  final backgroundPaint =
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(size / 2, size / 2),
          size / 2,
          [
            const Color(0xFF4CAF50), // Primary green
            const Color(0xFF2E7D32), // Darker green
          ],
          [0.0, 1.0],
        );

  // Draw background circle
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2,
    backgroundPaint,
  );

  // Wallet shadow
  final shadowPaint =
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  final walletShadowRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: const Offset(size / 2 + 2, size / 2 + 2),
      width: size * 0.5,
      height: size * 0.32,
    ),
    const Radius.circular(12),
  );
  canvas.drawRRect(walletShadowRect, shadowPaint);

  // Main wallet body
  final walletPaint =
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

  final walletRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: const Offset(size / 2, size / 2),
      width: size * 0.5,
      height: size * 0.32,
    ),
    const Radius.circular(12),
  );
  canvas.drawRRect(walletRect, walletPaint);

  // Wallet flap
  final flapRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(size / 2, size / 2 - size * 0.08),
      width: size * 0.5,
      height: size * 0.12,
    ),
    const Radius.circular(12),
  );
  canvas.drawRRect(flapRect, walletPaint);

  // Wallet clasp/button
  final claspPaint =
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.fill;

  final claspRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(size / 2, size / 2 - size * 0.08),
      width: size * 0.08,
      height: size * 0.04,
    ),
    const Radius.circular(4),
  );
  canvas.drawRRect(claspRect, claspPaint);

  // Currency symbol (KSh)
  final textStyle = ui.TextStyle(
    color: const Color(0xFF2E7D32),
    fontSize: size * 0.08,
    fontWeight: FontWeight.bold,
  );

  final paragraphBuilder =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
        ..pushStyle(textStyle)
        ..addText('KSh');

  final paragraph =
      paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: size));

  canvas.drawParagraph(
    paragraph,
    Offset(size / 2 - paragraph.maxIntrinsicWidth / 2, size / 2 + size * 0.02),
  );

  // Decorative elements (small circles for cards/coins)
  final dotPaint =
      Paint()
        ..color = const Color(0xFF2E7D32).withOpacity(0.3)
        ..style = PaintingStyle.fill;

  for (int i = 0; i < 3; i++) {
    canvas.drawCircle(
      Offset(
        size / 2 - size * 0.12 + (i * size * 0.12),
        size / 2 - size * 0.04,
      ),
      size * 0.008,
      dotPaint,
    );
  }

  // Add a subtle shine effect
  final shinePaint =
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(size, size), [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ]);

  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, shinePaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}

// Create a simpler version for smaller sizes
Future<Uint8List> generateSimpleWalletIcon(double size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Simple green circle background
  final backgroundPaint = Paint()..color = const Color(0xFF4CAF50);

  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, backgroundPaint);

  // Simple white wallet shape
  final walletPaint = Paint()..color = Colors.white;

  final walletPath =
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size / 2, size / 2),
            width: size * 0.6,
            height: size * 0.4,
          ),
          Radius.circular(size * 0.05),
        ),
      );

  canvas.drawPath(walletPath, walletPaint);

  // Simple currency symbol
  final textStyle = ui.TextStyle(
    color: const Color(0xFF2E7D32),
    fontSize: size * 0.15,
    fontWeight: FontWeight.bold,
  );

  final paragraphBuilder =
      ui.ParagraphBuilder(ui.ParagraphStyle())
        ..pushStyle(textStyle)
        ..addText('₹');

  final paragraph =
      paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: size));

  canvas.drawParagraph(
    paragraph,
    Offset(
      size / 2 - paragraph.maxIntrinsicWidth / 2,
      size / 2 - paragraph.height / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}
