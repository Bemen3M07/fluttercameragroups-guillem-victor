import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class AudioPlayerModel extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double speed = 1.0;

  AudioPlayer get player => _player;

  AudioPlayerModel() {
    _init();
  }

  Future<void> _init() async {
    await _player.setAsset('assets/audio/sample.mp3');
    duration = _player.duration ?? Duration.zero;

    _player.positionStream.listen((pos) {
      position = pos;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
  }

  void play() => _player.play();
  void pause() => _player.pause();

  void seekForward() {
    final newPos = position + const Duration(seconds: 5);
    _player.seek(newPos < duration ? newPos : duration);
  }

  void seekBackward() {
    final newPos = position - const Duration(seconds: 5);
    _player.seek(newPos.isNegative ? Duration.zero : newPos);
  }

  void seekTo(Duration newPosition) {
    _player.seek(newPosition);
  }

  void setSpeed(double s) {
    speed = s;
    _player.setSpeed(s);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerModel(),
      child: MaterialApp(
        home: const AudioHome(),
      ),
    );
  }
}

class AudioHome extends StatelessWidget {
  const AudioHome({super.key});

  @override
  Widget build(BuildContext context) {
    final audioModel = Provider.of<AudioPlayerModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reproducció d\'Àudio')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              value: audioModel.position.inMilliseconds.toDouble(),
              min: 0,
              max: audioModel.duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                audioModel.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
            Text(
              '${audioModel.position.toString().split('.').first} / '
              '${audioModel.duration.toString().split('.').first}',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.replay_5),
                  onPressed: audioModel.seekBackward,
                ),
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    audioModel.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    audioModel.isPlaying
                        ? audioModel.pause()
                        : audioModel.play();
                  },
                ),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.forward_5),
                  onPressed: audioModel.seekForward,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Velocitat: "),
                DropdownButton<double>(
                  value: audioModel.speed,
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                    DropdownMenuItem(value: 1.0, child: Text('1x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2.0, child: Text('2x')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      audioModel.setSpeed(value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
