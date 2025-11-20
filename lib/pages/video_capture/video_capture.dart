import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:myapp_flt_02/pages/video_merge/drop_zone_widget.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:path/path.dart' as path;

class VideoCaptureWidget extends StatefulWidget {
  const VideoCaptureWidget({super.key});

  @override
  State<VideoCaptureWidget> createState() => _VideoCaptureWidgetState();
}

class _VideoCaptureWidgetState extends State<VideoCaptureWidget> {
  final List<XFile> _files = <XFile>[];
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
    final List<XFile> videoFiles = <XFile>[];
    int ignoredCount = 0;

    for (final XFile file in details.files) {
      if (isVideoFile(file.path)) {
        videoFiles.add(file);
      } else {
        ignoredCount += 1;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isDragging = false;
      _files.addAll(videoFiles);
    });

    if (ignoredCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已忽略 $ignoredCount 个非视频文件'),
        ),
      );
    }
  }

  Future<int?> _showCaptureIntervalDialog() async {
    double selectedMinutes = 5;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: const Text('选择截图间隔'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      '设置每隔多少分钟截取一帧画面',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '${selectedMinutes.toStringAsFixed(0)} 分钟',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: selectedMinutes,
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: '${selectedMinutes.toStringAsFixed(0)} 分钟',
                      onChanged: (double value) {
                        setState(() {
                          selectedMinutes = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          '2 分钟',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '10 分钟',
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
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '范围：2 分钟 - 10 分钟，步长 1 分钟',
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
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(selectedMinutes.toInt()),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _captureScreenshot(XFile file) async {
    final int? intervalMinutes = await _showCaptureIntervalDialog();
    if (intervalMinutes == null) {
      return;
    }

    final int intervalSeconds = intervalMinutes * 60;

    final String inputPath = file.path;
    final String dir = path.dirname(inputPath);
    final String baseName = path.basenameWithoutExtension(inputPath);
    final String outputDir = path.join(dir, baseName);
    // ffmpeg image2 pattern requires %d / %0Nd, cannot use %s
    final String outputPattern = path.join(outputDir, '${baseName}@%04d_frame.jpg');

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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _CaptureLoadingDialog();
      },
    );

    try {
      await FFmpegHelper.runFFmpegShell(
        '-i "$inputPath" -vf "select=\'not(mod(t,$intervalSeconds))\'" -vsync vfr "$outputPattern" -y',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '截图已生成（间隔 $intervalMinutes 分钟）：$baseName/',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('截图失败: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        VideoDropZone(
          isDragging: _isDragging,
          onDragEntered: _onDragEntered,
          onDragExited: _onDragExited,
          onDragDone: _onDragDone,
        ),
        Expanded(
          child: _files.isEmpty
              ? const Center(
                  child: Text('请将视频文件拖拽到上方区域'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _files.length,
                  itemBuilder: (BuildContext context, int index) {
                    final XFile file = _files[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.video_file,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          _getFileName(file.path),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          file.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: TextButton.icon(
                          onPressed: () => _captureScreenshot(file),
                          icon: const Icon(Icons.image_outlined, size: 20),
                          label: const Text('截图'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }
}

class _CaptureLoadingDialog extends StatelessWidget {
  const _CaptureLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LoadingAnimationWidget.staggeredDotsWave(
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '正在生成截图，请稍候...',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
