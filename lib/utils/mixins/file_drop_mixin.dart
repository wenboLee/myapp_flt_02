import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

/// Mixin for handling file drag and drop state management.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with FileDropMixin {
///   @override
///   Widget build(BuildContext context) {
///     return VideoDropZone(
///       isDragging: isDragging,
///       onDragEntered: onDragEntered,
///       onDragExited: onDragExited,
///       onDragDone: (details) => onDragDone(details),
///     );
///   }
/// }
/// ```
mixin FileDropMixin<T extends StatefulWidget> on State<T> {
  final List<XFile> files = [];
  bool isDragging = false;

  /// Called when a drag enters the drop zone.
  void onDragEntered() {
    setState(() {
      isDragging = true;
    });
  }

  /// Called when a drag exits the drop zone.
  void onDragExited() {
    setState(() {
      isDragging = false;
    });
  }

  /// Called when files are dropped.
  ///
  /// [details] contains the dropped files.
  /// [fileFilter] optional filter function to accept only specific file types.
  /// [onFilesFiltered] optional callback when some files were filtered out.
  void onDragDone(
    DropDoneDetails details, {
    bool Function(String path)? fileFilter,
    void Function(int filteredCount)? onFilesFiltered,
  }) {
    final List<XFile> acceptedFiles = [];
    int filteredCount = 0;

    for (final XFile file in details.files) {
      if (fileFilter == null || fileFilter(file.path)) {
        acceptedFiles.add(file);
      } else {
        filteredCount++;
      }
    }

    setState(() {
      isDragging = false;
      files.addAll(acceptedFiles);
    });

    if (filteredCount > 0 && onFilesFiltered != null) {
      onFilesFiltered(filteredCount);
    }
  }

  /// Clears all files from the list.
  void clearFiles() {
    setState(() {
      files.clear();
    });
  }

  /// Removes a file at the specified index.
  void removeFile(int index) {
    setState(() {
      files.removeAt(index);
    });
  }

  /// Returns true if there are files in the list.
  bool get hasFiles => files.isNotEmpty;

  /// Returns the number of files in the list.
  int get fileCount => files.length;
}

