import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// A dialog widget that shows a loading animation with a message.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => const LoadingDialog(message: '正在处理...'),
/// );
/// ```
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    super.key,
    this.message = '请稍候...',
    this.useSimpleIndicator = false,
  });

  /// The message to display below the loading indicator.
  final String message;

  /// If true, uses a simple [CircularProgressIndicator] instead of the animated widget.
  final bool useSimpleIndicator;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useSimpleIndicator)
              const CircularProgressIndicator()
            else
              LoadingAnimationWidget.staggeredDotsWave(
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a loading dialog and returns a function to close it.
///
/// Example:
/// ```dart
/// final close = showLoadingDialog(context, message: '正在合并...');
/// try {
///   await doSomething();
/// } finally {
///   close();
/// }
/// ```
VoidCallback showLoadingDialog(
  BuildContext context, {
  String message = '请稍候...',
  bool barrierDismissible = false,
  bool useSimpleIndicator = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => LoadingDialog(
      message: message,
      useSimpleIndicator: useSimpleIndicator,
    ),
  );

  return () {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  };
}

