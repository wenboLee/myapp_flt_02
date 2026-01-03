import 'dart:io';

import 'package:path/path.dart' as path;

/// Returns a reasonable Downloads directory for the current platform,
/// or falls back to the current working directory.
Future<String> getDownloadsDirectory() async {
  String dir;
  if (Platform.isWindows) {
    dir = path.join(Platform.environment['USERPROFILE'] ?? '', 'Downloads');
  } else {
    dir = path.join(Platform.environment['HOME'] ?? '', 'Downloads');
  }
  if (dir.isEmpty) {
    dir = Directory.current.path;
  }
  return dir;
}

/// Generate a unique output file path in [directory] for [filename].
/// If the file exists, appends a numeric suffix before the extension.
Future<String> generateUniqueOutputFilePath(String filename, {String? directory}) async {
  final dir = directory ?? await getDownloadsDirectory();
  String candidate = path.join(dir, filename);
  final base = path.basenameWithoutExtension(filename);
  final ext = path.extension(filename);
  int i = 1;
  while (await File(candidate).exists()) {
    candidate = path.join(dir, '${base}_$i$ext');
    i++;
  }
  return candidate;
}
