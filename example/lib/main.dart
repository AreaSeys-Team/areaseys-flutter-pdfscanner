import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  String get _nowTime => DateTime.now().millisecondsSinceEpoch.toString();

  PsfScannerScreenListener _pdfScannerScreenListener = PsfScannerScreenListener(onImageScanned: (newImage) {
    print("se ha añadido la imagen escaneada: " + newImage);
  }, onPdfGenerated: (pdfPath) {
    print("se ha generado el pdf " + pdfPath);
  });

  @override
  build(context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PdfScannerScreen(
          listener: _pdfScannerScreenListener,
          iconButtonGeneratePdf: Icon(Icons.book, color: Colors.white),
          marginTop: 50,
          marginBottom: 50,
          marginLeft: 40,
          marginRight: 40,
          generatedPDFsPath: "/6conecta_Contractors/pdfs",
          scannedImagesPath: "/6Conecta_Contractors/images",
          pdfName: "scannedPDF_" + _nowTime + ".pdf",
          accentScreenColor: Colors.orangeAccent,
          primaryScreenColor: Colors.orange,
          generatePdfTitle: "Generar PDF",
          screenTitle: "6conecta Contractors PDF scanner",
          pageSize: PageSize.A4,
          cleanScannedImagesWhenPdfGenerate: false,
          screenBackground: Colors.grey[300],
        ),
      );
}
