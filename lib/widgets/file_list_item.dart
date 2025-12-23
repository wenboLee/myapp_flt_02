import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/utils/media_file_utils.dart';

/// A list item widget for displaying a file with its icon, name, and path.
///
/// Supports optional trailing actions and tap handling.
class FileListItem extends StatelessWidget {
  const FileListItem({
    super.key,
    required this.file,
    this.onRemove,
    this.trailing,
    this.onTap,
  });

  /// The file to display.
  final XFile file;

  /// Callback when the remove button is pressed.
  /// If null, no remove button will be shown.
  final VoidCallback? onRemove;

  /// Optional trailing widget(s). If provided, will be displayed before the remove button.
  final Widget? trailing;

  /// Callback when the list item is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fileName = getFileName(file.path);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          getFileIcon(fileName),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          file.path,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildTrailing() {
    final List<Widget> actions = [];

    if (trailing != null) {
      actions.add(trailing!);
    }

    if (onRemove != null) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
          tooltip: '移除',
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }
}

