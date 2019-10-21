import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String> _paths = List();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AreaSeys - PDF scanner plugin'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GridView.builder(
                itemCount: _paths.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemBuilder: (ctx, index) => Container(
                  child: Stack(
                    children: <Widget>[
                      Image.file(File(_paths[index])),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            child: Text(
                              "Page" + index.toString(),
                              textAlign: TextAlign.center,
                            ),
                            color: Color(0x94C4C4C4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Ruta del PDF escaneado:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            Container(
              height: 20,
            ),
            Container(
              height: 50,
            ),
            MaterialButton(
              onPressed: () => Pdfscanner.scan()
                  .then((String path) => setState(() {
                        setState(() {
                          _paths.add(path);
                        });
                      }))
                  .catchError(
                    (error) => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("Error!"),
                        content: Text(error),
                      ),
                    ),
                  ),
              child: Text("Scan"),
              color: Colors.blue,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
