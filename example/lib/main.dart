import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';
import 'package:reorderables/reorderables.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ContentBody(),
    );
  }
}

class ContentBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StateReorderableWrap();
}

class _StateReorderableWrap extends State<ContentBody> {
  final List<String> _processedImagesPaths = List(); //<-- returned by plugin.
  final List<Widget> _pageItems = List<Widget>();

  @override
  void didChangeDependencies() {
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738252272.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738275934.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738290705.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738252272.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738275934.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738290705.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738252272.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738275934.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738290705.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738252272.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738275934.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738290705.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738252272.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738275934.png");
    _processedImagesPaths.add("/storage/emulated/0/6conecta_documents/scann_1571738290705.png");
    _pageItems.add(_buildPageItem(0));
    _pageItems.add(_buildPageItem(1));
    _pageItems.add(_buildPageItem(2));
    _pageItems.add(_buildPageItem(3));
    _pageItems.add(_buildPageItem(4));
    _pageItems.add(_buildPageItem(5));
    _pageItems.add(_buildPageItem(6));
    _pageItems.add(_buildPageItem(7));
    _pageItems.add(_buildPageItem(8));
    _pageItems.add(_buildPageItem(9));
    _pageItems.add(_buildPageItem(10));
    _pageItems.add(_buildPageItem(11));
    _pageItems.add(_buildPageItem(12));
    _pageItems.add(_buildPageItem(13));
    _pageItems.add(_buildPageItem(14));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final wrap = ReorderableWrap(
        alignment: WrapAlignment.start,
        spacing: 5,
        runSpacing: 10,
        children: _pageItems,
        minMainAxisCount: 3,
        onReorder: _onReorder,
        onNoReorder: (int index) {
          //this callback is optional
          debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
        },
        onReorderStarted: (int index) {
          //this callback is optional
          debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
        });
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _launchScannerPlugin,
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Plugin Image Scanner by AreaSeys'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(
                top: 16,
                left: 16,
              ),
              child: Text(
                "Long press and drag for reorder pages...",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: wrap,
            ),
          ],
        ),
      ),
    );
  }

  void _launchScannerPlugin() async {
    int selectedSource = Pdfscanner.CAMERA;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return SimpleDialog(
          title: Text("Select image source"),
          children: <Widget>[
            SimpleDialogOption(
              child:  Row(
                children: <Widget>[
                  Icon(Icons.camera_alt),
                  Container(width: 5),
                  Expanded(
                    child: Text("Take a new photo"),
                  ),
                ],
              ),
              onPressed: () {
                selectedSource = Pdfscanner.CAMERA;
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
                    child: Text("Select image from files"),
                  ),
                ],
              ),
              onPressed: () {
                selectedSource = Pdfscanner.FILES;
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
    Pdfscanner.scan(scanSource: selectedSource)
        .then((final String path) => setState(() => setState(() {
              print("NEW PATH: $path");
              _processedImagesPaths.add(path);
              _pageItems.add(_buildPageItem(_processedImagesPaths.length - 1));
            })))
        .catchError(
          (final error) => showDialog(
            context: context,
            builder: (final ctx) => AlertDialog(
              title: Text("Error!"),
              content: Text(error),
            ),
          ),
        );
  }

  void _onReorder(final int oldIndex, final int newIndex) {
    setState(() {
      Widget pageItem = _pageItems.removeAt(oldIndex);
      _pageItems.insert(newIndex, pageItem);
    });
  }

  Widget _buildPageItem(final int index) {
    final width = (MediaQuery.of(context).size.width / 3) - 10;
    final height = width * 1.5;
    print(width.toString());
    if (index < _processedImagesPaths.length) {
      return Container(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
                margin: EdgeInsets.all(5),
                child: Image.file(
                  File(_processedImagesPaths[index]),
                  fit: BoxFit.cover,
                )),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  child: Text(
                    "Page" + index.toString(),
                    textAlign: TextAlign.center,
                  ),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      Color(0x94C4C4C4),
                      Colors.white,
                    ],
                  )),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[200],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              iconSize: 50,
              color: Colors.grey[200],
              onPressed: _launchScannerPlugin,
            ),
            Text(
              "Add scan",
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
      );
    }
  }
}
