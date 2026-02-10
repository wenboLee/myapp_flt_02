import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:myapp_flt_02/utils/file_paths.dart';

class YtDlpException implements Exception {
  final String message;
  final int? exitCode;
  final String? stdout;
  final String? stderr;

  YtDlpException(this.message, {this.exitCode, this.stdout, this.stderr});

  @override
  String toString() => 'YtDlpException: $message (exitCode: $exitCode)';
}

/// Run yt-dlp with the given args and return the ProcessResult.
/// Throws [YtDlpException] if the process cannot be started.
Future<ProcessResult> runYtDlp(List<String> args) async {
  try {
    final result = await Process.run('yt-dlp', args);
    return result;
  } on ProcessException catch (e) {
    throw YtDlpException('yt-dlp not found or failed to start: ${e.message}');
  } catch (e) {
    throw YtDlpException('yt-dlp failed: ${e.toString()}');
  }
}

/// Download audio for [url] into [outDir] or into the system Downloads directory.
/// Returns the absolute path to the downloaded file if it can be determined, or null.
Future<String?> downloadAudioToDirectory(
  String url, {
  String? outDir,
  String audioFormat = 'm4a',
}) async {
  final dir = outDir ?? await getDownloadsDirectory();

  final outputTemplate = path.join(dir, '%(title)s.%(ext)s');

  final args = [
    '-f', 'ba',
    '--extract-audio',
    '--audio-format', audioFormat,
    '-o', outputTemplate,
    url,
  ];

  final result = await runYtDlp(args);

  if (result.exitCode != 0) {
    throw YtDlpException('yt-dlp exited with non-zero code',
        exitCode: result.exitCode, stdout: result.stdout?.toString(), stderr: result.stderr?.toString());
  }

  final out = (result.stdout ?? '').toString();

  // Try parse Destination line
  final destMatch = _parseDestinationFromOutput(out);
  if (destMatch != null) return destMatch;

  // Fallback: find most recently modified file with requested extension
  final ext = '.${audioFormat.toLowerCase()}';
  final dirList = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith(ext))
      .toList();

  if (dirList.isNotEmpty) {
    dirList.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return dirList.first.path;
  }

  return null;
}

String? _parseDestinationFromOutput(String stdout) {
  // Common pattern: "Destination: /path/to/file.m4a"
  final match = RegExp(r'Destination:\s*(.+)').firstMatch(stdout);
  if (match != null && match.groupCount >= 1) {
    return match.group(1)?.trim();
  }

  // Another pattern sometimes appears in yt-dlp output
  // e.g. "[ffmpeg] Destination: ..." or "[download] Destination: ..."
  final altMatch = RegExp(r'Destination\s*:\s*(.+)').firstMatch(stdout);
  if (altMatch != null && altMatch.groupCount >= 1) {
    return altMatch.group(1)?.trim();
  }

  return null;
}
