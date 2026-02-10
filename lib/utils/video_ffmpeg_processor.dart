import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:myapp_flt_02/utils/video_ffmpeg_helper.dart';

/// FFmpeg 音频/视频处理器
///
/// 封装所有与 FFmpeg 相关的音频和视频处理逻辑，包括：
/// - 音频变速处理
/// - 视频变速处理
/// - 视频合并
/// - 视频截图
/// - 速度滤镜生成
class FFmpegProcessor {
  /// 私有构造函数，防止实例化
  FFmpegProcessor._();

  /// 构建 atempo 滤镜字符串
  ///
  /// atempo 滤镜接受 [0.5, 2.0] 范围内的值。
  /// 对于大于 2.0 的倍速，需要链式组合多个滤镜。
  ///
  /// [tempo] 目标倍速值
  static String buildAtempoFilter(double tempo) {
    // atempo accepts values in [0.5, 2.0]
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
    if (remaining >= 0.5) {
      factors.add(remaining);
    }

    return factors
        .map(
          (f) => 'atempo=${f.toStringAsFixed(f == f.roundToDouble() ? 0 : 2)}',
        )
        .join(',');
  }

  /// 检查 FFmpeg 是否可用
  ///
  /// 如果不可用，抛出异常
  static Future<void> ensureFFmpegAvailable() async {
    final hasFFmpeg = await FFmpegHelper.isFFmpegAvailable();
    if (!hasFFmpeg) {
      throw Exception('未检测到 ffmpeg，请先安装 ffmpeg 或确保应用已打包 ffmpeg');
    }
  }

  /// 生成变速音频输出文件路径
  static String _generateAudioOutputPath(String inputPath, double tempo) {
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final suffix = tempo.toStringAsFixed(1);
    return path.join(dir, '$baseName-${suffix}x.m4a');
  }

  /// 生成变速视频输出文件路径
  static String _generateVideoOutputPath(String inputPath, double tempo) {
    final dir = path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final ext = path.extension(inputPath);
    final suffix = tempo.toStringAsFixed(1);
    return path.join(dir, '$baseName-${suffix}x$ext');
  }

  /// 处理音频变速（静默模式 - 无 UI 反馈）
  ///
  /// [inputPath] 输入音频文件路径
  /// [tempo] 目标倍速
  ///
  /// 返回输出文件路径
  static Future<String> processAudioAtTempoSilent(
    String inputPath,
    double tempo,
  ) async {
    await ensureFFmpegAvailable();

    final outputPath = _generateAudioOutputPath(inputPath, tempo);
    final filter = buildAtempoFilter(tempo);

    await FFmpegHelper.runFFmpegShell(
      '-i "$inputPath" -filter:a "$filter" -c:a aac "$outputPath"',
    );

    return outputPath;
  }

  /// 处理视频变速（静默模式 - 无 UI 反馈）
  ///
  /// [inputPath] 输入视频文件路径
  /// [tempo] 目标倍速
  ///
  /// 返回输出文件路径
  static Future<String> processVideoAtTempoSilent(
    String inputPath,
    double tempo,
  ) async {
    await ensureFFmpegAvailable();

    final outputPath = _generateVideoOutputPath(inputPath, tempo);
    final aFilter = buildAtempoFilter(tempo);
    final vFactor = (1.0 / tempo).toStringAsFixed(6);

    await FFmpegHelper.runFFmpegShell(
      '-i "$inputPath" -filter:v "setpts=${vFactor}*PTS" -filter:a "$aFilter" "$outputPath"',
    );

    return outputPath;
  }

  /// 处理音频变速（完整模式）
  ///
  /// [inputPath] 输入音频文件路径
  /// [tempo] 目标倍速
  /// [onSuccess] 成功回调，接收输出路径
  /// [onError] 错误回调，接收错误信息
  static Future<void> processAudioAtTempo(
    String inputPath,
    double tempo, {
    required Function(String outputPath) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      await ensureFFmpegAvailable();
      final outputPath = await processAudioAtTempoSilent(inputPath, tempo);
      onSuccess(outputPath);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// 处理视频变速（完整模式）
  ///
  /// [inputPath] 输入视频文件路径
  /// [tempo] 目标倍速
  /// [onSuccess] 成功回调，接收输出路径
  /// [onError] 错误回调，接收错误信息
  static Future<void> processVideoAtTempo(
    String inputPath,
    double tempo, {
    required Function(String outputPath) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      await ensureFFmpegAvailable();
      final outputPath = await processVideoAtTempoSilent(inputPath, tempo);
      onSuccess(outputPath);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// 合并视频文件
  ///
  /// [inputPaths] 输入视频文件路径列表（至少2个）
  /// [outputPath] 输出文件路径
  static Future<void> mergeVideos(
    List<String> inputPaths,
    String outputPath,
  ) async {
    if (inputPaths.length < 2) {
      throw Exception('至少需要2个视频文件进行合并');
    }

    await ensureFFmpegAvailable();

    final inputFile1 = inputPaths[0];
    final inputFile2 = inputPaths[1];

    await FFmpegHelper.runFFmpegShell(
      '-i "$inputFile1" -i "$inputFile2" -c copy "$outputPath"',
    );
  }

  /// 截取视频截图
  ///
  /// [inputPath] 输入视频文件路径
  /// [intervalSeconds] 截图间隔（秒）
  /// [outputDir] 输出目录，默认为视频所在目录
  ///
  /// 返回截图输出目录路径
  static Future<String> captureScreenshots(
    String inputPath,
    int intervalSeconds, {
    String? outputDir,
  }) async {
    await ensureFFmpegAvailable();

    final dir = outputDir ?? path.dirname(inputPath);
    final baseName = path.basenameWithoutExtension(inputPath);
    final targetDir = path.join(dir, baseName);
    final outputPattern = path.join(targetDir, '${baseName}@%04d_frame.jpg');

    // 确保输出目录存在
    final Directory folder = Directory(targetDir);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    await FFmpegHelper.runFFmpegShell(
      '-i "$inputPath" -vf "select=\'not(mod(t,$intervalSeconds))\'" -vsync vfr "$outputPattern" -y',
    );

    return targetDir;
  }

  /// 下载并处理音频
  ///
  /// [downloadedPath] 已下载的音频文件路径
  /// [tempo] 目标倍速
  ///
  /// 返回处理后的输出路径，如果处理失败返回 null
  static Future<String?> processDownloadedAudio(
    String downloadedPath,
    double tempo,
  ) async {
    await ensureFFmpegAvailable();

    final dir = path.dirname(downloadedPath);
    final baseName = path.basenameWithoutExtension(downloadedPath);
    final suffix = tempo.toStringAsFixed(1);
    final outputPath = path.join(dir, '$baseName-${suffix}x.m4a');

    final aFilter = buildAtempoFilter(tempo);

    await FFmpegHelper.runFFmpegShell(
      '-i "$downloadedPath" -filter:a "$aFilter" -c:a aac "$outputPath"',
    );

    // 验证输出文件是否实际存在
    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw Exception('ffmpeg 执行完成但输出文件未生成: $outputPath');
    }

    // 验证文件大小不为0
    final fileSize = await outputFile.length();
    if (fileSize == 0) {
      await outputFile.delete(); // 删除空文件
      throw Exception('ffmpeg 生成的输出文件大小为 0');
    }

    return outputPath;
  }

  /// 删除源文件（如果输出文件存在）
  ///
  /// [inputPath] 输入文件路径
  /// [outputPath] 输出文件路径
  ///
  /// 如果输出文件存在且输入文件存在，则删除输入文件
  static Future<void> deleteSourceIfOutputExists(
    String inputPath,
    String outputPath,
  ) async {
    final outFile = File(outputPath);
    if (await outFile.exists()) {
      final inputFile = File(inputPath);
      if (await inputFile.exists()) {
        await inputFile.delete();
      }
    }
  }
}
