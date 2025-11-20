import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:path/path.dart' as path;

class Video2xPage extends StatefulWidget {
  const Video2xPage({super.key});

  @override
  State<Video2xPage> createState() => _Video2xPageState();
}

class _Video2xPageState extends State<Video2xPage> {
  final List<XFile> _files = [];

  bool _isDragging = false;

  void _onDragEntered() {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragExited() {
    setState(() {
      _isDragging = false;
    });
  }

  void _onDragDone(DropDoneDetails details) {
    setState(() {
      _isDragging = false;
      _files.addAll(details.files);
    });
  }

  void _clearFiles() {
    setState(() {
      _files.clear();
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  bool _isAudioFile(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'm4a', 'aac', 'flac'].contains(ext);
  }

  // 通用 processing 状态
  bool _isProcessing = false;
  String? _processingMessage;

  void _startProcessing(String message) {
    setState(() {
      _isProcessing = true;
      _processingMessage = message;
    });
  }

  void _stopProcessing() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _processingMessage = null;
      });
    }
  }

  Future<bool> _checkFFmpegInstalled() async {
    return await FFmpegHelper.isFFmpegAvailable();
  }

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
        final path = check['path'];
        final exists = check['exists'] ? '✓' : '✗';
        buffer.writeln('  $exists $path');
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

  void _openFileLocation(String filePath) {
    final directory = path.dirname(filePath);

    try {
      if (Platform.isWindows) {
        Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [directory]);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _batchProcessAllFiles() async {
    if (_files.isEmpty) return;

    final selectedSpeed = await _showSpeedSelectionDialog(
      title: '批量处理 - 选择速度倍数',
      message: '将对所有 ${_files.length} 个文件应用相同的速度倍数',
    );

    if (selectedSpeed == null) return;

    _startProcessing('批量处理中...');

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _files.length; i++) {
      final file = _files[i];
      
      setState(() {
        _processingMessage = '正在处理 ${i + 1}/${_files.length}: ${path.basename(file.path)}';
      });

      try {
        if (isVideoFile(file.path)) {
          await _processVideoAtTempoSilent(file, selectedSpeed);
        } else if (_isAudioFile(file.path)) {
          await _processAudioAtTempoSilent(file, selectedSpeed);
        } else {
          continue;
        }
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    _stopProcessing();

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('批处理完成：成功 $successCount 个，失败 $failCount 个'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<double?> _showSpeedSelectionDialog({
    required String title,
    required String message,
  }) async {
    double selectedSpeed = 2.0;
    
    return await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${selectedSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: selectedSpeed,
                      min: 1.5,
                      max: 5.0,
                      divisions: 35,
                      label: '${selectedSpeed.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() {
                          selectedSpeed = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1.5x',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '5.0x',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '倍速范围：1.5x - 5.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedSpeed),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSpeedDialog(XFile file) async {
    final selectedSpeed = await _showSpeedSelectionDialog(
      title: '选择速度倍数',
      message: isVideoFile(file.path)
          ? '请选择视频播放速度倍数'
          : '请选择音频播放速度倍数',
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

    final hasFFmpeg = await _checkFFmpegInstalled();
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

    final hasFFmpeg = await _checkFFmpegInstalled();
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

    // check ffmpeg
    final hasFFmpeg = await _checkFFmpegInstalled();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg')));
      return;
    }

    if (!mounted) return;
    _startProcessing('正在生成 $suffix 音频...');

    try {
      final filter = _buildAtempoFilter(tempo);
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -filter:a "$filter" -c:a aac "$outputPath"',
      );

      if (!mounted) return;
      _stopProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成成功：${path.basename(outputPath)}'),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => _openFileLocation(outputPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _stopProcessing();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('处理失败：${e.toString()}')));
    }
  }

  Future<void> _processVideoAtTempo(XFile file, double tempo) async {
    final inputPath = file.path;
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final ext = path.extension(inputPath);
    final suffix = '${tempo.toStringAsFixed(1)}x';
    final outputPath = path.join(dir, '$baseName-$suffix$ext');

    // check ffmpeg
    final hasFFmpeg = await _checkFFmpegInstalled();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg')));
      return;
    }

    if (!mounted) return;
    _startProcessing('正在生成 $suffix 视频...');

    try {
      final aFilter = _buildAtempoFilter(tempo);
      final vFactor = (1.0 / tempo).toStringAsFixed(6);
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -filter:v "setpts=${vFactor}*PTS" -filter:a "$aFilter" "$outputPath"',
      );

      if (!mounted) return;
      _stopProcessing();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成成功：${path.basename(outputPath)}'),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => _openFileLocation(outputPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _stopProcessing();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('处理失败：${e.toString()}')));
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
          if (_files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清空所有文件',
              onPressed: _clearFiles,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              VideoDropZone(
                isDragging: _isDragging,
                onDragEntered: _onDragEntered,
                onDragExited: _onDragExited,
                onDragDone: _onDragDone,
              ),
              _buildFileList(),
            ],
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _processingMessage ?? '处理中...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '暂无文件',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
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
                  '已添加 ${_files.length} 个文件',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _batchProcessAllFiles(),
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
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final fileName = _getFileName(file.path);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getFileIcon(fileName),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      file.path,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isAudioFile(file.path)) ...[
                          IconButton(
                            icon: const Icon(Icons.speed),
                            tooltip: '2x',
                            onPressed: () => _processAudioAtTempo(file, 2.0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.fast_forward),
                            tooltip: '自定义速度',
                            onPressed: () => _showSpeedDialog(file),
                          ),
                        ],
                        if (isVideoFile(file.path)) ...[
                          IconButton(
                            icon: const Icon(Icons.speed),
                            tooltip: '2x',
                            onPressed: () => _processVideoAtTempo(file, 2.0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.fast_forward),
                            tooltip: '自定义速度',
                            onPressed: () => _showSpeedDialog(file),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeFile(index),
                          tooltip: '移除',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
