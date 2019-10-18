import 'dart:async';

import 'package:flutter/services.dart';

class Pdfscanner {
  static const MethodChannel _channel = const MethodChannel('pdfscanner');

  static Future<String> scan() async {
    final String response = await _channel.invokeMethod('scan');
    return response;
  }
}
