import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:reorderables/reorderables.dart';

/// SEE THIS LINK FOR ADD MORE PAGE SIZES
///
///https://www.prepressure.com/library/paper-size

enum ImageSource {
  CAMERA,
  FILES,
}

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

final _imageSourceToValue = {
  ImageSource.CAMERA: 4,
  ImageSource.FILES: 5,
};

class ImagePdfScanner {
  static const MethodChannel _channel = const MethodChannel('com.areaseys.imagepdfscanner.plugin');

  /// Opens native plugin for scan, source can be specified using:
  /// Pdfscanner.CAMERA
  /// Pdfscanner.FILES
  /// by default scanner source is CAMERA.
  static Future<String> scan({
    final ImageSource scanSource,
    final String scannedImagesPath,
    final String scannedImageName,
  }) async {
    try {
      final String response = await _channel.invokeMethod('scan', {
        "scanSource": scanSource != null ? _imageSourceToValue[scanSource] : _imageSourceToValue[ImageSource.CAMERA],
        "scannedImagesPath": scannedImagesPath ?? "/ImageScannerPlugin/scanned_images",
        "scannedImageName": scannedImageName ?? "scanned_${DateTime.now().millisecondsSinceEpoch.toString()}"
      });
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }

  /// Generates a beautiful PDF with images paths.
  static Future<String> generatePdf({
    @required final List<String> imagesPaths,
    @required final String pdfName,
    final String generatedPDFsPath,
    final int marginLeft = 0,
    final int marginRight = 0,
    final int marginTop = 0,
    final int marginBottom = 0,
    final bool cleanScannedImagesWhenPdfGenerate = false,
    final PageSize pageSize,
  }) async {
    try {
      final String response = await _channel.invokeMethod('generatePdf', {
        "imagesPaths": imagesPaths ?? List<String>(),
        "pdfName": pdfName ?? "scan_" + DateTime.now().millisecondsSinceEpoch.toString(),
        "generatedPDFsPath": generatedPDFsPath ?? "/ImageScannerPlugin/generated_PDF",
        "marginLeft": marginLeft ?? 0,
        "marginRight": marginRight ?? 0,
        "marginTop": marginTop ?? 0,
        "marginBottom": marginBottom ?? 0,
        "pageWidth": _pageSizes[pageSize ?? PageSize.A4][0],
        "pageHeight": _pageSizes[pageSize ?? PageSize.A4][1],
        "cleanScannedImagesWhenPdfGenerate": cleanScannedImagesWhenPdfGenerate ?? false,
      });
      return Future.value(response);
    } catch (ex) {
      return Future.error(ex);
    }
  }
}

class PsfScannerScreenListener {
  Function _onGetAllImages;
  final Function(String imagePath) onImageScanned;
  final Function(String pdfPath) onPdfGenerated;
  final Function(String error, Exception ex) onError;

  PsfScannerScreenListener({
    this.onImageScanned,
    this.onPdfGenerated,
    this.onError,
  });

  List<String> getScannedImagesPaths() => _onGetAllImages != null ? _onGetAllImages() : List<String>();
}

class PdfScannerScreen extends StatefulWidget {
  final PsfScannerScreenListener listener;
  final List<String> imagesPaths;
  final String pdfName;
  final String generatedPDFsPath;
  final int marginLeft;
  final int marginRight;
  final int marginTop;
  final int marginBottom;
  final bool cleanScannedImagesWhenPdfGenerate;
  final PageSize pageSize;
  final ImageSource scanSource;
  final String scannedImagesPath;
  final String scannedImageName;
  final Color primaryScreenColor;
  final Color accentScreenColor;
  final Color screenBackground;
  final String screenTitle;
  final String screenSubtitle;
  final String generatePdfTitle;
  final Icon iconButtonAddImage;
  final Icon iconButtonGeneratePdf;
  final String txtFromCamera;
  final String txtFromFiles;
  final String textTitleDialog;
  final String txtOnError;
  final String txtGeneratingPdf;

  PdfScannerScreen(
      {this.imagesPaths,
      this.pdfName,
      this.generatedPDFsPath,
      this.marginLeft,
      this.marginRight,
      this.marginTop,
      this.marginBottom,
      this.cleanScannedImagesWhenPdfGenerate,
      this.pageSize,
      this.scanSource,
      this.scannedImagesPath,
      this.scannedImageName,
      this.screenBackground = Colors.white,
      this.primaryScreenColor = Colors.blue,
      this.accentScreenColor = Colors.blueAccent,
      this.screenTitle = "AREAseys document scanner",
      this.screenSubtitle,
      this.generatePdfTitle = "Generate PDF",
      this.iconButtonAddImage,
      this.iconButtonGeneratePdf,
      this.listener,
      this.txtOnError = "Error on scan image. Try again.",
      this.textTitleDialog = "Select image source",
      this.txtFromCamera = "Take a new photo",
      this.txtFromFiles = "Select iamge from file",
      this.txtGeneratingPdf = "Generating pdf..."});

  @override
  State<StatefulWidget> createState() => _PdfScannerScreen();
}

class _PdfScannerScreen extends State<PdfScannerScreen> {
  List<String> _imagesPaths = List();
  ProgressDialog pr;

  @override
  void initState() {
    _imagesPaths = widget.imagesPaths ?? List<String>();
    if (widget.listener != null) {
      widget.listener._onGetAllImages = () => _imagesPaths;
    }
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);
    pr.style(
        message: widget.txtGeneratingPdf ?? "",
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: Container(
          margin: EdgeInsets.all(10),
          child: SpinKitFadingCube(
            color: widget.primaryScreenColor,
            size: 50,
          ),
        ),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final wrap = ReorderableWrap(
      alignment: WrapAlignment.start,
      spacing: 5,
      runSpacing: 10,
      children: List<Widget>.generate(_imagesPaths.length, _buildPageItem),
      minMainAxisCount: 3,
      onReorder: _onReorder,
      onNoReorder: (int index) {
        //this callback is optional
        debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
      },
      onReorderStarted: (int index) {
        //this callback is optional
        debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
      },
    );
    return Scaffold(
      backgroundColor: widget.screenBackground,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 10,
        shape: CircularNotchedRectangle(),
        color: widget.primaryScreenColor,
        child: Container(
          padding: EdgeInsets.only(left: 10),
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              MaterialButton(
                child: Row(
                  children: <Widget>[
                    widget.iconButtonGeneratePdf != null
                        ? Container(
                            child: widget.iconButtonGeneratePdf,
                            margin: const EdgeInsets.only(right: 6),
                          )
                        : Container(),
                    Text(widget.generatePdfTitle, style: TextStyle(color: Colors.white)),
                  ],
                ),
                onPressed: () {
                  pr.show();
                  ImagePdfScanner.generatePdf(
                    imagesPaths: _imagesPaths,
                    pdfName: widget.pdfName ?? "pdf_${DateTime.now().millisecondsSinceEpoch}.pdf",
                    marginTop: widget.marginTop,
                    marginBottom: widget.marginBottom,
                    marginLeft: widget.marginLeft,
                    marginRight: widget.marginRight,
                    pageSize: widget.pageSize,
                    generatedPDFsPath: widget.generatedPDFsPath,
                    cleanScannedImagesWhenPdfGenerate: widget.cleanScannedImagesWhenPdfGenerate,
                  ).then((result) {
                    Future.delayed(Duration(seconds: 5), () => pr.hide());
                    widget.listener?.onPdfGenerated(result);
                  });
                },
                elevation: 0,
                color: widget.accentScreenColor,
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _launchScannerPlugin,
        child: widget.iconButtonAddImage ?? Icon(Icons.add),
        backgroundColor: widget.accentScreenColor ?? Colors.blue,
      ),
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: widget.primaryScreenColor ?? Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          widget.screenSubtitle != null
              ? Container(
                  margin: EdgeInsets.only(
                    top: 16,
                    left: 16,
                  ),
                  child: Text(
                    widget.screenSubtitle,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              : Container(),
          Expanded(
            child: _imagesPaths.length > 0
                ? SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.only(top: 40),
                      alignment: Alignment.center,
                      child: wrap,
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.scanner, color: Colors.grey[300], size: 100),
                        Text(
                          "No scanned pages, please tap in add(+) button to start scan.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _launchScannerPlugin() async {
    var imageSource = widget.scanSource;
    if (widget.scanSource == null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return SimpleDialog(
            title: Text(widget.textTitleDialog),
            children: <Widget>[
              SimpleDialogOption(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.camera_alt),
                    Container(width: 5),
                    Expanded(
                      child: Text(widget.txtFromCamera),
                    ),
                  ],
                ),
                onPressed: () {
                  imageSource = ImageSource.CAMERA;
                  Navigator.of(context).pop();
                },
              ),
              Divider(
                indent: 10,
                endIndent: 10,
              ),
              SimpleDialogOption(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.attach_file),
                    Container(width: 5),
                    Expanded(
                      child: Text(widget.txtFromFiles),
                    ),
                  ],
                ),
                onPressed: () {
                  imageSource = ImageSource.FILES;
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
    if (imageSource == null) {
      return;
    }
    ImagePdfScanner.scan(
      scanSource: imageSource,
      scannedImagesPath: widget.scannedImagesPath,
      scannedImageName: widget.scannedImageName,
    )
        .then((final String path) => setState(() => setState(() {
              _imagesPaths.add(path);
              widget.listener?.onImageScanned(path);
            })))
        .catchError(
          (final error) => showDialog(
            context: context,
            builder: (final ctx) => AlertDialog(
              title: Text("Error!"),
              content: Text(error is String ? error : ""),
            ),
          ),
        );
  }

  void _onReorder(final int oldIndex, final int newIndex) {
    setState(() {
      final String deleted = _imagesPaths.removeAt(oldIndex);
      _imagesPaths.insert(newIndex, deleted);
    });
  }

  Widget _buildPageItem(final int index) {
    final width = (MediaQuery.of(context).size.width / 3) - 10;
    final height = width * 1.6;
    return Container(
      width: width,
      height: height,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        ),
                      ],
                    ),
                    margin: EdgeInsets.all(width / 10),
                    padding: EdgeInsets.all(width / 20),
                    child: Image.file(
                      File(_imagesPaths[index]),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                    alignment: Alignment.center,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.grey[300],
                    shape: CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _imagesPaths.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            child: Text("Page $index"),
          ),
        ],
      ),
    );
  }
}
