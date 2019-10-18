import 'package:flutter/material.dart';
import 'package:pdfscanner/pdfscanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _path = 'press button for open native plugin and start scan.';

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
            Text(
              'Ruta del PDF escaneado:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            Container(
              height: 20,
            ),
            Text(
              _path,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            Container(
              height: 50,
            ),
            MaterialButton(
              onPressed: () => Pdfscanner.scan().then((String path) => setState(() => _path = path)),
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
