import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';
import 'package:open_file/open_file.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  String get _nowTime => DateTime.now().millisecondsSinceEpoch.toString();

  PsfScannerScreenListener _pdfScannerScreenListener = PsfScannerScreenListener(onImageScanned: (newImage) {
    print("se ha añadido la imagen escaneada: " + newImage);
  }, onPdfGenerated: (pdfPath) {
    print("se ha generado el pdf " + pdfPath);
    OpenFile.open(pdfPath);
  });

  @override
  build(context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PdfScannerScreen(
          listener: _pdfScannerScreenListener,
          iconButtonGeneratePdf: Icon(Icons.book, color: Colors.white),
          toolTipContent: "Press add button to start...",
          marginTop: 50,
          marginBottom: 50,
          marginLeft: 40,
          marginRight: 40,
          generatedPDFsPath: "/6conecta_Contractors/pdfs",
          scannedImagesPath: "/6Conecta_Contractors/images",
          pdfName: "scannedPDF_" + _nowTime + ".pdf",
          accentScreenColor: Colors.blueAccent,
          primaryScreenColor: Colors.blue,
          generatePdfTitle: "Generar PDF",
          screenTitle: "6conecta PDF scanner",
          pageSize: PageSize.A4,
          cleanScannedImagesWhenPdfGenerate: false,
          screenBackground: Colors.grey[100],
        ),
      );
}
