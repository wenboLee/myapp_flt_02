import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

/// yt-dlp 辅助工具类
class YtDlpHelper {
  static String? _cachedYtDlpPath;

  /// 获取 yt-dlp 可执行文件路径
  static Future<String?> getYtDlpPath() async {
    if (_cachedYtDlpPath != null) {
      return _cachedYtDlpPath;
    }

    // 1. 尝试查找系统 PATH 中的 yt-dlp
    final systemYtDlp = await _getSystemYtDlpPath();
    if (systemYtDlp != null) {
      _cachedYtDlpPath = systemYtDlp;
      return systemYtDlp;
    }

    return null;
  }

  /// 查找系统 PATH 中的 yt-dlp
  static Future<String?> _getSystemYtDlpPath() async {
    if (Platform.isWindows) {
      // Windows: 使用 where 命令
      try {
        final shell = Shell();
        final result = await shell.run('where yt-dlp');
        if (result.isNotEmpty && result.first.exitCode == 0) {
          final output = result.first.outText.trim();
          if (output.isNotEmpty) {
            final ytDlpPath = output.split('\n').first.trim();
            print('✓ 找到系统 yt-dlp: $ytDlpPath');
            return ytDlpPath;
          }
        }
      } catch (e) {
        print('查找系统 yt-dlp 时出错: $e');
      }
    } else {
      // macOS/Linux: 先检查常见安装位置，再使用 which 命令
      final commonPaths = [
        '/opt/homebrew/bin/yt-dlp', // Apple Silicon Mac (M1/M2/M3)
        '/usr/local/bin/yt-dlp', // Intel Mac / Homebrew
        '/usr/bin/yt-dlp', // 系统安装
        '/opt/local/bin/yt-dlp', // MacPorts
        '/usr/local/bin/yt-dlp', // Homebrew
        '/opt/homebrew/bin/yt-dlp', // Homebrew on Apple Silicon
      ];

      // 1. 优先检查常见路径
      for (final ytDlpPath in commonPaths) {
        final file = File(ytDlpPath);
        if (await file.exists()) {
          print('✓ 找到系统 yt-dlp: $ytDlpPath');
          return ytDlpPath;
        }
      }

      // 2. 尝试使用 which 命令
      try {
        final shell = Shell(
          environment: {
            'PATH':
                '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/local/bin',
          },
        );
        final result = await shell.run('which yt-dlp');
        if (result.isNotEmpty && result.first.exitCode == 0) {
          final output = result.first.outText.trim();
          if (output.isNotEmpty) {
            print('✓ 找到 yt-dlp (via which): $output');
            return output;
          }
        }
      } catch (e) {
        print('which 命令查找失败: $e');
      }

      // 3. 最后尝试直接执行
      for (final ytDlpPath in [
        '/opt/homebrew/bin/yt-dlp',
        '/usr/local/bin/yt-dlp',
      ]) {
        try {
          final result = await Process.run(ytDlpPath, ['--version']);
          if (result.exitCode == 0) {
            print('✓ 找到 yt-dlp (via direct exec): $ytDlpPath');
            return ytDlpPath;
          }
        } catch (e) {
          // 继续尝试下一个路径
        }
      }
    }

    return null;
  }

  /// 检查 yt-dlp 是否可用
  static Future<bool> isYtDlpAvailable() async {
    final ytDlpPath = await getYtDlpPath();
    return ytDlpPath != null;
  }

  /// 获取 yt-dlp 版本信息
  static Future<String?> getYtDlpVersion() async {
    try {
      final ytDlpPath = await getYtDlpPath();
      if (ytDlpPath == null) {
        return null;
      }

      final shell = Shell();
      final result = await shell.run('"$ytDlpPath" --version');

      if (result.isNotEmpty && result.first.exitCode == 0) {
        final output = result.first.outText.trim();
        return output;
      }
    } catch (e) {
      print('获取 yt-dlp 版本失败: $e');
    }

    return null;
  }

  /// 清除缓存的 yt-dlp 路径
  static void clearCache() {
    _cachedYtDlpPath = null;
  }

  /// 诊断 yt-dlp 检测问题
  ///
  /// 返回详细的诊断信息
  static Future<Map<String, dynamic>> diagnose() async {
    final result = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'system_yt_dlp': null,
      'common_paths_checked': [],
      'final_path': null,
      'is_available': false,
      'version': null,
    };

    try {
      // 检查系统 yt-dlp
      if (Platform.isMacOS || Platform.isLinux) {
        final commonPaths = [
          '/opt/homebrew/bin/yt-dlp',
          '/usr/local/bin/yt-dlp',
          '/usr/bin/yt-dlp',
          '/opt/local/bin/yt-dlp',
        ];

        for (final ytPath in commonPaths) {
          final exists = await File(ytPath).exists();
          result['common_paths_checked'].add({
            'path': ytPath,
            'exists': exists,
          });
        }
      }

      final system = await _getSystemYtDlpPath();
      result['system_yt_dlp'] = system;

      // 最终检测结果
      clearCache();
      final finalPath = await getYtDlpPath();
      result['final_path'] = finalPath;
      result['is_available'] = finalPath != null;

      if (finalPath != null) {
        result['version'] = await getYtDlpVersion();
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }
}
