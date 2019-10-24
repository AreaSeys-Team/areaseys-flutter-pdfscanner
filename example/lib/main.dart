import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  build(context) => MaterialApp(debugShowCheckedModeBanner: false, home: PdfScannerScreen(
    iconButtonGeneratePdf: Icon(Icons.insert_drive_file, color: Colors.white),
  ));
}
