import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:myapp_flt_02/utils/mixins/file_drop_mixin.dart';
import 'package:myapp_flt_02/utils/mixins/processing_mixin.dart';
import 'package:myapp_flt_02/widgets/empty_file_list.dart';
import 'package:myapp_flt_02/widgets/file_list_item.dart';
import 'package:myapp_flt_02/widgets/processing_overlay.dart';
import 'package:myapp_flt_02/widgets/slider_selection_dialog.dart';
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
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
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
          await _processVideoAtTempoSilent(file, selectedSpeed);
        } else if (isAudioFile(file.path)) {
          await _processAudioAtTempoSilent(file, selectedSpeed);
        } else {
          continue;
        }
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    stopProcessing();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('批处理完成：成功 $successCount 个，失败 $failCount 个'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showSpeedDialog(XFile file) async {
    final selectedSpeed = await showSliderSelectionDialog(
      context,
      title: '选择速度倍数',
      message: isVideoFile(file.path) ? '请选择视频播放速度倍数' : '请选择音频播放速度倍数',
      config: speedSliderConfig(),
    );

    if (selectedSpeed == null) return;

    if (isVideoFile(file.path)) {
      await _processVideoAtTempo(file, selectedSpeed);
    } else {
      await _processAudioAtTempo(file, selectedSpeed);
    }
  }

  Future<void> _processAudioAtTempoSilent(XFile file, double tempo) async {
    final inputPath = file.path;
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final suffix = '${tempo.toStringAsFixed(1)}x';
    final outputPath = path.join(dir, '$baseName-$suffix.m4a');

    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      throw Exception('未检测到 ffmpeg');
    }

    final filter = _buildAtempoFilter(tempo);
    await FFmpegHelper.runFFmpegShell(
      '-i "$inputPath" -filter:a "$filter" -c:a aac "$outputPath"',
    );
  }

  Future<void> _processVideoAtTempoSilent(XFile file, double tempo) async {
    final inputPath = file.path;
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final ext = path.extension(inputPath);
    final suffix = '${tempo.toStringAsFixed(1)}x';
    final outputPath = path.join(dir, '$baseName-$suffix$ext');

    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      throw Exception('未检测到 ffmpeg');
    }

    final aFilter = _buildAtempoFilter(tempo);
    final vFactor = (1.0 / tempo).toStringAsFixed(6);
    await FFmpegHelper.runFFmpegShell(
      '-i "$inputPath" -filter:v "setpts=${vFactor}*PTS" -filter:a "$aFilter" "$outputPath"',
    );
  }

  String _buildAtempoFilter(double tempo) {
    // atempo accepts values in [0.5, 2.0]. For tempo > 2.0 we chain filters.
    if (tempo <= 2.0 && tempo >= 0.5) {
      return 'atempo=$tempo';
    }

    // For >2.0, split into factors <=2.0 (greedy)
    final factors = <double>[];
    double remaining = tempo;
    while (remaining > 2.0) {
      factors.add(2.0);
      remaining = remaining / 2.0;
    }
    // remaining now <=2.0
    if (remaining >= 0.5) {
      factors.add(remaining);
    }

    return factors
        .map(
          (f) =>
              'atempo=${f.toStringAsFixed(f == (f).roundToDouble() ? 0 : 2)}',
        )
        .join(',');
  }

  Future<void> _processAudioAtTempo(XFile file, double tempo) async {
    final inputPath = file.path;
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final suffix = '${tempo.toStringAsFixed(1)}x';
    final outputPath = path.join(dir, '$baseName-$suffix.m4a');

    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg')),
      );
      return;
    }

    if (!mounted) return;
    startProcessing('正在生成 $suffix 音频...');

    try {
      final filter = _buildAtempoFilter(tempo);
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -filter:a "$filter" -c:a aac "$outputPath"',
      );

      if (!mounted) return;
      stopProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成成功：${path.basename(outputPath)}'),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => openFileLocation(outputPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      stopProcessing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('处理失败：${e.toString()}')),
      );
    }
  }

  Future<void> _processVideoAtTempo(XFile file, double tempo) async {
    final inputPath = file.path;
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final ext = path.extension(inputPath);
    final suffix = '${tempo.toStringAsFixed(1)}x';
    final outputPath = path.join(dir, '$baseName-$suffix$ext');

    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg')),
      );
      return;
    }

    if (!mounted) return;
    startProcessing('正在生成 $suffix 视频...');

    try {
      final aFilter = _buildAtempoFilter(tempo);
      final vFactor = (1.0 / tempo).toStringAsFixed(6);
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -filter:v "setpts=${vFactor}*PTS" -filter:a "$aFilter" "$outputPath"',
      );

      if (!mounted) return;
      stopProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成成功：${path.basename(outputPath)}'),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => openFileLocation(outputPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      stopProcessing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('处理失败：${e.toString()}')),
      );
    }
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
              _buildFileList(),
            ],
          ),
          if (isProcessing)
            ProcessingOverlay(message: processingMessage ?? '处理中...'),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: fileCount,
              itemBuilder: (context, index) {
                final file = files[index];
                return FileListItem(
                  file: file,
                  onRemove: () => removeFile(index),
                  trailing: _buildFileActions(file),
                );
              },
            ),
          ),
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
          onPressed: () => isVideo
              ? _processVideoAtTempo(file, 2.0)
              : _processAudioAtTempo(file, 2.0),
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
