import 'package:flutter/material.dart';
import 'package:myapp_flt_02/utils/notifications_helper.dart';
import 'package:myapp_flt_02/utils/video_media_utils.dart';
import 'package:path/path.dart' as path;
import 'package:myapp_flt_02/utils/video_ffmpeg_helper.dart';
import 'package:myapp_flt_02/utils/video_ffmpeg_processor.dart';
import 'package:myapp_flt_02/utils/notification_helper.dart';
import 'package:myapp_flt_02/utils/video_download_helper.dart';
import 'package:myapp_flt_02/utils/video_ytdlp_helper.dart';
import 'package:myapp_flt_02/widgets/video_loading_dialog.dart';

/// 视频主页面的简易输入与下载按钮组件
class VideoMainPage extends StatefulWidget {
  /// 初始处理倍速（默认 2.0）
  final double initialSpeed;

  /// 可选的倍速列表（若未提供则使用默认选项）
  final List<double>? speedOptions;

  /// 可选的初始文本
  final String? initialText;

  const VideoMainPage({super.key, this.initialText, this.initialSpeed = 1.8, this.speedOptions});

  @override
  State<VideoMainPage> createState() => _VideoMainPageState();
}

class _VideoMainPageState extends State<VideoMainPage> {
  late final TextEditingController _controller;
  late final ValueNotifier<bool> _canSubmit;

  late List<double> _speedOptions;
  late double _selectedSpeed;
  bool _isWorking = false;

  void _setWorking(bool v) {
    if (!mounted) return;
    setState(() => _isWorking = v);

    if (!mounted) return;
    setState(() => _isWorking = v);
  }

  Future<void> _showYtDlpDiagnosis() async {
    final diagnosis = await YtDlpHelper.diagnose();

    if (!mounted) return;

    final buffer = StringBuffer();
    buffer.writeln('平台: ${diagnosis['platform']}');
    buffer.writeln('');
    buffer.writeln('系统 yt-dlp: ${diagnosis['system_yt_dlp'] ?? '未找到'}');
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
        title: const Text('yt-dlp 诊断信息'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(buffer.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭'))],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _canSubmit = ValueNotifier<bool>(_controller.text.trim().isNotEmpty);
    _controller.addListener(() => _canSubmit.value = _controller.text.trim().isNotEmpty);

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

  List<String> _parseUrls(String text) =>
      text.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _handleDownload() async {
    final urls = _parseUrls(_controller.text.trim());
    if (urls.isEmpty) return;

    _setWorking(true);
    final closeDialog = showLoadingDialog(
      context,
      message: urls.length == 1 ? '正在下载音频...' : '正在下载 ${urls.length} 个音频，请稍候...',
      barrierDismissible: false,
    );

    try {
      for (int i = 0; i < urls.length; i++) {
        final url = urls[i];
        try {
          final downloadedPath = await downloadAudioToDirectory(url);
          if (downloadedPath != null) {
            NotificationHelper.showDownloadComplete(
              context,
              fileName: path.basename(downloadedPath),
              filePath: downloadedPath,
              current: i + 1,
              total: urls.length,
            );
          } else {
            NotificationHelper.showError(context, message: '[$i/${urls.length - 1}] 下载完成，但未能确定输出文件路径');
          }
        } catch (e) {
          NotificationHelper.showDownloadFailed(context, url: url, error: e, current: i + 1, total: urls.length);
        }
      }
      closeDialog();
    } finally {
      _setWorking(false);
    }
  }

  Future<void> _handleDownloadVideo() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final urls = text.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (urls.isEmpty) return;

    _setWorking(true);

    final progress = showProgressDialog(
      context,
      initialMessage: urls.length == 1 ? '正在下载视频...' : '正在下载 ${urls.length} 个视频，请稍候...',
      barrierDismissible: false,
    );

    try {
      final int total = urls.length;

      for (int i = 0; i < total; i++) {
        final url = urls[i];
        final current = i + 1;

        try {
          progress.update('[$current/$total] 正在下载视频...');
          final downloadedPath = await downloadVideoToDirectory(url);

          if (!mounted) return;

          if (downloadedPath != null) {
            final fileName = path.basename(downloadedPath);
            progress.update('[$current/$total] 完成：$fileName');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('[$current/$total] 视频下载完成：$fileName'),
                action: SnackBarAction(label: '打开文件夹', onPressed: () => openFileLocation(downloadedPath)),
              ),
            );

            // System notification
            try {
              final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
              Notifications.showNotification(id: id, title: '视频下载完成', body: fileName);
            } catch (_) {}
          } else {
            progress.update('[$current/$total] 下载完成，但未能确定输出文件路径');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('[$current/$total] 视频下载完成，但未能确定输出文件路径')));
          }
        } catch (e) {
          progress.update('[$current/$total] 失败：${e.toString()}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('视频下载失败（$url）：${e.toString()}')));
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

  Future<void> _handleDownloadAndProcess() async {
    final urls = _parseUrls(_controller.text.trim());
    if (urls.isEmpty) return;

    _setWorking(true);
    final progress = showProgressDialog(
      context,
      initialMessage: urls.length == 1 ? '正在下载并处理音频...' : '正在下载并处理 ${urls.length} 个音频，请稍候...',
      barrierDismissible: false,
    );

    try {
      if (!await FFmpegHelper.isFFmpegAvailable()) {
        progress.close();
        _setWorking(false);
        NotificationHelper.showError(context, message: '未检测到 ffmpeg，请先安装 ffmpeg 或确保应用包含 ffmpeg');
        return;
      }

      for (int i = 0; i < urls.length; i++) {
        final current = i + 1;
        try {
          progress.update('[$current/${urls.length}] 正在下载...');
          final downloadedPath = await downloadAudioToDirectory(urls[i]);
          if (downloadedPath == null) {
            NotificationHelper.showError(context, message: '[$current/${urls.length}] 下载成功，但无法定位下载文件进行处理');
            continue;
          }
          progress.update('[$current/${urls.length}] 下载完成，开始处理...');
          final outputPath = await FFmpegProcessor.processDownloadedAudio(downloadedPath, _selectedSpeed);
          if (outputPath != null) {
            try {
              await FFmpegProcessor.deleteSourceIfOutputExists(downloadedPath, outputPath);
            } catch (e) {
              NotificationHelper.showError(
                context,
                message: '已处理 ${path.basenameWithoutExtension(downloadedPath)}，但删除原始文件失败',
                error: e,
              );
            }
            progress.update('[$current/${urls.length}] 完成：${path.basename(outputPath)}');
            NotificationHelper.showDownloadAndProcessComplete(
              context,
              fileName: path.basename(outputPath),
              filePath: outputPath,
              current: current,
              total: urls.length,
            );
          }
        } catch (e) {
          progress.update('[$current/${urls.length}] 失败：${e.toString()}');
          NotificationHelper.showDownloadFailed(context, url: urls[i], error: e, current: current, total: urls.length);
        }
      }
      progress.close();
    } finally {
      _setWorking(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频下载&加速'),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), tooltip: 'yt-dlp 诊断信息', onPressed: _showYtDlpDiagnosis),
        ],
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
                builder: (context, hasText, child) => TextField(
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
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('倍速：'),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _selectedSpeed,
                  items: _speedOptions
                      .map((s) => DropdownMenuItem<double>(value: s, child: Text('${s.toStringAsFixed(1)}x')))
                      .toList(),
                  onChanged: _isWorking
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedSpeed = v);
                        },
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _canSubmit,
                  builder: (context, canSubmit, child) => Row(
                    children: [
                      ElevatedButton(
                        onPressed: (!_isWorking && canSubmit) ? _handleDownload : null,
                        child: const Text('下载'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (!_isWorking && canSubmit) ? _handleDownloadAndProcess : null,
                        child: const Text('下载并处理'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (!_isWorking && canSubmit) ? _handleDownloadVideo : null,
                        child: const Text('下载视频'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
