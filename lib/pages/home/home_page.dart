import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

class FileDropScreen extends StatefulWidget {
  const FileDropScreen({super.key});

  @override
  State<FileDropScreen> createState() => _FileDropScreenState();
}

class _FileDropScreenState extends State<FileDropScreen> {
  final List<XFile> _files = [];
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
    setState(() {
      _isDragging = false;
      _files.addAll(details.files);
    });
  }

  void _clearFiles() {
    setState(() {
      _files.clear();
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('文件拖拽应用'),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清空所有文件',
              onPressed: _clearFiles,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDropZone(),
          if (_files.isNotEmpty) _buildActionBar(),
          _buildFileList(),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _mergeVideos,
            icon: const Icon(Icons.video_library),
            label: const Text('合并视频'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVideoFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['mp4', 'm4a', 'avi', 'mov', 'mkv', 'flv', 'wmv', 'm3u8', 'ts'].contains(extension);
  }

  Future<void> _mergeVideos() async {
    if (_files.isEmpty) {
      return;
    }
    
    // 过滤出视频文件
    final videoFiles = _files.where((file) => _isVideoFile(file.path)).toList();
    
    if (videoFiles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有找到视频文件'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (videoFiles.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请添加至少2个视频文件（如 video.m3u8 和 audio.m3u8）'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // 从第一个视频文件获取文件名
    final firstVideoFileName = path.basenameWithoutExtension(videoFiles[0].path);
    final defaultOutputFileName = '$firstVideoFileName-merged.mp4';
    
    // 选择输出文件路径
    String? outputPath;
    try {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '选择输出文件位置',
        fileName: defaultOutputFileName,
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件选择器错误：${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (outputPath == null) {
      // 用户取消了保存
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('取消了'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // 将 outputPath 赋值给非空变量
    final String outputFilePath = outputPath;
    
    // 检查 ffmpeg 是否安装
    if (!mounted) return;
    final hasFFmpeg = await _checkFFmpegInstalled();
    if (!hasFFmpeg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未检测到 ffmpeg，请先安装 ffmpeg'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // 显示合并进度
    if (!mounted) return;
    _showMergingDialog();
    
    try {
      // 执行 ffmpeg 命令
      final inputFile1 = videoFiles[0].path;
      final inputFile2 = videoFiles[1].path;
      
      final shell = Shell();
      await shell.run(
        'ffmpeg -i "$inputFile1" -i "$inputFile2" -c copy "$outputFilePath"',
      );
      
      // 合并成功
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭进度对话框
      
      final fileName = path.basename(outputFilePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('合并成功！输出文件：$fileName'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '打开文件夹',
            onPressed: () => _openFileLocation(outputFilePath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭进度对话框
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('合并失败：${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _checkFFmpegInstalled() async {
    try {
      final shell = Shell();
      await shell.run('ffmpeg -version');
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showMergingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在合并视频...'),
          ],
        ),
      ),
    );
  }

  void _openFileLocation(String filePath) {
    final directory = path.dirname(filePath);
    
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  Widget _buildDropZone() {
    return DropTarget(
      onDragEntered: (_) => _onDragEntered(),
      onDragExited: (_) => _onDragExited(),
      onDragDone: _onDragDone,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isDragging
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: _isDragging ? Colors.blue : Colors.grey,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDragging ? Icons.file_download : Icons.file_upload_outlined,
                size: 64,
                color: _isDragging ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _isDragging ? '释放以添加文件' : '拖拽文件到此处',
                style: TextStyle(
                  fontSize: 18,
                  color: _isDragging ? Colors.blue : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持拖拽多个文件',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '暂无文件',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              '已添加 ${_files.length} 个文件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                return _FileListItem(
                  file: _files[index],
                  index: index,
                  onRemove: () => _removeFile(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  final XFile file;
  final int index;
  final VoidCallback onRemove;

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  IconData _getFileIcon(String fileName) {
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
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _getFileName(file.path);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFileIcon(fileName),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          file.path,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
          tooltip: '移除',
        ),
      ),
    );
  }
}

