import 'package:qr/qr.dart';
import 'package:flutter/material.dart';

class QrPainter extends CustomPainter {
  final String data;
  QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    // final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
    final qrCode = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L);

    final qrImage = QrImage(qrCode);

    final paint = Paint()..color = Colors.black;
    final moduleSize = size.width / qrImage.moduleCount;

    for (var x = 0; x < qrImage.moduleCount; x++) {
      for (var y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final rect = Rect.fromLTWH(
            x * moduleSize,
            y * moduleSize,
            moduleSize,
            moduleSize,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
