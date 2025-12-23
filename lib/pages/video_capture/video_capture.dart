import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:myapp_flt_02/utils/mixins/file_drop_mixin.dart';
import 'package:myapp_flt_02/widgets/empty_file_list.dart';
import 'package:myapp_flt_02/widgets/file_list_item.dart';
import 'package:myapp_flt_02/widgets/loading_dialog.dart';
import 'package:myapp_flt_02/widgets/slider_selection_dialog.dart';
import 'package:path/path.dart' as path;

class VideoCaptureWidget extends StatefulWidget {
  const VideoCaptureWidget({super.key});

  @override
  State<VideoCaptureWidget> createState() => _VideoCaptureWidgetState();
}

class _VideoCaptureWidgetState extends State<VideoCaptureWidget>
    with FileDropMixin {
  void _handleDragDone(details) {
    onDragDone(
      details,
      fileFilter: isVideoFile,
      onFilesFiltered: (count) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已忽略 $count 个非视频文件')),
          );
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
    final String dir = path.dirname(inputPath);
    final String baseName = path.basenameWithoutExtension(inputPath);
    final String outputDir = path.join(dir, baseName);
    // ffmpeg image2 pattern requires %d / %0Nd, cannot use %s
    final String outputPattern =
        path.join(outputDir, '${baseName}@%04d_frame.jpg');

    final Directory folder = Directory(outputDir);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final bool hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg'),
        ),
      );
      return;
    }

    if (!mounted) return;

    final closeDialog = showLoadingDialog(
      context,
      message: '正在生成截图，请稍候...',
    );

    try {
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -vf "select=\'not(mod(t,$intervalSeconds))\'" -vsync vfr "$outputPattern" -y',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('截图已生成（间隔 $intervalMinutes 分钟）：$baseName/'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('截图失败: ${e.toString()}')),
      );
    } finally {
      closeDialog();
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
              ? const EmptyFileList(message: '请将视频文件拖拽到上方区域')
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
