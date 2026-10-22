import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BridgeState { open, cracked, built, broken, reinforced }

const _labels = {
  BridgeState.open: 'Bridge open',
  BridgeState.cracked: 'Bridge cracked',
  BridgeState.built: 'Bridge built',
  BridgeState.broken: 'Bridge broken',
  BridgeState.reinforced: 'Bridge reinforced',
};

// Scene geometry as fractions of the panel, shared by painter and widgets.
const _deck = 0.58; // top of the cliffs and of the bridge deck (of height)
const _waterTop = 0.8; // top of the river (of height)
const _cliff = 0.22; // cliff width (of width)
const _stub = 0.16; // plank stub length (of width)
const _gapSize = Size(64, 48);
const _carSize = Size(40, 22);

/// Two cliffs over a river with a bridge between them. The clause cards, the
/// [gap] drop target and the vehicle are widgets over a painted backdrop. The
/// vehicle drives to the far cliff once the bridge is built or reinforced.
class BridgeScene extends StatelessWidget {
  const BridgeScene({
    super.key,
    required this.state,
    required this.left,
    required this.right,
    required this.gap,
    this.placedWord,
  });

  final BridgeState state;
  final String left;
  final String right;

  /// Shown in the bridge once it is built or reinforced.
  final String? placedWord;

  /// Fills a 64x48 slot centered over the missing bridge section. Hidden
  /// when the bridge is broken.
  final Widget gap;

  @override
  Widget build(BuildContext context) {
    final crossed =
        state == BridgeState.built || state == BridgeState.reinforced;
    final word = placedWord;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: AspectRatio(
          aspectRatio: 350 / 260,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: _labels[state],
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final (w, h) = (box.maxWidth, box.maxHeight);
                  // Puts the car's wheels on the deck line.
                  final carY =
                      2 *
                          (h * _deck - _carSize.height) /
                          (h - _carSize.height) -
                      1;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _ScenePainter(state)),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        width: w * 0.44,
                        child: _ClauseCard(left),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        width: w * 0.44,
                        child: _ClauseCard(right),
                      ),
                      if (state != BridgeState.broken)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: h * _deck - _gapSize.height / 2,
                          child: Center(
                            child: SizedBox.fromSize(
                              size: _gapSize,
                              child: crossed && word != null
                                  ? _PlacedWord(word)
                                  : gap,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              alignment: Alignment(crossed ? 1 : -1, carY),
                              child: CustomPaint(
                                size: _carSize,
                                painter: _CarPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClauseCard extends StatelessWidget {
  const _ClauseCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlacedWord extends StatelessWidget {
  const _PlacedWord(this.word);

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.correct, width: 3),
      ),
      child: Text(
        word,
        style: const TextStyle(
          color: AppColors.cliff,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.state);

  final BridgeState state;

  @override
  void paint(Canvas canvas, Size size) {
    final (w, h) = (size.width, size.height);
    final deck = h * _deck;
    final thick = h * 0.05;
    final paint = Paint()..color = AppColors.primary;
    canvas.drawRect(Rect.fromLTRB(0, h * _waterTop, w, h), paint);
    paint.color = AppColors.cliff;
    const lip = Radius.circular(12);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(0, deck, w * _cliff, h, topRight: lip),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(w * (1 - _cliff), deck, w, h, topLeft: lip),
      paint,
    );

    paint.color = AppColors.bridge;
    final left = Rect.fromLTWH(w * _cliff, deck, w * _stub, thick);
    final right = Rect.fromLTWH(
      w * (1 - _cliff - _stub),
      deck,
      w * _stub,
      thick,
    );
    switch (state) {
      case BridgeState.built || BridgeState.reinforced:
        _plank(
          canvas,
          Rect.fromLTRB(left.left, deck, right.right, deck + thick),
          paint,
        );
        if (state == BridgeState.reinforced) {
          _supports(canvas, size, deck + thick);
        }
      case BridgeState.broken:
        _plank(canvas, left, paint, pivot: left.topLeft, angle: 0.8);
        _plank(canvas, right, paint, pivot: right.topRight, angle: -0.8);
      case BridgeState.open || BridgeState.cracked:
        _plank(canvas, left, paint);
        _plank(canvas, right, paint);
        if (state == BridgeState.cracked) {
          _crack(canvas, left.right, 1, deck, thick);
          _crack(canvas, right.left, -1, deck, thick);
        }
    }
  }

  void _plank(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    Offset pivot = Offset.zero,
    double angle = 0,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      paint,
    );
    canvas.restore();
  }

  /// A zigzag across the plank end; [dir] points from the end toward the cliff.
  void _crack(Canvas canvas, double x, double dir, double deck, double thick) {
    final path = Path()
      ..moveTo(x - dir * 6, deck)
      ..lineTo(x - dir * 11, deck + thick * 0.45)
      ..lineTo(x - dir * 7, deck + thick * 0.6)
      ..lineTo(x - dir * 12, deck + thick);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.wrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A V of braces under the deck, resting on a pillar in the river.
  void _supports(Canvas canvas, Size size, double under) {
    final apex = Offset(size.width / 2, under + size.height * 0.1);
    final brace = Paint()
      ..color = AppColors.bridge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.3, under), apex, brace);
    canvas.drawLine(Offset(size.width * 0.7, under), apex, brace);
    canvas.drawLine(apex, Offset(apex.dx, size.height * _waterTop), brace);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.state != state;
}

class _CarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.vehicle;
    const round = Radius.circular(4);
    canvas.drawRRect(RRect.fromLTRBR(0, 8, size.width, 18, round), paint);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        9,
        0,
        size.width - 9,
        10,
        topLeft: round,
        topRight: round,
      ),
      paint,
    );
    paint.color = AppColors.sky;
    canvas.drawRect(const Rect.fromLTWH(12, 2, 7, 6), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 19, 2, 7, 6), paint);
    paint.color = AppColors.ink;
    canvas.drawCircle(const Offset(10, 18), 4, paint);
    canvas.drawCircle(Offset(size.width - 10, 18), 4, paint);
  }

  @override
  bool shouldRepaint(_CarPainter old) => false;
}
