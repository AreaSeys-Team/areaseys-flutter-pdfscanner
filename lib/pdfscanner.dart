import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Pdfscanner {
  static const MethodChannel _channel = const MethodChannel('pdfscanner');

  static Future<String> scan() async {
    try {
      final String response = await _channel.invokeMethod('scan');
      print("PDFScannerPlugin: result of scanning -> $response");
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }

  ///Generates a pdf of
  static Future<String> generatePdf() {
    debugPrint("PDFScanner: generating pdf...");

    //TODO: Santi...

  }
}
