import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Media file type related helpers.

/// Returns true if [filePath] has a common video file extension
/// that FFmpeg can typically handle.
bool isVideoFile(String filePath) {
  final String extension = filePath.split('.').last.toLowerCase();
  const List<String> videoExtensions = <String>[
    // Very common containers
    'mp4',
    'm4v',
    'mov',
    'mkv',
    'avi',
    'wmv',
    'webm',
    'flv',
    '3gp',

    // Additional FFmpeg‑supported containers / formats
    '3g2',
    'f4v',
    'f4p',
    'f4a',
    'f4b',
    'ts',
    'mts',
    'm2ts',
    'vob',
    'ogv',
    'ogg',
    'm2v',
    'mpg',
    'mpeg',
    'mpv',
    'rm',
    'rmvb',
    'asf',
    'divx',
    'xvid',
    'mxf',
    'nut',
    'dv',
    'h264',
    'h265',
    'hevc',
    'y4m',
  ];
  return videoExtensions.contains(extension);
}

/// Returns true if [filePath] has a common audio file extension.
bool isAudioFile(String filePath) {
  final String extension = filePath.split('.').last.toLowerCase();
  const List<String> audioExtensions = <String>[
    'mp3',
    'wav',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'wma',
    'opus',
    'aiff',
    'alac',
  ];
  return audioExtensions.contains(extension);
}

/// Returns true if [filePath] is either a video or audio file.
bool isMediaFile(String filePath) {
  return isVideoFile(filePath) || isAudioFile(filePath);
}

/// Extracts the file name from a file path.
/// Handles both forward slashes and backslashes.
String getFileName(String filePath) {
  return filePath.split('/').last.split('\\').last;
}

/// Returns an appropriate icon for the given file name based on its extension.
IconData getFileIcon(String fileName) {
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
    case 'webp':
    case 'bmp':
      return Icons.image;
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'mkv':
    case 'wmv':
    case 'flv':
    case 'webm':
    case 'ts':
    case 'm4v':
      return Icons.video_file;
    case 'mp3':
    case 'wav':
    case 'm4a':
    case 'aac':
    case 'flac':
    case 'ogg':
    case 'wma':
      return Icons.audio_file;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Icons.folder_zip;
    case 'txt':
    case 'md':
      return Icons.text_snippet;
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
      return Icons.data_object;
    default:
      return Icons.insert_drive_file;
  }
}

/// Opens the file location in the system file explorer.
void openFileLocation(String filePath) {
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
    // Ignore errors when opening file location
  }
}

/// Opens the file location and selects the file in the system file explorer.
void openAndSelectFile(String filePath) {
  try {
    if (Platform.isWindows) {
      Process.run('explorer', ['/select,', filePath]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', filePath]);
    } else if (Platform.isLinux) {
      // Linux doesn't have a standard way to select a file, so just open the folder
      openFileLocation(filePath);
    }
  } catch (_) {
    // Ignore errors when opening file location
  }
}
