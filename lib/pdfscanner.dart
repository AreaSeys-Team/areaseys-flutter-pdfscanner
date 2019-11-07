import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdfscanner/SeysFlicker.dart';
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
  final Function(String imagePath) onImageScannedDeleted;
  final Function(String pdfPath) onPdfGenerated;
  final Function(String error, Exception ex) onError;

  PsfScannerScreenListener({
    this.onImageScanned = _doNothing,
    this.onImageScannedDeleted = _doNothing,
    this.onPdfGenerated = _doNothing,
    this.onError,
  });

  List<String> getScannedImagesPaths() => _onGetAllImages != null ? _onGetAllImages() : List<String>();

  static void _doNothing(String path) => print("Generated -> " + path);
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
  final String generatePdfTitle;
  final Icon iconButtonAddImage;
  final Icon iconButtonGeneratePdf;
  final String txtOnError;
  final String txtGeneratingPdf;
  final String toolTipContent;
  final String textDropArea;

  PdfScannerScreen({
    this.imagesPaths,
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
    this.generatePdfTitle = "Generate PDF",
    this.iconButtonAddImage,
    this.iconButtonGeneratePdf,
    this.listener,
    this.txtOnError = "Error on scan image. Try again.",
    this.txtGeneratingPdf = "Generating pdf...",
    this.toolTipContent = "No scanned pages, please tap in add(+) button to start scan.",
    this.textDropArea = "Drag pages here for remove",
  });

  @override
  State<StatefulWidget> createState() => _PdfScannerScreen();
}

class _PdfScannerScreen extends State<PdfScannerScreen> {
  List<String> _imagesPaths;
  ProgressDialog pr;
  bool _dialVisible = false;

  int _pageInSorting = -1;
  int _pageClicked = -1;
  double _heightDropArea = 0;
  double _dropAreaOpacity = 0;
  bool _warnDelete = false;
  String _pathWaitingForDelete;

  @override
  void initState() {
    _imagesPaths = widget.imagesPaths ?? List();
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
    debugPrint("List of scanned lenght -> ${_imagesPaths.length}");
    final wrap = ReorderableWrap(
      buildDraggableFeedback: (context, constraints, widget) {
        return Material(
          color: Colors.transparent,
          child: Container(
            child: _buildPageItem(_pageInSorting, true),
          ),
        );
      },
      alignment: WrapAlignment.start,
      spacing: 5,
      runSpacing: 10,
      children: List<Widget>.generate(_imagesPaths.length, (index) => _buildPageItem(index, false)),
      minMainAxisCount: 3,
      needsLongPressDraggable: true,
      onReorder: _onReorder,
      onNoReorder: (int index) {
        setState(() {
          _pageInSorting = -1;
          _heightDropArea = 0;
          _dropAreaOpacity = 0;
        });
      },
      onReorderStarted: (int index) {
        setState(() {
          _pageInSorting = index;
          _heightDropArea = 100;
          _dropAreaOpacity = 1.0;
        });
      },
    );
    return Scaffold(
      backgroundColor: widget.screenBackground,
      bottomNavigationBar: _imagesPaths.length > 0
          ? BottomAppBar(
              elevation: 10,
              child: Container(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        color: widget.primaryScreenColor,
                        child: InkWell(
                          splashColor: Colors.white,
                          onTap: () {
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
                              Future.delayed(Duration(seconds: 2), () => pr.hide());
                              widget.listener?.onPdfGenerated(result);
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              widget.iconButtonGeneratePdf != null
                                  ? Container(
                                      child: widget.iconButtonGeneratePdf,
                                      margin: const EdgeInsets.only(right: 6),
                                    )
                                  : Container(),
                              Text(widget.generatePdfTitle, style: TextStyle(color: Colors.white, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: SpeedDial(
        marginRight: 18,
        marginBottom: 20,
        child: !_dialVisible ? Icon(Icons.add) : Icon(Icons.close),
        animatedIconTheme: IconThemeData(size: 22.0),
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.2,
        onOpen: () => setState(() => _dialVisible = true),
        onClose: () => setState(() => _dialVisible = false),
        backgroundColor: widget.primaryScreenColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
            child: Icon(
              Icons.collections,
              color: widget.primaryScreenColor,
            ),
            backgroundColor: Colors.grey[200],
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => _launchScannerPlugin(ImageSource.FILES),
          ),
          SpeedDialChild(
              child: Icon(Icons.camera_alt, color: widget.primaryScreenColor),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () => _launchScannerPlugin(ImageSource.CAMERA)),
        ],
      ),
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: widget.primaryScreenColor ?? Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildDeleteItemArea(),
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
                          widget.toolTipContent,
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

  void _launchScannerPlugin(final ImageSource source) async {
    ImagePdfScanner.scan(
      scanSource: source,
      scannedImagesPath: widget.scannedImagesPath,
      scannedImageName: widget.scannedImageName,
    )
        .then((final String path) => setState(() => setState(() {
              _imagesPaths.add(path);
              widget.listener?.onImageScanned(path);
            })))
        .catchError((final error) => setState(() {}));
  }

  void _onReorder(final int oldIndex, final int newIndex) {
    setState(() {
      final String deleted = _imagesPaths.removeAt(oldIndex);
      _imagesPaths.insert(newIndex, deleted);
      _pageClicked = -1;
      _pageInSorting = -1;
      _heightDropArea = 0;
    });
  }

  Widget _buildPageItem(final int index, bool itemInDrag) {
    final width = (MediaQuery.of(context).size.width / 3) - 10;
    final height = width * 1.6;
    final content = Container(
      width: width,
      height: height,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Container(
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
                    height: height,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                  alignment: Alignment.center,
                ),
                _pageClicked == index || itemInDrag //--> Apply mask if item is in drag or is clicked
                    ? Opacity(
                        opacity: 0.7,
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
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            child: Text(itemInDrag ? "" : "Pág. $index"),
          ),
        ],
      ),
    );
    if (itemInDrag) {
      _pathWaitingForDelete = _imagesPaths[index];
    }
    return itemInDrag
        ? LongPressDraggable<int>(
            ignoringFeedbackSemantics: true,
            onDragEnd: (details) {},
            data: index,
            maxSimultaneousDrags: 100,
            feedback: Container(
              width: 100,
              height: 100,
            ),
            child: _warnDelete
                ? Flicker(
                    minOpacity: 0.5,
                    maxOpacity: 1,
                    durationInMillis: 50,
                    child: content,
                  )
                : Container(child: content),
          )
        : content;
  }

  Widget _buildDeleteItemArea() {
    return DragTarget<int>(
      onWillAccept: (dynamic) {
        setState(() {
          _warnDelete = true;
        });
        return true;
      },
      //Be careful index change by ReorderableWrap widget. NOT USE!
      onAccept: (index) {
        Future.delayed(Duration(milliseconds: 200), () {
          //avoid deleted before wrap ends sorting.
          setState(() {
            _imagesPaths.remove(_imagesPaths.firstWhere((str) => str == _pathWaitingForDelete));
            widget.listener?.onImageScannedDeleted(_pathWaitingForDelete);
            _warnDelete = false;
          });
        });
      },
      onLeave: (data) {
        setState(() {
          _warnDelete = false;
        });
      },
      builder: (ctx, l1, l2) => Row(
        children: <Widget>[
          Expanded(
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: _dropAreaOpacity,
              child: AnimatedContainer(
                color: Colors.grey[300],
                width: MediaQuery.of(context).size.width - 10,
                height: _heightDropArea,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOutSine,
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      Container(color: _warnDelete ? Colors.redAccent : Colors.transparent),
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.delete, color: _warnDelete ? Colors.white : Colors.grey, size: 45),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.textDropArea ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _warnDelete ? Colors.white : Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
