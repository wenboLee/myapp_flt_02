import 'package:flutter/material.dart';

/// Configuration for a slider selection dialog.
class SliderConfig {
  const SliderConfig({
    required this.min,
    required this.max,
    required this.initialValue,
    this.divisions,
    required this.valueFormatter,
    required this.unitLabel,
  });

  /// Minimum value of the slider.
  final double min;

  /// Maximum value of the slider.
  final double max;

  /// Initial value of the slider.
  final double initialValue;

  /// Number of divisions. If null, the slider is continuous.
  final int? divisions;

  /// Formats the value for display (e.g., "2.0x" or "5 分钟").
  final String Function(double value) valueFormatter;

  /// Label for the unit (e.g., "倍速范围：1.5x - 5.0x").
  final String unitLabel;
}

/// A dialog with a slider for selecting a numeric value.
///
/// Returns the selected value, or null if cancelled.
class SliderSelectionDialog extends StatefulWidget {
  const SliderSelectionDialog({
    super.key,
    required this.title,
    this.message,
    required this.config,
  });

  /// Dialog title.
  final String title;

  /// Optional message below the title.
  final String? message;

  /// Slider configuration.
  final SliderConfig config;

  @override
  State<SliderSelectionDialog> createState() => _SliderSelectionDialogState();
}

class _SliderSelectionDialogState extends State<SliderSelectionDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.config.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message != null)
              Text(
                widget.message!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  config.valueFormatter(_value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Slider(
              value: _value,
              min: config.min,
              max: config.max,
              divisions: config.divisions,
              label: config.valueFormatter(_value),
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  config.valueFormatter(config.min),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  config.valueFormatter(config.max),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.unitLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// Shows a slider selection dialog and returns the selected value.
///
/// Returns null if the user cancels.
Future<double?> showSliderSelectionDialog(
  BuildContext context, {
  required String title,
  String? message,
  required SliderConfig config,
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => SliderSelectionDialog(
      title: title,
      message: message,
      config: config,
    ),
  );
}

/// Pre-configured slider config for speed/tempo selection (1.5x - 5.0x).
SliderConfig speedSliderConfig({double initialValue = 2.0}) {
  return SliderConfig(
    min: 1.5,
    max: 5.0,
    initialValue: initialValue,
    divisions: 35,
    valueFormatter: (v) => '${v.toStringAsFixed(1)}x',
    unitLabel: '倍速范围：1.5x - 5.0x',
  );
}

/// Pre-configured slider config for interval selection (2-10 minutes).
SliderConfig intervalSliderConfig({double initialValue = 5.0}) {
  return SliderConfig(
    min: 2,
    max: 10,
    initialValue: initialValue,
    divisions: 8,
    valueFormatter: (v) => '${v.toStringAsFixed(0)} 分钟',
    unitLabel: '范围：2 分钟 - 10 分钟，步长 1 分钟',
  );
}

