import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// SEE THIS LINK FOR ADD MORE PAGE SIZES
///
///https://www.prepressure.com/library/paper-size

enum PageSize {
  //ISO A paper sizes
  A0,
  A1,
  A2,
  A3,
  A4,
  A5,
  A6,
  A7,
  A8,

  //American paper sizes
  AMERICAN_LETTER,
  AMERICAN_LEGAL,
  AMERICAN_LEDGER,
  AMERICAN_EXECUTIVE,
  AMERICAN_ANSI_C,
  AMERICAN_ANSI_D,
  AMERICAN_ANSI_E,
}

// PageSize.X : [width, Height]
final _pageSizes = {
  //ISO A paper sizes
  PageSize.A0: [2384, 3370],
  PageSize.A1: [1684, 2384],
  PageSize.A2: [1190, 1684],
  PageSize.A3: [842, 1190],
  PageSize.A4: [595, 842],
  PageSize.A5: [420, 595],
  PageSize.A6: [298, 420],
  PageSize.A7: [210, 298],
  PageSize.A8: [148, 210],

  PageSize.AMERICAN_LETTER: [612, 792],
  PageSize.AMERICAN_LEGAL: [612, 1008],
  PageSize.AMERICAN_LEDGER: [792, 1224],
  PageSize.AMERICAN_EXECUTIVE: [1224, 792],
  PageSize.AMERICAN_ANSI_C: [522, 756],
  PageSize.AMERICAN_ANSI_D: [1584, 1224],
  PageSize.AMERICAN_ANSI_E: [2448, 1584],
};

class Pdfscanner {
  static const int CAMERA = 4;
  static const int FILES = 5;
  static const MethodChannel _channel = const MethodChannel('pdfscanner');

  /// Opens native plugin for scan, source can be specified using:
  /// Pdfscanner.CAMERA
  /// Pdfscanner.FILES
  /// by default scanner source is CAMERA.
  static Future<String> scan({
    final int scanSource = CAMERA,
    final String scannedImagesPath = "/ImageScannerPlugin/scanned_images",
    final String scannedImageName,
  }) async {
    try {
      final String response = await _channel.invokeMethod('scan', {
        "scanSource": scanSource,
        "scannedImagesPath": scannedImagesPath,
        "scannedImageName": scannedImageName ?? "scanned_${DateTime.now().toIso8601String()}.png"
      });
      print("PDFScannerPlugin: result of scanning -> $response");
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }

  /// Generates a beautiful PDF with images paths.
  static Future<String> generatePdf({
    @required final List<String> imagesPaths,
    @required final String pdfName,
    final String generatedPDFsPath = "/ImageScannerPlugin/generated_PDF",
    final int marginLeft = 0,
    final int marginRight = 0,
    final int marginTop = 0,
    final int marginBottom = 0,
    final bool cleanScannedImagesWhenPdfGenerate = false,
    final PageSize pageSize = PageSize.A4,
  }) async {
    try {
      final String response = await _channel.invokeMethod('generatePdf', {
        "imagesPaths": imagesPaths,
        "pdfName": pdfName,
        "generatedPDFsPath": generatedPDFsPath,
        "marginLeft": marginLeft,
        "marginRight": marginRight,
        "marginTop": marginTop,
        "marginBottom": marginBottom,
        "pageWidth": _pageSizes[pageSize][0],
        "pageHeight": _pageSizes[pageSize][1],
        "cleanScannedImagesWhenPdfGenerate": cleanScannedImagesWhenPdfGenerate,
      });
      print("PDFScannerPlugin: result of PDF generation -> $response");
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }
}
