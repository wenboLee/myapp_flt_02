import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

/// FFmpeg 辅助工具类
/// 优先使用打包在应用内的 ffmpeg，其次尝试系统 ffmpeg
class FFmpegHelper {
  static String? _cachedFFmpegPath;

  /// 获取 ffmpeg 可执行文件路径
  /// 
  /// 优先级：
  /// 1. 应用内打包的 ffmpeg (macOS: Contents/Resources/ffmpeg)
  /// 2. 系统 PATH 中的 ffmpeg
  static Future<String?> getFFmpegPath() async {
    // 如果已经缓存了路径，直接返回
    if (_cachedFFmpegPath != null) {
      return _cachedFFmpegPath;
    }

    // 1. 尝试查找打包在应用内的 ffmpeg
    final bundledFFmpeg = await _getBundledFFmpegPath();
    if (bundledFFmpeg != null) {
      _cachedFFmpegPath = bundledFFmpeg;
      return bundledFFmpeg;
    }

    // 2. 尝试使用系统 ffmpeg
    final systemFFmpeg = await _getSystemFFmpegPath();
    if (systemFFmpeg != null) {
      _cachedFFmpegPath = systemFFmpeg;
      return systemFFmpeg;
    }

    return null;
  }

  /// 查找打包在应用内的 ffmpeg
  static Future<String?> _getBundledFFmpegPath() async {
    try {
      if (Platform.isMacOS) {
        // macOS: 获取应用包路径
        final executablePath = Platform.resolvedExecutable;
        // 路径格式: /path/to/App.app/Contents/MacOS/App
        final appDir = Directory(executablePath).parent.parent.path;
        final ffmpegPath = path.join(appDir, 'Resources', 'ffmpeg');

        final ffmpegFile = File(ffmpegPath);
        if (await ffmpegFile.exists()) {
          // 确保有执行权限
          await _ensureExecutable(ffmpegPath);
          print('✓ 找到打包的 ffmpeg: $ffmpegPath');
          return ffmpegPath;
        }
      } else if (Platform.isWindows) {
        // Windows: ffmpeg 可能在应用目录下
        final executablePath = Platform.resolvedExecutable;
        final appDir = Directory(executablePath).parent.path;
        final ffmpegPath = path.join(appDir, 'ffmpeg.exe');

        final ffmpegFile = File(ffmpegPath);
        if (await ffmpegFile.exists()) {
          print('✓ 找到打包的 ffmpeg: $ffmpegPath');
          return ffmpegPath;
        }
      }
    } catch (e) {
      print('查找打包 ffmpeg 时出错: $e');
    }

    return null;
  }

  /// 查找系统 PATH 中的 ffmpeg
  static Future<String?> _getSystemFFmpegPath() async {
    try {
      final shell = Shell();
      
      if (Platform.isWindows) {
        final result = await shell.run('where ffmpeg');
        if (result.isNotEmpty && result.first.exitCode == 0) {
          final output = result.first.outText.trim();
          if (output.isNotEmpty) {
            final ffmpegPath = output.split('\n').first.trim();
            print('✓ 找到系统 ffmpeg: $ffmpegPath');
            return ffmpegPath;
          }
        }
      } else {
        // macOS/Linux
        final result = await shell.run('which ffmpeg');
        if (result.isNotEmpty && result.first.exitCode == 0) {
          final output = result.first.outText.trim();
          if (output.isNotEmpty) {
            print('✓ 找到系统 ffmpeg: $output');
            return output;
          }
        }
      }
    } catch (e) {
      print('查找系统 ffmpeg 时出错: $e');
    }

    return null;
  }

  /// 确保文件有执行权限（仅 Unix 系统）
  static Future<void> _ensureExecutable(String filePath) async {
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', filePath]);
      } catch (e) {
        print('设置执行权限失败: $e');
      }
    }
  }

  /// 检查 ffmpeg 是否可用
  static Future<bool> isFFmpegAvailable() async {
    final ffmpegPath = await getFFmpegPath();
    return ffmpegPath != null;
  }

  /// 获取 ffmpeg 版本信息
  static Future<String?> getFFmpegVersion() async {
    try {
      final ffmpegPath = await getFFmpegPath();
      if (ffmpegPath == null) {
        return null;
      }

      final shell = Shell();
      final result = await shell.run('"$ffmpegPath" -version');
      
      if (result.isNotEmpty && result.first.exitCode == 0) {
        final output = result.first.outText;
        // 提取第一行版本信息
        final firstLine = output.split('\n').first;
        return firstLine;
      }
    } catch (e) {
      print('获取 ffmpeg 版本失败: $e');
    }

    return null;
  }

  /// 执行 ffmpeg 命令
  /// 
  /// 参数：
  /// - [args]: ffmpeg 命令参数（不包括 ffmpeg 本身）
  /// - [workingDirectory]: 工作目录（可选）
  /// 
  /// 示例：
  /// ```dart
  /// await FFmpegHelper.runFFmpeg([
  ///   '-i', 'input.mp4',
  ///   '-filter:v', 'setpts=0.5*PTS',
  ///   'output.mp4'
  /// ]);
  /// ```
  static Future<ProcessResult> runFFmpeg(
    List<String> args, {
    String? workingDirectory,
  }) async {
    final ffmpegPath = await getFFmpegPath();
    
    if (ffmpegPath == null) {
      throw Exception('ffmpeg 不可用。请安装 ffmpeg 或确保应用包含打包的 ffmpeg。');
    }

    print('执行 ffmpeg 命令: $ffmpegPath ${args.join(" ")}');

    return await Process.run(
      ffmpegPath,
      args,
      workingDirectory: workingDirectory,
    );
  }

  /// 使用 Shell 执行 ffmpeg 命令（用于复杂命令）
  /// 
  /// 参数：
  /// - [command]: 完整的 ffmpeg 命令（不包括 ffmpeg 路径）
  /// 
  /// 示例：
  /// ```dart
  /// await FFmpegHelper.runFFmpegShell(
  ///   '-i "input.mp4" -filter:v "setpts=0.5*PTS" "output.mp4"'
  /// );
  /// ```
  static Future<List<ProcessResult>> runFFmpegShell(String command) async {
    final ffmpegPath = await getFFmpegPath();
    
    if (ffmpegPath == null) {
      throw Exception('ffmpeg 不可用。请安装 ffmpeg 或确保应用包含打包的 ffmpeg。');
    }

    final shell = Shell();
    final fullCommand = '"$ffmpegPath" $command';
    
    print('执行 ffmpeg Shell 命令: $fullCommand');
    
    return await shell.run(fullCommand);
  }

  /// 清除缓存的 ffmpeg 路径（用于测试或重新检测）
  static void clearCache() {
    _cachedFFmpegPath = null;
  }
}

