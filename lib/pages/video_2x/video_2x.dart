import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_processor.dart';
import 'package:myapp_flt_02/utils/video_media_utils.dart';
import 'package:myapp_flt_02/utils/mixins/video_file_drop_mixin.dart';
import 'package:myapp_flt_02/utils/mixins/video_processing_mixin.dart';
import 'package:myapp_flt_02/utils/notification_helper.dart';
import 'package:myapp_flt_02/widgets/video_file_list_section.dart';
import 'package:myapp_flt_02/widgets/video_processing_overlay.dart';
import 'package:myapp_flt_02/widgets/video_speed_dialog.dart';
import 'package:path/path.dart' as path;

class Video2xPage extends StatefulWidget {
  const Video2xPage({super.key});

  @override
  State<Video2xPage> createState() => _Video2xPageState();
}

class _Video2xPageState extends State<Video2xPage>
    with FileDropMixin, ProcessingMixin {
  Future<void> _showFFmpegDiagnosis() async {
    final diagnosis = await FFmpegHelper.diagnose();

    if (!mounted) return;

    final buffer = StringBuffer();
    buffer.writeln('平台: ${diagnosis['platform']}');
    buffer.writeln('');
    buffer.writeln('打包的 ffmpeg: ${diagnosis['bundled_ffmpeg'] ?? '未找到'}');
    buffer.writeln('系统 ffmpeg: ${diagnosis['system_ffmpeg'] ?? '未找到'}');
    buffer.writeln('');

    if (diagnosis['common_paths_checked'] != null) {
      buffer.writeln('检查的路径:');
      for (final check in diagnosis['common_paths_checked']) {
        final p = check['path'];
        final exists = check['exists'] ? '✓' : '✗';
        buffer.writeln('  $exists $p');
      }
      buffer.writeln('');
    }

    buffer.writeln('最终路径: ${diagnosis['final_path'] ?? '未找到'}');
    buffer.writeln('是否可用: ${diagnosis['is_available'] ? '是' : '否'}');

    if (diagnosis['version'] != null) {
      buffer.writeln('');
      buffer.writeln('版本: ${diagnosis['version']}');
    }

    if (diagnosis['error'] != null) {
      buffer.writeln('');
      buffer.writeln('错误: ${diagnosis['error']}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FFmpeg 诊断信息'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _batchProcessAllFiles() async {
    if (files.isEmpty) return;

    final selectedSpeed = await showSliderSelectionDialog(
      context,
      title: '批量处理 - 选择速度倍数',
      message: '将对所有 ${files.length} 个文件应用相同的速度倍数',
      config: speedSliderConfig(),
    );

    if (selectedSpeed == null) return;

    startProcessing('批量处理中...');

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      updateProcessingMessage(
        '正在处理 ${i + 1}/${files.length}: ${path.basename(file.path)}',
      );

      try {
        if (isVideoFile(file.path)) {
          await FFmpegProcessor.processVideoAtTempoSilent(
            file.path,
            selectedSpeed,
          );
          NotificationHelper.showBatchItemComplete(
            fileName: path.basename(file.path),
            current: i + 1,
            total: files.length,
          );
        } else if (isAudioFile(file.path)) {
          await FFmpegProcessor.processAudioAtTempoSilent(
            file.path,
            selectedSpeed,
          );
          NotificationHelper.showBatchItemComplete(
            fileName: path.basename(file.path),
            current: i + 1,
            total: files.length,
          );
        } else {
          continue;
        }
        successCount++;
      } catch (e) {
        NotificationHelper.showBatchItemFailed(
          fileName: path.basename(file.path),
          current: i + 1,
          total: files.length,
        );
        failCount++;
      }
    }

    stopProcessing();

    NotificationHelper.showBatchComplete(
      context,
      successCount: successCount,
      failCount: failCount,
    );
  }

  Future<void> _showSpeedDialog(XFile file, {double defaultSpeed = 2.0}) async {
    final selectedSpeed = await showSliderSelectionDialog(
      context,
      title: '选择速度倍数',
      message: isVideoFile(file.path) ? '请选择视频播放速度倍数' : '请选择音频播放速度倍数',
      config: speedSliderConfig(initialValue: defaultSpeed),
    );

    if (selectedSpeed == null) return;

    if (isVideoFile(file.path)) {
      await _processVideoAtTempo(file, selectedSpeed);
    } else {
      await _processAudioAtTempo(file, selectedSpeed);
    }
  }

  Future<void> _processAudioAtTempo(XFile file, double tempo) async {
    startProcessing('正在生成 ${tempo.toStringAsFixed(1)}x 音频...');

    await FFmpegProcessor.processAudioAtTempo(
      file.path,
      tempo,
      onSuccess: (outputPath) {
        stopProcessing();
        NotificationHelper.showSuccess(
          context,
          message: '生成成功：${path.basename(outputPath)}',
          filePath: outputPath,
        );
      },
      onError: (error) {
        stopProcessing();
        NotificationHelper.showError(context, message: '处理失败', error: error);
      },
    );
  }

  Future<void> _processVideoAtTempo(XFile file, double tempo) async {
    startProcessing('正在生成 ${tempo.toStringAsFixed(1)}x 视频...');

    await FFmpegProcessor.processVideoAtTempo(
      file.path,
      tempo,
      onSuccess: (outputPath) {
        stopProcessing();
        NotificationHelper.showSuccess(
          context,
          message: '生成成功：${path.basename(outputPath)}',
          filePath: outputPath,
        );
      },
      onError: (error) {
        stopProcessing();
        NotificationHelper.showError(context, message: '处理失败', error: error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('音视频 2x'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'FFmpeg 诊断信息',
            onPressed: _showFFmpegDiagnosis,
          ),
          if (hasFiles)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清空所有文件',
              onPressed: clearFiles,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              VideoDropZone(
                isDragging: isDragging,
                onDragEntered: onDragEntered,
                onDragExited: onDragExited,
                onDragDone: onDragDone,
              ),
              FileListSection(
                files: files,
                onRemoveFile: removeFile,
                emptyMessage: '拖拽音视频文件到上方区域',
                headerBuilder: (context) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已添加 $fileCount 个文件',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isProcessing ? null : _batchProcessAllFiles,
                        icon: const Icon(Icons.playlist_play, size: 20),
                        label: const Text('批量处理'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailingBuilder: (file) => _buildFileActions(file),
              ),
            ],
          ),
          if (isProcessing)
            ProcessingOverlay(message: processingMessage ?? '处理中...'),
        ],
      ),
    );
  }

  Widget _buildFileActions(XFile file) {
    final isAudio = isAudioFile(file.path);
    final isVideo = isVideoFile(file.path);

    if (!isAudio && !isVideo) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.speed),
          tooltip: '2x',
          onPressed: () => _showSpeedDialog(file, defaultSpeed: 2.0),
        ),
        IconButton(
          icon: const Icon(Icons.fast_forward),
          tooltip: '自定义速度',
          onPressed: () => _showSpeedDialog(file),
        ),
      ],
    );
  }
}
