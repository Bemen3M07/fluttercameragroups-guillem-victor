import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/* Variables globales */
List<CameraDescription> cameras = [];
CameraController? controller;
XFile? lastPhoto;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtener cámaras disponibles
  cameras = await availableCameras();

  if (cameras.isEmpty) {
    debugPrint('No cameras found');
  } else {
    // Inicializar con la primera cámara
    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller?.initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0; // BottomNavigationBar index

  // Para alternar flash
  bool flashOn = false;

  // Alternar cámara frontal/trasera
  int cameraIndex = 0;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Función para capturar foto
  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      XFile file = await controller!.takePicture();
      lastPhoto = file;

      // Mostrar alerta con ruta
      if (mounted) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Foto Capturada'),
                  content: Text('Guardada en: ${file.path}'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'))
                  ],
                ));
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
    }
    setState(() {});
  }

  // Función para alternar flash
  Future<void> toggleFlash() async {
    if (controller == null) return;
    flashOn = !flashOn;
    await controller!.setFlashMode(
        flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  // Función para cambiar cámara
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
    List<Widget> screens = [
      cameraScreen(),
      photoScreen(),
      mediaScreen(),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(_currentIndex == 0
              ? 'Cámara'
              : _currentIndex == 1
                  ? 'Foto'
                  : 'Multimedia'),
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() {
            _currentIndex = index;
          }),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cámara'),
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Foto'),
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
              tooltip: 'Cambiar cámara',
            ),
            IconButton(
              icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: toggleFlash,
              tooltip: 'Flash',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: takePicture,
              tooltip: 'Capturar foto',
            ),
          ],
        ),
      ],
    );
  }

  Widget photoScreen() {
    if (lastPhoto == null) {
      return const Center(child: Text('No hay foto tomada'));
    }

    return Center(
      child: Image.file(File(lastPhoto!.path)),
    );
  }

  Widget mediaScreen() {
    return const Center(
      child: Text('Pantalla Multimedia (Ejercicio 3)'),
    );
  }
}
