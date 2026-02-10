import 'package:flutter/material.dart';

/// A full-screen overlay that shows a loading indicator with an optional message.
///
/// Use this widget to block user interaction while processing is in progress.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     if (isProcessing)
///       ProcessingOverlay(message: '正在处理...'),
///   ],
/// )
/// ```
class ProcessingOverlay extends StatelessWidget {
  const ProcessingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  /// Optional message to display below the loading indicator.
  final String? message;

  /// Background color of the overlay. Defaults to semi-transparent black.
  final Color? backgroundColor;

  /// Color of the loading indicator. Defaults to white.
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: indicatorColor ?? Colors.white,
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(
                    color: indicatorColor ?? Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

