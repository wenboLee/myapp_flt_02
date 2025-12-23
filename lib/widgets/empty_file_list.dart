import 'package:flutter/material.dart';

/// A widget that displays an empty state for file lists.
///
/// Shows a folder icon with a customizable message.
class EmptyFileList extends StatelessWidget {
  const EmptyFileList({
    super.key,
    this.message = '暂无文件',
    this.icon = Icons.folder_open,
  });

  /// The message to display. Defaults to '暂无文件'.
  final String message;

  /// The icon to display. Defaults to [Icons.folder_open].
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

