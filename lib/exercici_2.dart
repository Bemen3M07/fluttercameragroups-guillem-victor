import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription> cameras = [];
CameraController? controller;
XFile? lastPhoto;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  if (cameras.isNotEmpty) {
    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller!.initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  bool flashOn = false;
  int cameraIndex = 0;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    XFile file = await controller!.takePicture();

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = '${appDir.path}/images';
    await Directory(imagesDir).create(recursive: true);

    final String fileName =
        'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = '$imagesDir/$fileName';

    final File savedImage = await File(file.path).copy(newPath);
    lastPhoto = XFile(savedImage.path);

    await Permission.storage.request();
    await ImageGallerySaver.saveFile(savedImage.path, name: fileName);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Foto capturada'),
          content: Text('Guardada en:\n$newPath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }

    setState(() {});
  }

  Future<void> toggleFlash() async {
    if (controller == null) return;
    flashOn = !flashOn;
    await controller!
        .setFlashMode(flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    cameraIndex = (cameraIndex + 1) % cameras.length;
    controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller!.initialize();

    if (flashOn) {
      await controller!.setFlashMode(FlashMode.torch);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      cameraScreen(),
      photoScreen(),
      mediaScreen(),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentIndex == 0
                ? 'Cámara'
                : _currentIndex == 1
                    ? 'Foto'
                    : 'Multimedia',
          ),
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.camera), label: 'Cámara'),
            BottomNavigationBarItem(
                icon: Icon(Icons.photo), label: 'Foto'),
            BottomNavigationBarItem(
                icon: Icon(Icons.music_note), label: 'Multimedia'),
          ],
        ),
      ),
    );
  }

  Widget cameraScreen() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(controller!)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.switch_camera),
              onPressed: switchCamera,
            ),
            IconButton(
              icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: toggleFlash,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: takePicture,
            ),
          ],
        ),
      ],
    );
  }

  Widget photoScreen() {
    if (lastPhoto == null) {
      return const Center(child: Text('No hay foto'));
    }
    return Center(child: Image.file(File(lastPhoto!.path)));
  }

  Widget mediaScreen() {
    return const Center(
      child: Text('Pantalla Multimedia'),
    );
  }
}
