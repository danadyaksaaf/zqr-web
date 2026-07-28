import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../widgets/qr_preview_card.dart';

class GeneratorScreenLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyHint;
  final QRData? currentQR;
  final Widget inputCard;

  const GeneratorScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyHint,
    required this.currentQR,
    required this.inputCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(stacked ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              SizedBox(height: 24),
              if (stacked)
                Column(
                  children: [
                    QrPreviewCard(
                      currentQR: currentQR,
                      emptyHint: emptyHint,
                      compact: true,
                    ),
                    SizedBox(height: 16),
                    inputCard,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: inputCard),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: QrPreviewCard(
                        currentQR: currentQR,
                        emptyHint: emptyHint,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
