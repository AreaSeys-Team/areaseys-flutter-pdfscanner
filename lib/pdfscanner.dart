import 'dart:async';

import 'package:flutter/services.dart';

class Pdfscanner {
  static const int CAMERA = 4;
  static const int FILES = 5;
  static const MethodChannel _channel = const MethodChannel('pdfscanner');

  /// Opens native plugin for scan, source can be specified using:
  /// Pdfscanner.CAMERA
  /// Pdfscanner.FILES
  /// by default scanner source is CAMERA.
  static Future<String> scan({final int scanSource = CAMERA}) async {
    try {
      final String response = await _channel.invokeMethod('scan', scanSource);
      print("PDFScannerPlugin: result of scanning -> $response");
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }
}
