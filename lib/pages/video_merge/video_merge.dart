import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_processor.dart';
import 'package:myapp_flt_02/utils/file_paths.dart';
import 'package:myapp_flt_02/utils/mixins/video_file_drop_mixin.dart';
import 'package:myapp_flt_02/utils/notification_helper.dart';
import 'package:myapp_flt_02/widgets/video_file_list_section.dart';
import 'package:myapp_flt_02/widgets/video_loading_dialog.dart';
import 'package:path/path.dart' as path;

class VideoMergePage extends StatefulWidget {
  const VideoMergePage({super.key});

  @override
  State<VideoMergePage> createState() => _VideoMergePageState();
}

class _VideoMergePageState extends State<VideoMergePage> with FileDropMixin {
  bool _isMergeableFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return [
      'mp4',
      'm4a',
      'm4s',
      'avi',
      'mov',
      'mkv',
      'flv',
      'wmv',
      'm3u8',
      'ts',
    ].contains(extension);
  }

  Future<void> _mergeVideos() async {
    if (files.isEmpty) return;

    final videoFiles = files
        .where((file) => _isMergeableFile(file.path))
        .toList();

    if (videoFiles.isEmpty) {
      NotificationHelper.showNoValidFiles(context, message: '没有找到视频文件');
      return;
    }

    if (videoFiles.length < 2) {
      NotificationHelper.showNeedMoreFiles(
        context,
        minCount: 2,
        fileType: '视频',
      );
      return;
    }

    final firstVideoFileName = path.basenameWithoutExtension(
      videoFiles[0].path,
    );
    final defaultOutputFileName = '$firstVideoFileName-merged.mp4';
    final outputFilePath = await generateUniqueOutputFilePath(
      defaultOutputFileName,
    );

    if (!mounted) return;
    if (!await FFmpegHelper.isFFmpegAvailable()) {
      NotificationHelper.showError(context, message: '未检测到 ffmpeg，请先安装 ffmpeg');
      return;
    }

    final closeDialog = showLoadingDialog(
      context,
      message: '正在合并视频...',
      useSimpleIndicator: true,
    );

    try {
      await FFmpegProcessor.mergeVideos(
        videoFiles.map((f) => f.path).toList(),
        outputFilePath,
      );

      if (!mounted) return;
      closeDialog();

      NotificationHelper.showSuccess(
        context,
        message: '合并成功！输出文件：${path.basename(outputFilePath)}',
        filePath: outputFilePath,
      );
    } catch (e) {
      if (!mounted) return;
      closeDialog();
      NotificationHelper.showError(context, message: '合并失败', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('视频合并'),
      ),
      body: Column(
        children: [
          VideoDropZone(
            isDragging: isDragging,
            onDragEntered: onDragEntered,
            onDragExited: onDragExited,
            onDragDone: onDragDone,
          ),
          if (hasFiles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _mergeVideos,
                    icon: const Icon(Icons.video_library),
                    label: const Text('合并视频'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: hasFiles ? clearFiles : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('清空'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          FileListSection(
            files: files,
            onRemoveFile: removeFile,
            emptyMessage: '拖拽视频文件到上方区域',
          ),
        ],
      ),
    );
  }
}
