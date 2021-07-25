import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:rehal_scanner/public.dart';

void main() {
  runApp(MaterialApp(
    home: MyHome(),
    routes: {
      "result": (ctx) => OnSuccessWidget(),
      "failure": (ctx) => OnFailure()
    },
  ));
}

class MyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rehal Ticket Scanner ')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => QRViewExample(),
            ));
          },
          child: Text('qrView'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  int timer = 0;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  void stopCamera() async {
    await controller.stopCamera();
    setState(() {});
  }

  void reumse() async {
    await controller.resumeCamera();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: Text('pause', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: Text('resume', style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) async {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      try {
        List<String> code = result.code.split(",");
        print("resulttt ${code[0]}");
        if (result.code.contains(",")) {
          Uri uri = Uri.parse("${Public.baseUrl}/bookings/${code[1]}");
          await http.get(uri, headers: {"auth-token": code[1]});
          Navigator.of(context).popAndPushNamed("result");
        } else {
          Navigator.of(context).popAndPushNamed("failure");
        }
      } catch (e) {
        Navigator.of(context).popAndPushNamed("failure");
      }
    });
    setState(() {
      result = null;
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class OnFailure extends StatefulWidget {
  @override
  _OnFailureState createState() => _OnFailureState();
}

class _OnFailureState extends State<OnFailure> {
  initState() {
    Future.delayed(Duration(seconds: 1)).then((value) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => QRViewExample())));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Ticket not  Found !"),
          leading: BackButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (ctx) => QRViewExample())),
          ),
        ),
        body: Center(
            child: FlatButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (ctx) => QRViewExample())),
                child: Text("Click to Scan another code"))));
  }
}

class OnSuccessWidget extends StatefulWidget {
  OnSuccessWidget({
    this.stopCamera,
  });
  Function stopCamera;

  @override
  _OnSuccessWidgetState createState() => _OnSuccessWidgetState();
}

class _OnSuccessWidgetState extends State<OnSuccessWidget> {
  initState() {
    Future.delayed(Duration(seconds: 1)).then((value) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => QRViewExample())));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Ticket found !!"),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (ctx) => QRViewExample()));
            },
          ),
        ),
        body: Center(
            child: Text(
          "Ticket is Valid",
          style: TextStyle(
              color: Colors.green, fontSize: 25, fontWeight: FontWeight.bold),
        )));
  }
}
