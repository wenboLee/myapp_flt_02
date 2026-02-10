import 'package:flutter/material.dart';
import 'package:myapp_flt_02/utils/video_media_utils.dart';
import 'package:myapp_flt_02/utils/notifications_helper.dart';

/// 通知帮助类
///
/// 统一处理 Snackbar 和系统通知
class NotificationHelper {
  NotificationHelper._();

  /// 显示成功通知（带打开文件夹操作）
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? filePath,
    bool showSystemNotification = false,
    String? notificationTitle,
    String? notificationBody,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: filePath != null
            ? SnackBarAction(
                label: '打开文件夹',
                onPressed: () => openFileLocation(filePath),
              )
            : null,
      ),
    );

    if (showSystemNotification) {
      _showSystemNotification(
        title: notificationTitle ?? '操作完成',
        body: notificationBody ?? message,
      );
    }
  }

  /// 显示错误通知
  static void showError(
    BuildContext context, {
    required String message,
    Object? error,
  }) {
    if (!context.mounted) return;

    final errorMessage = error != null
        ? '$message：${error.toString()}'
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 5),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 显示进度通知（批量处理）
  static void showProgress(
    BuildContext context, {
    required String message,
    int? current,
    int? total,
  }) {
    if (!context.mounted) return;

    final displayMessage = current != null && total != null
        ? '[$current/$total] $message'
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示批量处理完成通知
  static void showBatchComplete(
    BuildContext context, {
    required int successCount,
    required int failCount,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('批处理完成：成功 $successCount 个，失败 $failCount 个'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示下载完成通知
  static void showDownloadComplete(
    BuildContext context, {
    required String fileName,
    required String filePath,
    required int current,
    required int total,
  }) {
    if (!context.mounted) return;

    final message = total == 1
        ? '下载完成：$fileName'
        : '[$current/$total] 下载完成：$fileName';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '打开文件夹',
          onPressed: () => openFileLocation(filePath),
        ),
      ),
    );

    // 系统通知
    _showSystemNotification(title: '下载完成', body: fileName);
  }

  /// 显示下载并处理完成通知
  static void showDownloadAndProcessComplete(
    BuildContext context, {
    required String fileName,
    required String filePath,
    required int current,
    required int total,
  }) {
    if (!context.mounted) return;

    final message = total == 1
        ? '下载并处理完成：$fileName'
        : '[$current/$total] 下载并处理完成：$fileName';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '打开文件夹',
          onPressed: () => openFileLocation(filePath),
        ),
      ),
    );

    // 系统通知
    _showSystemNotification(title: '下载并处理完成', body: fileName);
  }

  /// 显示下载失败通知
  static void showDownloadFailed(
    BuildContext context, {
    required String url,
    required Object error,
    int? current,
    int? total,
  }) {
    if (!context.mounted) return;

    final prefix = current != null && total != null ? '[$current/$total] ' : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${prefix}下载失败（$url）：${error.toString()}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// 显示文件被过滤通知
  static void showFilesFiltered(BuildContext context, int count) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已忽略 $count 个非视频文件')));
  }

  /// 显示无可用文件通知
  static void showNoValidFiles(
    BuildContext context, {
    String message = '没有找到有效的媒体文件',
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// 显示需要更多文件通知
  static void showNeedMoreFiles(
    BuildContext context, {
    int minCount = 2,
    String fileType = '视频',
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('请添加至少$minCount个$fileType文件'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示截图完成通知
  static void showScreenshotComplete(
    BuildContext context, {
    required String dirName,
    required int intervalMinutes,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('截图已生成（间隔 $intervalMinutes 分钟）：$dirName/')),
    );
  }

  /// 显示截图失败通知
  static void showScreenshotFailed(
    BuildContext context, {
    required Object error,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('截图失败: ${error.toString()}')));
  }

  /// 显示批量处理单个文件完成通知
  static void showBatchItemComplete({
    required String fileName,
    required int current,
    required int total,
  }) {
    _showSystemNotification(title: '处理完成 [$current/$total]', body: fileName);
  }

  /// 显示批量处理单个文件失败通知
  static void showBatchItemFailed({
    required String fileName,
    required int current,
    required int total,
  }) {
    _showSystemNotification(title: '处理失败 [$current/$total]', body: fileName);
  }

  /// 私有方法：显示系统通知
  static void _showSystemNotification({
    required String title,
    required String body,
  }) {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      Notifications.showNotification(id: id, title: title, body: body);
    } catch (_) {}
  }
}
