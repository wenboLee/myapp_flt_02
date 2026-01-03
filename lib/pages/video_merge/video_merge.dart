import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:myapp_flt_02/utils/mixins/file_drop_mixin.dart';
import 'package:myapp_flt_02/widgets/empty_file_list.dart';
import 'package:myapp_flt_02/widgets/file_list_item.dart';
import 'package:myapp_flt_02/widgets/loading_dialog.dart';
import 'package:path/path.dart' as path;

class VideoMergePage extends StatefulWidget {
  const VideoMergePage({super.key});

  @override
  State<VideoMergePage> createState() => _VideoMergePageState();
}

class _VideoMergePageState extends State<VideoMergePage> with FileDropMixin {
  /// Check if file is a mergeable video/audio file.
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
    if (files.isEmpty) {
      return;
    }

    // Filter video files
    final videoFiles =
        files.where((file) => _isMergeableFile(file.path)).toList();

    if (videoFiles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有找到视频文件'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (videoFiles.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请添加至少2个视频文件（如 video.m3u8 和 audio.m3u8）'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Generate default output filename
    final firstVideoFileName = path.basenameWithoutExtension(
      videoFiles[0].path,
    );
    final defaultOutputFileName = '$firstVideoFileName-merged.mp4';

    // Select output file path: save directly to user's Downloads directory with a unique filename
    Future<String> _getDownloadsDirectory() async {
      String dir;
      if (Platform.isWindows) {
        dir = path.join(Platform.environment['USERPROFILE'] ?? '', 'Downloads');
      } else {
        dir = path.join(Platform.environment['HOME'] ?? '', 'Downloads');
      }
      if (dir.isEmpty) {
        dir = Directory.current.path;
      }
      return dir;
    }

    Future<String> _generateUniqueOutputFilePath(String filename) async {
      final dir = await _getDownloadsDirectory();
      String candidate = path.join(dir, filename);
      final base = path.basenameWithoutExtension(filename);
      final ext = path.extension(filename);
      int i = 1;
      while (await File(candidate).exists()) {
        candidate = path.join(dir, '${base}_$i$ext');
        i++;
      }
      return candidate;
    }

    final String outputFilePath = await _generateUniqueOutputFilePath(defaultOutputFileName);

    // Check ffmpeg availability
    if (!mounted) return;
    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未检测到 ffmpeg，请先安装 ffmpeg'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show merging dialog
    if (!mounted) return;
    final closeDialog = showLoadingDialog(
      context,
      message: '正在合并视频...',
      useSimpleIndicator: true,
    );

    try {
      // Execute ffmpeg command
      final inputFile1 = videoFiles[0].path;
      final inputFile2 = videoFiles[1].path;

      await FFmpegHelper.runFFmpegShell(
        '-i "$inputFile1" -i "$inputFile2" -c copy "$outputFilePath"',
      );

      if (!mounted) return;
      closeDialog();

      final fileName = path.basename(outputFilePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('合并成功！输出文件：$fileName'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => openFileLocation(outputFilePath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      closeDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('合并失败：${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
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
          if (hasFiles) _buildActionBar(),
          _buildFileList(),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _mergeVideos,
            icon: const Icon(Icons.video_library),
            label: const Text('合并视频'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: hasFiles ? clearFiles : null,
            icon: const Icon(Icons.delete),
            label: const Text('清空'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (!hasFiles) {
      return const Expanded(child: EmptyFileList());
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              '已添加 $fileCount 个文件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: fileCount,
              itemBuilder: (context, index) {
                return FileListItem(
                  file: files[index],
                  onRemove: () => removeFile(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
