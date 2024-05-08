import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  var signSpeakApp = const SignSpeakApp();
  runApp(signSpeakApp);
}

class SignSpeakApp extends StatelessWidget {
  const SignSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SignSpeak',
      home: SignSpeakHomePage(),
    );
  }
}

class SignSpeakHomePage extends StatefulWidget {
  const SignSpeakHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignSpeakHomePageState createState() => _SignSpeakHomePageState();
}

class _SignSpeakHomePageState extends State<SignSpeakHomePage> {
  late CameraController cameraController;
  bool isDetecting = false;
  String result = '';

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  Future<void> initCamera() async {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    await cameraController.initialize();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  void detectHandSign(CameraImage image) async {
    if (isDetecting) return;
    isDetecting = true;

    var recognitions = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      numResults: 2,
    );

    result = recognitions!.isEmpty
        ? 'No hand sign detected'
        : recognitions[0]['label'];

    setState(() {});
    isDetecting = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSpeak'),
      ),
      body: Stack(
        children: [
          CameraPreview(cameraController),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white.withOpacity(0.8),
              child: Text(
                result,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await cameraController.initialize();
          cameraController.startImageStream(detectHandSign);
        },
        child: const Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}