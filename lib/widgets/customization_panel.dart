import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'color_picker.dart';

class CustomizationPanel extends StatelessWidget {
  final int foregroundColor;
  final int backgroundColor;
  final double correctionLevel;
  final String? frameText;
  final ValueChanged<int> onForegroundColorChanged;
  final ValueChanged<int> onBackgroundColorChanged;
  final ValueChanged<double> onCorrectionLevelChanged;
  final ValueChanged<String?> onFrameTextChanged;
  final VoidCallback? onSave;
  final bool isSaved;

  const CustomizationPanel({
    super.key,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.correctionLevel,
    this.frameText,
    required this.onForegroundColorChanged,
    required this.onBackgroundColorChanged,
    required this.onCorrectionLevelChanged,
    required this.onFrameTextChanged,
    this.onSave,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customization',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            QrColorPicker(
              label: 'Foreground Color',
              currentColor: foregroundColor,
              onChanged: onForegroundColorChanged,
            ),
            SizedBox(height: 12),
            QrColorPicker(
              label: 'Background Color',
              currentColor: backgroundColor,
              onChanged: onBackgroundColorChanged,
            ),
            SizedBox(height: 16),
            _buildCorrectionLevelSlider(context),
            SizedBox(height: 16),
            _buildFrameTextField(context),
            SizedBox(height: 16),
            if (onSave != null)
              SizedBox(
                width: double.infinity,
                child: isSaved
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.check_circle_outline),
                        label: Text('Saved to History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: AppTheme.success,
                          disabledBackgroundColor: AppTheme.success.withValues(
                            alpha: 0.15,
                          ),
                          disabledForegroundColor: AppTheme.success,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: onSave,
                        icon: Icon(Icons.bookmark_add_outlined),
                        label: Text('Save to History'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionLevelSlider(BuildContext context) {
    String getLevelLabel(double value) {
      if (value <= 0.07) return 'Low (7%)';
      if (value <= 0.15) return 'Medium (15%)';
      if (value <= 0.25) return 'Quartile (25%)';
      return 'High (30%)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Error Correction',
                style: TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                getLevelLabel(correctionLevel),
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        Slider(
          value: correctionLevel,
          min: 0.07,
          max: 0.30,
          divisions: 3,
          activeColor: AppTheme.primaryPurple,
          onChanged: onCorrectionLevelChanged,
        ),
      ],
    );
  }

  Widget _buildFrameTextField(BuildContext context) {
    return TextFormField(
      initialValue: frameText,
      decoration: InputDecoration(
        labelText: 'Frame Text (optional)',
        hintText: 'e.g., Scan Me',
        prefixIcon: Icon(Icons.text_fields_outlined),
      ),
      maxLength: 30,
      onChanged: onFrameTextChanged,
    );
  }
}
