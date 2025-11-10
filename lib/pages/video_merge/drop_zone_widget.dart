import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class VideoDropZone extends StatelessWidget {
  const VideoDropZone({
    super.key,
    required this.isDragging,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDragDone,
  });

  final bool isDragging;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final void Function(DropDoneDetails) onDragDone;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => onDragEntered(),
      onDragExited: (_) => onDragExited(),
      onDragDone: onDragDone,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDragging
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: isDragging ? Colors.blue : Colors.grey,
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
                isDragging ? Icons.file_download : Icons.file_upload_outlined,
                size: 64,
                color: isDragging ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isDragging ? '释放以添加文件' : '拖拽文件到此处',
                style: TextStyle(
                  fontSize: 18,
                  color: isDragging ? Colors.blue : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持拖拽多个文件',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
