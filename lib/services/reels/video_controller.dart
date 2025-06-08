
import 'package:video_player/video_player.dart';

class VideoControllerManager {
  static final VideoControllerManager _instance =
      VideoControllerManager._internal();
  factory VideoControllerManager() => _instance;
  VideoControllerManager._internal();

  final List<VideoPlayerController> _controllers = [];

  // Register a video controller
  void registerController(VideoPlayerController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  // Unregister a video controller
  void unregisterController(VideoPlayerController controller) {
    _controllers.remove(controller);
  }

  // Play a specific controller and pause all others
  void playController(VideoPlayerController controller) {
    for (var c in _controllers) {
      if (c != controller && c.value.isPlaying) {
        c.pause();
      }
    }
    if (!controller.value.isPlaying) {
      controller.play();
    }
  }

  // Pause all controllers
  void pauseAll() {
    for (var controller in _controllers) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  // Dispose all controllers (optional, for cleanup)
  void disposeAll() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
