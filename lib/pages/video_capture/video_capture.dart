import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_processor.dart';
import 'package:myapp_flt_02/utils/video_media_utils.dart';
import 'package:myapp_flt_02/utils/mixins/video_file_drop_mixin.dart';
import 'package:myapp_flt_02/utils/notification_helper.dart';
import 'package:myapp_flt_02/widgets/video_file_list_item.dart';
import 'package:myapp_flt_02/widgets/video_speed_dialog.dart';
import 'package:path/path.dart' as path;

class VideoCaptureWidget extends StatefulWidget {
  const VideoCaptureWidget({super.key});

  @override
  State<VideoCaptureWidget> createState() => _VideoCaptureWidgetState();
}

class _VideoCaptureWidgetState extends State<VideoCaptureWidget> with FileDropMixin {
  void _handleDragDone(details) {
    onDragDone(
      details,
      fileFilter: isVideoFile,
      onFilesFiltered: (count) {
        if (mounted) {
          NotificationHelper.showFilesFiltered(context, count);
        }
      },
    );
  }

  Future<void> _captureScreenshot(XFile file) async {
    final selectedInterval = await showSliderSelectionDialog(
      context,
      title: '选择截图间隔',
      message: '设置每隔多少分钟截取一帧画面',
      config: intervalSliderConfig(),
    );

    if (selectedInterval == null) return;

    final int intervalMinutes = selectedInterval.toInt();
    final int intervalSeconds = intervalMinutes * 60;
    final String inputPath = file.path;
    final String baseName = path.basenameWithoutExtension(inputPath);

    try {
      await FFmpegProcessor.captureScreenshots(inputPath, intervalSeconds);
      NotificationHelper.showScreenshotComplete(
        context,
        dirName: baseName,
        intervalMinutes: intervalMinutes,
      );
    } catch (e) {
      NotificationHelper.showScreenshotFailed(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VideoDropZone(
          isDragging: isDragging,
          onDragEntered: onDragEntered,
          onDragExited: onDragExited,
          onDragDone: _handleDragDone,
        ),
        Expanded(
          child: !hasFiles
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('请将视频文件拖拽到上方区域', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: fileCount,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return FileListItem(
                      file: file,
                      trailing: TextButton.icon(
                        onPressed: () => _captureScreenshot(file),
                        icon: const Icon(Icons.image_outlined, size: 20),
                        label: const Text('截图'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
