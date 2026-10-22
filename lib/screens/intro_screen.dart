import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/logo_placeholder.svg',
                  width: 160,
                  semanticsLabel: 'BridgeIt lotus logo',
                ),
                const SizedBox(height: 8),
                Text('BridgeIt', style: text.displaySmall),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.card,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _CharacterArtPlaceholder(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Hi, Bridge Builder! I'm ready to go on an "
                                'adventure, but I need your help to reach my '
                                'destination!',
                                style: text.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Complete each level, choose the correct '
                          'coordinating conjunctions, and build and strengthen '
                          'the bridges along the way.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/levels'),
                  child: const Text("Let's start"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed box standing in for the character art the client will supply.
class _CharacterArtPlaceholder extends StatelessWidget {
  const _CharacterArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 120,
      child: CustomPaint(
        painter: _DashedBoxPainter(AppColors.primary),
        child: const Center(
          child: Text('[Character art]', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}
