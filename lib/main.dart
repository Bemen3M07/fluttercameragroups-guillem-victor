import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/* Declarar variables globals per tenir
 * accés des de qualsevol lloc de l'aplicació
 */
List<CameraDescription> cameras = [];
CameraController? controler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtenir la llista de càmeres disponibles
  cameras = await availableCameras();

  for (var camera in cameras) {
    debugPrint(
        'Camera found: ${camera.name}, LensDirection: ${camera.lensDirection}, SensorOrientation: ${camera.sensorOrientation}');
  }

  // Construir el controlador de la càmera (usem la primera per seguretat)
  controler = CameraController(
    cameras[0],
    ResolutionPreset.medium,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              FutureBuilder(
                future: controler?.initialize(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Expanded(
                      child: CameraPreview(controler!),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              ...cameras.map(
                (camera) => Text('Camera found: ${camera.name}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
