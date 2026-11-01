import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BridgeState { open, cracked, built, broken }

const _labels = {
  BridgeState.open: 'Bridge open',
  BridgeState.cracked: 'Bridge cracked',
  BridgeState.built: 'Bridge built',
  BridgeState.broken: 'Bridge broken',
};

// Scene geometry as fractions of the panel, shared by painter and widgets.
const _deck = 0.58; // top of the cliffs and of the bridge deck (of height)
const _deckThickness = 0.05; // deck plank height (of height)
const _waterTop = 0.8; // top of the river (of height)
const _towerX = 0.17; // left tower center (of width); the right one mirrors it
const _towerTop = 0.32; // top of the towers (of height)
const _deckEnd = 0.38; // where the left deck stops (of width)
const _gapSize = Size(64, 48);
const _carSize = Size(46, 22);
const _fallTime = Duration(milliseconds: 500);
const _fallAngle = 0.35; // how far a broken deck tilts (radians)
final _outline = Paint()
  ..color = AppColors.ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;

/// A suspension bridge over water, with a gap in it. The sentence card, the
/// [gap] drop target and the vehicle are widgets over a painted backdrop. The
/// student's [foundations] sit under the scene, so long sentences can wrap,
/// and the vehicle drives to the far cliff when [crossed].
class BridgeScene extends StatelessWidget {
  const BridgeScene({
    super.key,
    required this.state,
    required this.left,
    required this.right,
    required this.gap,
    this.placedWord,
    this.foundations = const [],
    this.crossed = false,
    this.onCrossed,
    this.onTapWord,
  });

  final BridgeState state;
  final String left;
  final String right;

  /// Shown in the bridge once it is built.
  final String? placedWord;

  /// Fills a 64x48 slot centered over the missing bridge section. Hidden
  /// when the bridge is broken.
  final Widget gap;

  /// Sentences that strengthen the bridge.
  final List<String> foundations;
  final bool crossed;

  /// Called when the vehicle reaches the far cliff.
  final VoidCallback? onCrossed;

  /// Called when the student taps the word in a built bridge.
  final VoidCallback? onTapWord;

  @override
  Widget build(BuildContext context) {
    final complete = state == BridgeState.built;
    final word = placedWord;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
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
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: state == BridgeState.broken ? 1 : 0,
                              ),
                              duration: _fallTime,
                              curve: Curves.easeIn,
                              builder: (context, fall, _) => CustomPaint(
                                painter: _ScenePainter(state, fall),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            top: 8,
                            child: _SentenceCard(
                              left: left,
                              right: right,
                              word: complete ? word : null,
                            ),
                          ),
                          if (state != BridgeState.broken)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: h * _deck - _gapSize.height / 2,
                              child: Center(
                                child: SizedBox.fromSize(
                                  size: _gapSize,
                                  child: complete && word != null
                                      ? _PlacedWord(word, onTap: onTapWord)
                                      : gap,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                  onEnd: onCrossed,
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
            for (final sentence in foundations) _Foundation(sentence),
          ],
        ),
      ),
    );
  }
}

/// Both clauses in one card, with the missing conjunction as an inline blank
/// that shows the placed [word] once the bridge is complete.
class _SentenceCard extends StatelessWidget {
  const _SentenceCard({required this.left, required this.right, this.word});

  final String left;
  final String right;
  final String? word;

  @override
  Widget build(BuildContext context) {
    final word = this.word;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$left '),
            word == null
                ? const TextSpan(
                    text: '_____',
                    style: TextStyle(color: AppColors.primary),
                  )
                : TextSpan(
                    text: word,
                    style: const TextStyle(
                      color: AppColors.cliff,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            TextSpan(text: ' $right'),
          ],
        ),
        textAlign: TextAlign.center,
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
  const _PlacedWord(this.word, {this.onTap});

  final String word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('placed-word'),
        onTap: onTap,
        child: Container(
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
        ),
      ),
    );
  }
}

/// One student sentence, as a beam under the deck.
class _Foundation extends StatelessWidget {
  const _Foundation(this.sentence);

  final String sentence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.deck,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sentence,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.card, fontSize: 13),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.state, this.fall);

  final BridgeState state;
  final double fall;

  @override
  void paint(Canvas canvas, Size size) {
    final (w, h) = (size.width, size.height);
    final deck = h * _deck;
    final thick = h * _deckThickness;
    final waterTop = h * _waterTop;
    final paint = Paint()..color = AppColors.water;
    canvas.drawRect(Rect.fromLTRB(0, waterTop, w, h), paint);
    paint.color = AppColors.sky.withValues(alpha: 0.5);
    for (final (x, y) in const [(0.3, 0.86), (0.62, 0.93), (0.8, 0.85)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * x, h * y), width: 30, height: 3),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    paint.color = AppColors.rock;
    canvas.drawOval(Rect.fromLTRB(-16, h * 0.86, w * 0.09, h * 1.08), paint);
    canvas.drawOval(Rect.fromLTRB(w * 0.92, h * 0.84, w + 16, h * 1.08), paint);

    final angle = state == BridgeState.broken ? _fallAngle * fall : 0.0;
    _cables(canvas, w, deck, angle);
    _tower(canvas, w * _towerX, h, deck, waterTop);
    _tower(canvas, w * (1 - _towerX), h, deck, waterTop);

    paint.color = AppColors.deck;
    final left = Rect.fromLTWH(0, deck, w * _deckEnd, thick);
    final right = Rect.fromLTWH(w * (1 - _deckEnd), deck, w * _deckEnd, thick);
    final leftPivot = Offset(w * _towerX, deck);
    final rightPivot = Offset(w * (1 - _towerX), deck);
    switch (state) {
      case BridgeState.built:
        _plank(canvas, Rect.fromLTRB(0, deck, w, deck + thick), paint);
      case BridgeState.broken:
        _plank(canvas, left, paint, pivot: leftPivot, angle: angle);
        _plank(canvas, right, paint, pivot: rightPivot, angle: -angle);
      case BridgeState.open || BridgeState.cracked:
        _plank(canvas, left, paint);
        _plank(canvas, right, paint);
        if (state == BridgeState.cracked) {
          _crack(canvas, left.right, 1, deck, thick);
          _crack(canvas, right.left, -1, deck, thick);
        }
    }
  }

  /// Two legs with a cross-brace and a cap, on a stone pier in the water.
  void _tower(Canvas canvas, double x, double h, double deck, double waterTop) {
    final top = h * _towerTop;
    final foot = waterTop + 8;
    final paint = Paint()..color = AppColors.rock;
    void outlined(Rect rect) {
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, _outline);
    }

    outlined(Rect.fromLTRB(x - 15, waterTop - 8, x + 15, foot));
    canvas.drawLine(
      Offset(x - 11, deck),
      Offset(x + 11, waterTop - 8),
      _outline,
    );
    canvas.drawLine(
      Offset(x + 11, deck),
      Offset(x - 11, waterTop - 8),
      _outline,
    );
    paint.color = AppColors.tower;
    for (final dx in const [-11.0, 11.0]) {
      outlined(Rect.fromLTRB(x + dx - 3.5, top, x + dx + 3.5, waterTop - 8));
    }
    outlined(Rect.fromLTRB(x - 14, top, x + 14, top + 5));
    outlined(
      Rect.fromLTRB(x - 11, (top + deck) / 2, x + 11, (top + deck) / 2 + 4),
    );
  }

  /// The main cables with their hangers, on both halves. They stay tied to
  /// the tower top, and their far ends follow the deck down by [angle].
  void _cables(Canvas canvas, double w, double deck, double angle) {
    final stroke = Paint()
      ..color = AppColors.cable
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final hanger = Paint()
      ..color = AppColors.cable
      ..strokeWidth = 1;
    final top = _towerTopY(deck);
    for (final (from, to, tilt) in [
      (w * _towerX, w * _deckEnd, angle),
      (w * (1 - _towerX), w * (1 - _deckEnd), -angle),
    ]) {
      final pivot = Offset(from, deck);
      Offset down(Offset point) {
        final d = point - pivot;
        return pivot +
            Offset(
              d.dx * cos(tilt) - d.dy * sin(tilt),
              d.dx * sin(tilt) + d.dy * cos(tilt),
            );
      }

      final mid = deck - 8.0;
      final start = Offset(from, top);
      final bend = down(Offset((from + to) / 2, mid + 4));
      final end = down(Offset(to, mid));
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy),
        stroke,
      );
      for (var t = 0.2; t < 1; t += 0.2) {
        final u = 1 - t;
        final point = start * (u * u) + bend * (2 * u * t) + end * (t * t);
        final foot = down(Offset(from + (to - from) * t, deck));
        canvas.drawLine(point, foot, hanger);
      }
    }
  }

  double _towerTopY(double deck) => deck * _towerTop / _deck;

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

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.state != state || old.fall != fall;
}

class _CarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()..color = AppColors.vehicle;
    final body = Path()
      ..moveTo(2, 18)
      ..quadraticBezierTo(0, 11, 8, 10)
      ..lineTo(14, 3)
      ..quadraticBezierTo(16, 1, 20, 1)
      ..lineTo(w - 18, 1)
      ..quadraticBezierTo(w - 15, 1, w - 13, 4)
      ..lineTo(w - 8, 10)
      ..quadraticBezierTo(w, 11, w, 18)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawPath(body, _outline);
    paint.color = AppColors.sky;
    canvas.drawPath(
      Path()
        ..moveTo(12, 10)
        ..lineTo(17, 4)
        ..lineTo(23, 4)
        ..lineTo(23, 10)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(26, 10)
        ..lineTo(26, 4)
        ..lineTo(w - 16, 4)
        ..lineTo(w - 11, 10)
        ..close(),
      paint,
    );
    paint.color = AppColors.ink;
    canvas.drawCircle(const Offset(11, 18), 4, paint);
    canvas.drawCircle(Offset(w - 11, 18), 4, paint);
    paint.color = AppColors.card;
    canvas.drawCircle(const Offset(11, 18), 1.5, paint);
    canvas.drawCircle(Offset(w - 11, 18), 1.5, paint);
  }

  @override
  bool shouldRepaint(_CarPainter old) => false;
}
