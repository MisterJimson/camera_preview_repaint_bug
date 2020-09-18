//The top half of the screen is the scource and the bottom half is a screenshot.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }

  runApp(MaterialApp(
    home: MyApp(),
  ));
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static GlobalKey previewContainer = GlobalKey();
  CameraController controller;
  ui.Image image;
  Offset blueSquareOffset = Offset(10.0, 10.0);

  @override
  void initState() {
    super.initState();

    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _getScreenShotImage() async {
    _capturePng();
    image = await _capturePng();
    debugPrint("im height: ${image.height}, im width: ${image.width}");
    setState(() {});
  }

  Future<ui.Image> _capturePng() async {
    RenderRepaintBoundary boundary =
        previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    return image;
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text('Camera is initialising...');
    } else {
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: RepaintBoundary(
            child: GestureDetector(
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }
  }

  void _moveBlueSquare(DragUpdateDetails details) {
    setState(() {
      _getScreenShotImage();
      blueSquareOffset = blueSquareOffset + details.delta;
    });
  }

  Widget _blueSquare() {
    return Positioned(
      top: blueSquareOffset.dy,
      left: blueSquareOffset.dx,
      width: 50.0,
      height: 50.0,
      child: GestureDetector(
        onPanUpdate: _moveBlueSquare,
        child: Container(
          color: Color.fromARGB(255, 10, 10, 255),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Render Boundry Screenshot Error Example'),
      ),
      body: RepaintBoundary(
        key: previewContainer,
        child: Container(
          padding: EdgeInsets.all(0.0),
          margin: EdgeInsets.all(0.0),
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              overflow: Overflow.clip,
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                        child: Stack(children: <Widget>[
                      RepaintBoundary(
                        child: Container(child: _cameraPreviewWidget()),
                      ),
                      _blueSquare(),
                    ])),
                    Expanded(
                      child: Container(
                          //color: Color.fromARGB(50, 50, 50, 50),
                          child: CustomPaint(
                        painter: RectanglePainter(image),
                      )),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RectanglePainter extends CustomPainter {
  RectanglePainter(this.image);

  ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) {
      canvas.drawRect(
          Rect.fromLTRB(100.0, 50.0, 300.0, 200.0),
          Paint()
            ..color = Color.fromARGB(255, 50, 50, 255)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.0);
    } else {
      canvas.drawImage(image, Offset(0.0, 0.0), Paint());
    }
  }

  @override
  bool shouldRepaint(RectanglePainter old) {
    return true;
  }
}
