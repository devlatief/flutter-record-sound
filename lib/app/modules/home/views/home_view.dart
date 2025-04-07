import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Recording button section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Obx(() {
                  return GestureDetector(
                    onTap: () async {
                      if (controller.isRecording.value) {
                        await controller.stopRecording();
                      } else {
                        await controller.startRecording();
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.isRecording.value
                            ? Colors.red
                            : Colors.blue,
                      ),
                      child: Icon(
                        controller.isRecording.value ? Icons.stop : Icons.mic,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Obx(() => Text(
                      controller.isRecording.value
                          ? 'Recording...'
                          : 'Tap to record',
                      style: const TextStyle(fontSize: 16),
                    )),
              ],
            ),
          ),

          // Divider
          const Divider(thickness: 1),

          // Recordings list section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Recordings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.recordedFiles.isEmpty) {
                      return const Center(
                        child: Text('No recordings yet'),
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.recordedFiles.length,
                      itemBuilder: (context, index) {
                        final filePath = controller.recordedFiles[index];
                        final fileName = _getFileName(filePath);
                        final isSelected =
                            controller.selectedFile.value == filePath;

                        return ListTile(
                          title: Text(fileName),
                          selected: isSelected,
                          selectedTileColor:
                              Colors.blue.withValues(alpha: 0.1 * 255),
                          leading: Icon(
                            Icons.audio_file,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Play button
                              IconButton(
                                icon: Obx(() {
                                  final isPlayingThisFile = controller
                                          .isPlaying.value &&
                                      controller.audioPath.value == filePath;
                                  return Icon(
                                    isPlayingThisFile
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                    color: isPlayingThisFile
                                        ? Colors.red
                                        : Colors.blue,
                                  );
                                }),
                                onPressed: () async {
                                  controller.selectFile(filePath);
                                  if (controller.isPlaying.value &&
                                      controller.audioPath.value == filePath) {
                                    await controller.stopPlaying();
                                  } else {
                                    await controller.playRecording();
                                  }
                                },
                              ),
                              // Delete button
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Delete Recording',
                                    middleText:
                                        'Are you sure you want to delete this recording?',
                                    textConfirm: 'Delete',
                                    textCancel: 'Cancel',
                                    confirmTextColor: Colors.white,
                                    onConfirm: () {
                                      controller.deleteRecording(filePath);
                                      Get.back();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            controller.selectFile(filePath);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.loadRecordedFiles();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
