import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';

class QrColorPicker extends StatelessWidget {
  const QrColorPicker({
    super.key,
    required this.label,
    required this.currentColor,
    required this.onChanged,
  });

  final String label;
  final int currentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        GestureDetector(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Select $label'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: Color(currentColor),
                    onColorChanged: (color) {
                      onChanged(color.toARGB32());
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(currentColor),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
