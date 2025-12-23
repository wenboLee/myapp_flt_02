import 'package:flutter/material.dart';

/// Mixin for handling processing state management.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with ProcessingMixin {
///   Future<void> _doSomething() async {
///     startProcessing('正在处理...');
///     try {
///       await someAsyncOperation();
///     } finally {
///       stopProcessing();
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Stack(
///       children: [
///         // Your content
///         if (isProcessing)
///           ProcessingOverlay(message: processingMessage),
///       ],
///     );
///   }
/// }
/// ```
mixin ProcessingMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;
  String? _processingMessage;

  /// Returns true if currently processing.
  bool get isProcessing => _isProcessing;

  /// Returns the current processing message.
  String? get processingMessage => _processingMessage;

  /// Starts the processing state with an optional message.
  void startProcessing([String? message]) {
    setState(() {
      _isProcessing = true;
      _processingMessage = message;
    });
  }

  /// Updates the processing message without changing the processing state.
  void updateProcessingMessage(String message) {
    setState(() {
      _processingMessage = message;
    });
  }

  /// Stops the processing state.
  void stopProcessing() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _processingMessage = null;
      });
    }
  }
}

