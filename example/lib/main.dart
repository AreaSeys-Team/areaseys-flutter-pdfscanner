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

  @override
  Widget build(BuildContext context) {
    final wrap = ReorderableWrap(
        alignment: WrapAlignment.start,
        spacing: 5,
        runSpacing: 10,
        children: List<Widget>.generate(_processedImagesPaths.length, _buildPageItem),
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
      backgroundColor: Colors.grey[200],
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
              margin: EdgeInsets.only(
                top: 40,
              ),
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
              child: Row(
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
              //_pageItems.add(_buildPageItem(_processedImagesPaths.length - 1));
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
      final String deleted = _processedImagesPaths.removeAt(oldIndex);
      _processedImagesPaths.insert(newIndex, deleted);
    });
  }

  Widget _buildPageItem(final int index) {
    final width = (MediaQuery.of(context).size.width / 3) - 10;
    final height = width * 1.6;
    print(width.toString());
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
                      File(_processedImagesPaths[index]),
                      fit: BoxFit.cover,
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
                          _processedImagesPaths.removeAt(index);
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
