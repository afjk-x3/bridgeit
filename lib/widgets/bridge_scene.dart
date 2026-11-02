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

// The scene is drawn in a 390 x 232 box (the Wireframes v3 Bridge sheet) and
// scaled to fit. Widgets on top use the same units.
const _size = Size(390, 232);
const _deckTop = 108.0; // the road surface, where the car's wheels sit
const _slabTop = 118.0; // the clause slab, 58 high
const _slabBottom = 176.0;
const _trussBottom = 194.0;
const _halfEnd = 150.0; // where the left half of a split deck stops
const _pierX = {1: 122.0, 2: 268.0};
const _pierWidth = 48.0;
const _norPierWidth = 64.0;
const _gapSize = Size(72, 48);
const _carSize = Size(46, 22);
const _fallTime = Duration(milliseconds: 500);
const _fallAngle = 0.35; // how far a broken deck tilts (radians)
const _shakeTime = Duration(milliseconds: 1200);
const _carFallTime = Duration(milliseconds: 1400);
const _carRestY = 222.0; // where the fallen car comes to rest in the river
const _carStart = 90.0; // just right of the left tower
const _carEnd = 300.0; // just left of the right tower
final _outline = Paint()
  ..color = AppColors.ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;

/// One accepted sentence, standing under the deck as a pier tagged with the
/// [word] it used.
class BridgePier {
  const BridgePier(this.word, this.sentence);

  final String word;
  final String sentence;
}

/// The suspension bridge over water. The clauses sit on the deck either side
/// of the [gap]; each of the student's [piers] stands under the deck, and the
/// deck shakes until [piersNeeded] are in. The car drives to the far bank
/// when [crossed].
class BridgeScene extends StatelessWidget {
  const BridgeScene({
    super.key,
    required this.state,
    required this.left,
    required this.right,
    required this.gap,
    this.placedWord,
    this.piers = const [],
    this.piersNeeded = 2,
    this.cracks = 0,
    this.crossed = false,
    this.onCrossed,
  });

  final BridgeState state;
  final String left;
  final String right;

  /// Shown in the bridge once it is built.
  final String? placedWord;

  /// Fills the slot over the missing bridge section while the bridge is open.
  final Widget gap;

  final List<BridgePier> piers;
  final int piersNeeded;

  /// Wrong tries so far: the first cracks the left tower support, the second
  /// the right one.
  final int cracks;
  final bool crossed;

  /// Called when the vehicle reaches the far cliff.
  final VoidCallback? onCrossed;

  double get _amplitude {
    if (state != BridgeState.built || piers.length >= piersNeeded) return 0;
    return piers.isEmpty ? 1 : 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final complete = state == BridgeState.built;
    final word = placedWord;
    // The piece carries the comma, so the deck shows the clause without it.
    final clause = left.endsWith(',')
        ? left.substring(0, left.length - 1)
        : left;
    final sentence = complete && word != null
        ? '$clause, $word $right'
        : '$clause, _____ $right';
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _size.width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: _size.width / _size.height,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: _labels[state],
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final s = box.maxWidth / _size.width;
                      Rect at(double l, double t, double w, double h) =>
                          Rect.fromLTWH(l * s, t * s, w * s, h * s);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BackPainter(complete, cracks),
                            ),
                          ),
                          for (final (i, side) in const [
                            'Left',
                            'Right',
                          ].indexed)
                            if (cracks > i)
                              Positioned.fromRect(
                                rect: at(
                                  i == 0 ? 50 : 296,
                                  _trussBottom,
                                  44,
                                  _size.height - _trussBottom,
                                ),
                                child: Semantics(
                                  label: '$side support cracked',
                                ),
                              ),
                          for (final (i, pier) in piers.indexed)
                            _pier(i + 1, pier, s),
                          Positioned.fill(
                            child: BridgeWobble(
                              key: const ValueKey('wobble'),
                              amplitude: _amplitude,
                              child: Stack(
                                key: const ValueKey('deck-layer'),
                                children: [
                                  Positioned.fill(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0,
                                        end: state == BridgeState.broken
                                            ? 1
                                            : 0,
                                      ),
                                      duration: _fallTime,
                                      curve: Curves.easeIn,
                                      builder: (context, fall, _) =>
                                          CustomPaint(
                                            painter: _DeckPainter(state, fall),
                                          ),
                                    ),
                                  ),
                                  if (state != BridgeState.broken)
                                    Positioned.fromRect(
                                      rect: at(
                                        0,
                                        _slabTop,
                                        _size.width,
                                        _slabBottom - _slabTop,
                                      ),
                                      child: Semantics(
                                        label: sentence,
                                        excludeSemantics: true,
                                        child: Row(
                                          children: [
                                            _DeckClause(
                                              clause,
                                              width: _halfEnd * s,
                                            ),
                                            const Spacer(),
                                            _DeckClause(
                                              right,
                                              width: _halfEnd * s,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (state != BridgeState.broken)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top:
                                          (_slabTop + _slabBottom) / 2 * s -
                                          _gapSize.height / 2,
                                      child: Center(
                                        child: SizedBox.fromSize(
                                          size: _gapSize,
                                          child: complete && word != null
                                              ? _PlacedWord(word)
                                              : gap,
                                        ),
                                      ),
                                    ),
                                  _car(s, box.maxWidth),
                                ],
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
            if (piers.isNotEmpty) _Caption(piers),
          ],
        ),
      ),
    );
  }

  Widget _pier(int n, BridgePier pier, double s) {
    final single = piersNeeded == 1;
    final cx = single ? _size.width / 2 : _pierX[n] ?? _pierX[2]!;
    final width = (single ? _norPierWidth : _pierWidth) * s;
    return Positioned(
      left: cx * s - width / 2,
      top: _trussBottom * s,
      width: width,
      height: (_size.height - _trussBottom) * s,
      child: Container(
        key: ValueKey('pier-$n'),
        decoration: BoxDecoration(
          color: AppColors.stone,
          border: Border.all(color: AppColors.ink, width: 3),
        ),
        // The tag may be wider than its pier.
        child: OverflowBox(
          maxWidth: 160,
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$n · ${pier.word}',
              style: const TextStyle(
                color: AppColors.card,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _car(double s, double width) => Positioned(
    left: 0,
    right: 0,
    top: _slabTop * s - _carSize.height,
    height: _carSize.height,
    child: IgnorePointer(
      // The car drives between the towers, on the deck.
      child: Padding(
        padding: EdgeInsets.only(
          left: (_carStart) * s,
          right: (_size.width - _carEnd) * s,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          onEnd: onCrossed,
          alignment: Alignment(crossed ? 1 : -1, 0),
          // When the bridge collapses the car rolls to the broken edge and
          // falls into the river.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: state == BridgeState.broken ? 1 : 0),
            duration: _carFallTime,
            builder: (context, t, car) {
              final roll = (t / 0.4).clamp(0.0, 1.0);
              final fall = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(
                  roll * (_halfEnd - _carStart - _carSize.width / 2) * s,
                  Curves.easeIn.transform(fall) * (_carRestY - _deckTop) * s,
                ),
                child: Transform.rotate(angle: fall * 0.9, child: car),
              );
            },
            child: Semantics(
              label: state == BridgeState.broken
                  ? 'The car fell into the river'
                  : null,
              child: CustomPaint(
                key: const ValueKey('bridge-car'),
                size: _carSize,
                painter: _CarPainter(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shakes [child] by up to 2 px times [amplitude]; still when animations are
/// off, a screen reader is on (moving nodes unsettle its focus), or
/// [amplitude] is 0.
class BridgeWobble extends StatefulWidget {
  const BridgeWobble({super.key, required this.amplitude, required this.child});

  final double amplitude;
  final Widget child;

  @override
  State<BridgeWobble> createState() => _BridgeWobbleState();
}

class _BridgeWobbleState extends State<BridgeWobble>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: _shakeTime);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BridgeWobble old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final moving =
        widget.amplitude > 0 &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (moving && !_clock.isAnimating) _clock.repeat();
    if (!moving && _clock.isAnimating) _clock.reset();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, child) {
      final shake = sin(_clock.value * 2 * pi) * 2 * widget.amplitude;
      return Transform.translate(
        offset: Offset(shake, shake / 2),
        child: child,
      );
    },
    child: widget.child,
  );
}

/// One clause written on its half of the deck slab.
class _DeckClause extends StatelessWidget {
  const _DeckClause(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.card,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ),
    ),
  );
}

class _PlacedWord extends StatelessWidget {
  const _PlacedWord(this.word);

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('placed-word'),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.correct, width: 3),
      ),
      // The piece keeps its comma once the bridge is built.
      child: Text(
        ', $word',
        style: const TextStyle(
          color: AppColors.cliff,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The student's sentences in full, numbered to match their piers.
class _Caption extends StatelessWidget {
  const _Caption(this.piers);

  final List<BridgePier> piers;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('pier-caption'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, pier) in piers.indexed)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${i + 1}  ',
                    style: const TextStyle(color: AppColors.lightTeal),
                  ),
                  TextSpan(text: pier.sentence),
                ],
              ),
              style: const TextStyle(
                color: AppColors.card,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

/// Everything that stays still: river, banks, cables, towers and footings.
class _BackPainter extends CustomPainter {
  _BackPainter(this.whole, this.cracks);

  /// The deck is joined, so one cable spans the river.
  final bool whole;

  /// How many tower supports are cracked, left first.
  final int cracks;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _size.width);
    final (w, h) = (_size.width, _size.height);
    final fill = Paint();
    final line = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fill..color = AppColors.sky);
    fill.color = AppColors.card;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(190, 30), width: 56, height: 18),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(206, 24), width: 32, height: 16),
      fill,
    );

    final hill = Path()
      ..moveTo(0, 170)
      ..quadraticBezierTo(80, 140, 160, 160)
      ..quadraticBezierTo(240, 136, 320, 158)
      ..quadraticBezierTo(360, 146, w, 160)
      ..lineTo(w, 200)
      ..lineTo(0, 200)
      ..close();
    canvas.drawPath(hill, fill..color = AppColors.lightTeal);
    canvas.drawPath(hill, line..strokeWidth = 2);
    canvas.drawRect(
      Rect.fromLTWH(0, 196, w, h - 196),
      fill..color = AppColors.water,
    );

    // Stone bank walls with grassy tops.
    for (final wall in [
      Path()..addPolygon([
        const Offset(0, 96),
        const Offset(30, 96),
        Offset(38, h),
        Offset(0, h),
      ], true),
      Path()..addPolygon([
        Offset(w, 96),
        Offset(w - 30, 96),
        Offset(w - 38, h),
        Offset(w, h),
      ], true),
    ]) {
      canvas.drawPath(wall, fill..color = AppColors.stone);
      canvas.drawPath(wall, line..strokeWidth = 3);
    }
    for (final cap in [
      const Rect.fromLTWH(0, 92, 32, 8),
      Rect.fromLTWH(w - 32, 92, 32, 8),
    ]) {
      canvas.drawRect(cap, fill..color = AppColors.lightTeal);
      canvas.drawRect(cap, line..strokeWidth = 2);
    }

    final cables = Path()
      ..moveTo(72, 10)
      ..quadraticBezierTo(40, 70, 0, 92)
      ..moveTo(318, 10)
      ..quadraticBezierTo(350, 70, w, 92);
    if (whole) {
      cables
        ..moveTo(72, 10)
        ..quadraticBezierTo(195, 112, 318, 10);
    } else {
      cables
        ..moveTo(72, 10)
        ..quadraticBezierTo(120, 100, _halfEnd, _deckTop)
        ..moveTo(318, 10)
        ..quadraticBezierTo(270, 100, w - _halfEnd, _deckTop);
    }
    canvas.drawPath(cables, line..strokeWidth = 3);
    line.strokeWidth = 1.5;
    for (final (x, top) in const [
      (96.0, 28.0),
      (116.0, 40.0),
      (136.0, 49.0),
      (254.0, 49.0),
      (274.0, 40.0),
      (294.0, 28.0),
      (40.0, 64.0),
      (350.0, 64.0),
    ]) {
      canvas.drawLine(
        Offset(x, top),
        const Offset(0, _slabTop).translate(x, 0),
        line,
      );
    }

    // Towers, then their footings in the river.
    for (final (i, x) in const [58.0, 304.0].indexed) {
      final tower = Rect.fromLTWH(x, 6, 28, 190);
      canvas.drawRect(tower, fill..color = AppColors.tower);
      canvas.drawRect(tower, line..strokeWidth = 3);
      line.strokeWidth = 2;
      canvas.drawLine(Offset(x, 40), Offset(x + 28, 70), line);
      canvas.drawLine(Offset(x + 28, 40), Offset(x, 70), line);
      canvas.drawRect(
        Rect.fromLTWH(x - 4, 2, 36, 8),
        fill..color = AppColors.ink,
      );
      final footing = Rect.fromLTWH(x - 8, _trussBottom, 44, h - _trussBottom);
      canvas.drawRect(footing, fill..color = AppColors.stone);
      canvas.drawRect(footing, line..strokeWidth = 3);
      if (cracks > i) _crack(canvas, footing);
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) =>
      old.whole != whole || old.cracks != cracks;

  /// A jagged split down the support, with a chip knocked out of its top.
  void _crack(Canvas canvas, Rect footing) {
    final c = footing.center.dx;
    final top = footing.top;
    final crack = Path()
      ..moveTo(c - 4, top)
      ..lineTo(c + 5, top + 8)
      ..lineTo(c - 3, top + 16)
      ..lineTo(c + 6, top + 26)
      ..lineTo(c, footing.bottom)
      ..moveTo(c - 3, top + 16)
      ..lineTo(c - 14, top + 22);
    canvas.drawPath(
      Path()
        ..moveTo(footing.right - 12, top)
        ..lineTo(footing.right, top)
        ..lineTo(footing.right, top + 10)
        ..close(),
      Paint()..color = AppColors.water,
    );
    canvas.drawPath(
      crack,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }
}

/// The deck: whole once built, split with jagged ends while open, and tilting
/// into the river by [fall] when broken.
class _DeckPainter extends CustomPainter {
  _DeckPainter(this.state, this.fall);

  final BridgeState state;
  final double fall;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _size.width);
    final w = _size.width;
    final fill = Paint()..color = AppColors.deck;
    final line = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    void draw(Path path) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }

    // The road line and its railings.
    final road = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3;
    if (state == BridgeState.built) {
      canvas.drawLine(const Offset(0, _deckTop), Offset(w, _deckTop), road);
      _posts(canvas, 0, w);
      draw(Path()..addRect(Rect.fromLTRB(0, _slabTop, w, _slabBottom)));
      draw(Path()..addRect(Rect.fromLTRB(0, _slabBottom, w, _trussBottom)));
      _truss(canvas, 0, w);
      return;
    }

    final angle = state == BridgeState.broken ? _fallAngle * fall : 0.0;
    for (final (side, pivot) in [(1.0, 72.0), (-1.0, 318.0)]) {
      canvas.save();
      canvas.translate(pivot, _deckTop);
      canvas.rotate(angle * side);
      canvas.translate(-pivot, -_deckTop);
      // Mirror the right half onto the left half's shape.
      if (side < 0) {
        canvas.translate(w, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawLine(
        const Offset(0, _deckTop),
        const Offset(_halfEnd, _deckTop),
        road,
      );
      _posts(canvas, 0, _halfEnd);
      draw(
        Path()
          ..moveTo(0, _slabTop)
          ..lineTo(_halfEnd, _slabTop)
          ..lineTo(_halfEnd - 6, 134)
          ..lineTo(_halfEnd + 2, 150)
          ..lineTo(_halfEnd - 6, 166)
          ..lineTo(_halfEnd, _slabBottom)
          ..lineTo(0, _slabBottom)
          ..close(),
      );
      draw(
        Path()
          ..moveTo(0, _slabBottom)
          ..lineTo(_halfEnd, _slabBottom)
          ..lineTo(_halfEnd - 4, _trussBottom)
          ..lineTo(0, _trussBottom)
          ..close(),
      );
      _truss(canvas, 0, _halfEnd - 6);
      canvas.restore();
    }

    // Rubble in the gap, and splashes where it fell.
    for (final stone in [
      [
        const Offset(168, 204),
        const Offset(182, 200),
        const Offset(186, 210),
        const Offset(172, 214),
      ],
      [
        const Offset(206, 214),
        const Offset(218, 216),
        const Offset(216, 226),
        const Offset(204, 224),
      ],
    ]) {
      draw(Path()..addPolygon(stone, true));
    }
    final splash = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final x in const [160.0, 200.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 228)
          ..quadraticBezierTo(x + 10, 218, x + 20, 228),
        splash,
      );
    }
  }

  /// Railing posts holding the rail up off the deck.
  void _posts(Canvas canvas, double from, double to) {
    final post = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2;
    for (var x = from + 12; x < to; x += 18) {
      canvas.drawLine(Offset(x, _deckTop), Offset(x, _slabTop), post);
    }
  }

  void _truss(Canvas canvas, double from, double to) {
    final zig = Path()..moveTo(from, _trussBottom);
    var up = true;
    for (var x = from + 12; x <= to; x += 12, up = !up) {
      zig.lineTo(x, up ? _slabBottom : _trussBottom);
    }
    canvas.drawPath(
      zig,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DeckPainter old) =>
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
