import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HomeController extends GetxController {
  final record = AudioRecorder();
  final audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSubscription;

  RxBool isRecording = false.obs;
  RxBool isPlaying = false.obs;
  RxString audioPath = ''.obs;
  RxList<String> recordedFiles = <String>[].obs;
  RxString selectedFile = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _requestPermission();
    loadRecordedFiles();
  }

  Future<void> _requestPermission() async {
    // Request microphone permission
    final micPermission = await record.hasPermission();
    if (!micPermission) {
      Get.snackbar(
        'Permission Required',
        'Microphone permission is required to record audio',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    // Request storage permissions for Android
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          Get.snackbar(
            'Permission Required',
            'Storage permission is required to save recordings',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    }
  }

  Future<String> _getRecordingPath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Get the external storage directory for Android
      directory = await getExternalStorageDirectory();

      // Create a specific folder for our app recordings if it doesn't exist
      final appDir = Directory('${directory!.path}/AudioRecordings');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      directory = appDir;
    } else {
      // For iOS and other platforms, use the documents directory
      directory = await getApplicationDocumentsDirectory();
    }

    // Generate a unique filename with timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${directory.path}/recording_$timestamp.m4a';
  }

  Future<void> startRecording() async {
    try {
      if (await record.hasPermission()) {
        final path = await _getRecordingPath();

        await record.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        audioPath.value = path;
        isRecording.value = true;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start recording: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      await record.stop();
      isRecording.value = false;

      // Add the new recording to the list and refresh the list
      if (audioPath.value.isNotEmpty) {
        recordedFiles.add(audioPath.value);
        selectedFile.value = audioPath.value;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to stop recording: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loadRecordedFiles() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        final appDir = Directory('${directory!.path}/AudioRecordings');
        if (await appDir.exists()) {
          directory = appDir;
        } else {
          return; // Directory doesn't exist yet
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();

      recordedFiles.value = files;

      // Set the most recent file as selected if available
      if (files.isNotEmpty) {
        selectedFile.value = files.last;
        audioPath.value = files.last;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load recordings: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectFile(String filePath) {
    selectedFile.value = filePath;
    audioPath.value = filePath;
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        recordedFiles.remove(filePath);

        if (selectedFile.value == filePath) {
          selectedFile.value =
              recordedFiles.isNotEmpty ? recordedFiles.last : '';
          audioPath.value = selectedFile.value;
        }

        Get.snackbar(
          'Success',
          'Recording deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete recording: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> playRecording() async {
    try {
      if (audioPath.value.isNotEmpty) {
        // Cancel any existing subscription
        await _playerCompleteSubscription?.cancel();

        await audioPlayer.play(DeviceFileSource(audioPath.value));
        isPlaying.value = true;

        // Add the completion listener
        _playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((_) {
          isPlaying.value = false;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to play recording: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.stop();
      isPlaying.value = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to stop playing: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    record.dispose();
    audioPlayer.dispose();
    super.onClose();
  }
}
