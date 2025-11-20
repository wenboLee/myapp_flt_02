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
