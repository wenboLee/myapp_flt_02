import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:myapp_flt_02/widgets/video_empty_file_list.dart';
import 'package:myapp_flt_02/widgets/video_file_list_item.dart';

/// 文件列表区域组件
///
/// 封装文件列表的显示逻辑，包括空状态、文件计数和操作按钮
class FileListSection extends StatelessWidget {
  const FileListSection({
    super.key,
    required this.files,
    this.onRemoveFile,
    this.trailingBuilder,
    this.emptyMessage = '暂无文件',
    this.headerBuilder,
    this.showCount = true,
  });

  /// 文件列表
  final List<XFile> files;

  /// 移除文件回调 (index)
  final ValueChanged<int>? onRemoveFile;

  /// 构建每个文件的尾部组件
  final Widget Function(XFile file)? trailingBuilder;

  /// 空状态消息
  final String emptyMessage;

  /// 头部构建器（文件计数和操作按钮区域）
  final WidgetBuilder? headerBuilder;

  /// 是否显示文件计数
  final bool showCount;

  bool get hasFiles => files.isNotEmpty;
  int get fileCount => files.length;

  @override
  Widget build(BuildContext context) {
    if (!hasFiles) {
      return Expanded(child: EmptyFileList(message: emptyMessage));
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCount || headerBuilder != null) _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: fileCount,
              itemBuilder: (context, index) {
                final file = files[index];
                return FileListItem(
                  file: file,
                  onRemove: onRemoveFile != null
                      ? () => onRemoveFile!(index)
                      : null,
                  trailing: trailingBuilder?.call(file),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (headerBuilder != null) {
      return headerBuilder!(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        '已添加 $fileCount 个文件',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}
