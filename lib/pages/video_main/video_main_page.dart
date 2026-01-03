

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:myapp_flt_02/widgets/loading_dialog.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';
import 'package:myapp_flt_02/utils/ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/yt_dlp_helper.dart';
import 'package:myapp_flt_02/utils/notifications_helper.dart';

/// 视频主页面的简易输入与下载按钮组件
class VideoMainPage extends StatefulWidget {
  /// 初始处理倍速（默认 2.0）
  final double initialSpeed;

  /// 可选的倍速列表（若未提供则使用默认选项）
  final List<double>? speedOptions;

  /// 可选的初始文本
  final String? initialText;

  const VideoMainPage({
    super.key,
    this.initialText,
    this.initialSpeed = 2.0,
    this.speedOptions,
  });

  @override
  State<VideoMainPage> createState() => _VideoMainPageState();
}

class _VideoMainPageState extends State<VideoMainPage> {
  late final TextEditingController _controller;
  late final ValueNotifier<bool> _canSubmit;

  // speed selection
  late List<double> _speedOptions;
  late double _selectedSpeed;

  // batch processing flag
  bool _isWorking = false;

  void _setWorking(bool v) {
    if (!mounted) return;
    setState(() {
      _isWorking = v;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _canSubmit = ValueNotifier<bool>(_controller.text.trim().isNotEmpty);
    _controller.addListener(() {
      _canSubmit.value = _controller.text.trim().isNotEmpty;
    });

    _speedOptions = widget.speedOptions ?? [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0];
    _selectedSpeed = widget.initialSpeed;
    if (!_speedOptions.contains(_selectedSpeed)) {
      _speedOptions = [..._speedOptions, _selectedSpeed];
      _speedOptions.sort();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _canSubmit.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final urls = text
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (urls.isEmpty) return;

    _setWorking(true);

    final closeDialog = showLoadingDialog(
      context,
      message: urls.length == 1
          ? '正在下载音频...'
          : '正在下载 ${urls.length} 个音频，请稍候...',
      barrierDismissible: false,
    );

    try {
      final int total = urls.length;

      for (int i = 0; i < total; i++) {
        final url = urls[i];
        try {
          final downloadedPath = await downloadAudioToDirectory(url);

          if (!mounted) return;

          if (downloadedPath != null) {
              final fileName = path.basename(downloadedPath);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('[$i/${total - 1}] 下载完成：$fileName'),
                  action: SnackBarAction(
                    label: '打开文件夹',
                    onPressed: () => openFileLocation(downloadedPath!),
                  ),
                ),
              );

              // System notification
              try {
                final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
                Notifications.showNotification(
                  id: id,
                  title: '下载完成',
                  body: fileName,
                );
              } catch (_) {}
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('[$i/${total - 1}] 下载完成，但未能确定输出文件路径')),
              );
            }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载失败（$url）：${e.toString()}')),
          );
        }
      }

      // Close loading dialog
      closeDialog();
    } finally {
      _setWorking(false);
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}
    }
  }

  Future<void> _handleDownloadAndProcess() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final urls = text
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (urls.isEmpty) return;

    _setWorking(true);

    final progress = showProgressDialog(
      context,
      initialMessage: urls.length == 1
          ? '正在下载并处理音频...'
          : '正在下载并处理 ${urls.length} 个音频，请稍候...',
      barrierDismissible: false,
    );

    try {
      // Pre-check ffmpeg availability once
      final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
      if (!hasFFmpeg) {
        progress.close();
        _setWorking(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用包含 ffmpeg')),
        );
        return;
      }

      final int total = urls.length;

      for (int i = 0; i < total; i++) {
        final url = urls[i];
        final current = i + 1;

        try {
          progress.update('[$current/$total] 正在下载...');
          final downloadedPath = await downloadAudioToDirectory(url);

          if (downloadedPath == null) {
            progress.update('[$current/$total] 下载完成，但无法定位下载文件进行处理');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('[$current/$total] 下载成功，但无法定位下载文件进行处理')),
            );
            continue;
          }

          progress.update('[$current/$total] 下载完成，开始处理...');

          final inputPath = downloadedPath;
          final dirPath = path.dirname(inputPath);
          final baseName = path.basenameWithoutExtension(inputPath);
          final suffix = _selectedSpeed.toStringAsFixed(1);
          final outputPath = path.join(dirPath, '$baseName-${suffix}x.m4a');

          // Build atempo filter for arbitrary speed
          final aFilter = _buildAtempoFilter(_selectedSpeed);

          // Run ffmpeg to speed up audio
          await FFmpegHelper.runFFmpegShell(
            '-i "$inputPath" -filter:a "$aFilter" -c:a aac "$outputPath"',
          );

          // 如果输出存在，尝试删除原始输入文件，仅在处理成功后删除
          try {
            final outFile = File(outputPath);
            if (await outFile.exists()) {
              try {
                final inputFile = File(inputPath);
                if (await inputFile.exists()) {
                  await inputFile.delete();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已处理 $baseName，但删除原始文件失败：${e.toString()}')),
                );
              }
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('处理完成但找不到输出文件，原始文件保留：$inputPath')),
              );
            }
          } catch (_) {
            // 忽略检查错误
          }

          final outName = path.basename(outputPath);
          progress.update('[$current/$total] 完成：$outName');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('[$current/$total] 下载并处理完成：$outName'),
              action: SnackBarAction(
                label: '打开文件夹',
                onPressed: () => openFileLocation(outputPath),
              ),
            ),
          );

          // System notification
          try {
            final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
            Notifications.showNotification(
              id: id,
              title: '下载并处理完成',
              body: outName,
            );
          } catch (_) {}
        } catch (e) {
          progress.update('[$current/$total] 失败：${e.toString()}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('下载并处理失败（$url）：${e.toString()}')),
          );
        }
      }

      // Close loading dialog
      progress.close();
    } finally {
      _setWorking(false);
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}
    }
  }

  String _buildAtempoFilter(double tempo) {
    if (tempo <= 2.0 && tempo >= 0.5) {
      return 'atempo=$tempo';
    }

    final factors = <double>[];
    double remaining = tempo;
    while (remaining > 2.0) {
      factors.add(2.0);
      remaining = remaining / 2.0;
    }
    if (remaining >= 0.5) {
      factors.add(remaining);
    }

    return factors
        .map((f) => 'atempo=${f.toStringAsFixed(f == f.roundToDouble() ? 0 : 2)}')
        .join(',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频下载&加速'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: ValueListenableBuilder<bool>(
                valueListenable: _canSubmit,
                builder: (context, hasText, child) {
                  return TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: '请输入 url 或文本（最多 3 行）',
                      suffixIcon: hasText
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: '清除',
                              onPressed: _isWorking
                                  ? null
                                  : () {
                                      _controller.clear();
                                      _canSubmit.value = false;
                                    },
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('倍速：'),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _selectedSpeed,
                  items: _speedOptions
                      .map(
                        (s) => DropdownMenuItem<double>(
                          value: s,
                          child: Text('${s.toStringAsFixed(1)}x'),
                        ),
                      )
                      .toList(),
                  onChanged: _isWorking
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedSpeed = v;
                          });
                        },
                ),
                const Spacer(),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _canSubmit,
                  builder: (context, canSubmit, child) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: (! _isWorking && canSubmit) ? _handleDownload : null,
                          child: const Text('下载'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (! _isWorking && canSubmit) ? _handleDownloadAndProcess : null,
                          child: const Text('下载并处理'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}