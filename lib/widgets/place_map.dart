import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

/// Place ids from north to south along the coast road.
const northToSouth = [
  'saud',
  'bangui',
  'burgos',
  'la_paz',
  'paoay',
  'pangil',
  'badoc',
];

/// [places] north to south; ids not in [northToSouth] follow in content order.
List<Place> mapOrder(List<Place> places) {
  int rank(Place place) {
    final i = northToSouth.indexOf(place.id);
    return i < 0 ? northToSouth.length : i;
  }

  // List.sort is not stable, so break ties by content order.
  final indexed = places.indexed.toList()
    ..sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, place) in indexed) place];
}

const _driveTime = Duration(milliseconds: 1600);
const _startY = 24.0;
const _firstStop = 70.0;
// Stops spread to fill the map's height, so every place shows at once; on a
// short screen they keep this much room for a four-line card and scroll.
const _maxStopGap = 100.0;
const _minStopGap = 56.0;
const _belowLast = 86.0; // room under the last stop for its card
const _pinRadius = 14.0;
const _cardWidth = 118.0;
const _cardGap = 6.0;
const _edge = 8.0;
const _carSize = Size(40, 20);

/// The coast road with one numbered stop per place. The student picks a
/// place, then "Drive to …" drives the car along the road to it and calls
/// [onChosen].
class PlaceMap extends StatefulWidget {
  const PlaceMap({super.key, required this.places, required this.onChosen});

  final List<Place> places;
  final ValueChanged<Place> onChosen;

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: _driveTime,
  );
  late final List<Place> _places = mapOrder(widget.places);
  Place? _selected;

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final place = _selected;
    if (place == null) return;
    await _drive.forward(from: 0);
    if (mounted) widget.onChosen(place);
  }

  /// Stop [i]: left of centre for even stops, right for odd ones.
  static Offset _stop(int i, double width, double gap) =>
      Offset(width * (i.isEven ? 0.38 : 0.64), _firstStop + i * gap);

  /// The road from START through every stop, and how far along it each is.
  static (Path, List<double>) _road(int count, double width, double gap) {
    final start = Offset(_stop(0, width, gap).dx, _startY);
    final path = Path()..moveTo(start.dx, start.dy);
    final distances = <double>[];
    var from = start;
    for (var i = 0; i < count; i++) {
      final to = _stop(i, width, gap);
      final bend = (to.dy - from.dy) / 2;
      path.cubicTo(from.dx, from.dy + bend, to.dx, to.dy - bend, to.dx, to.dy);
      distances.add(
        path.computeMetrics().fold(0.0, (sum, m) => sum + m.length),
      );
      from = to;
    }
    return (path, distances);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final driving = _drive.isAnimating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.land,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final steps = max(_places.length - 1, 1);
                final gap = ((box.maxHeight - _firstStop - _belowLast) / steps)
                    .clamp(_minStopGap, _maxStopGap);
                final (road, distances) = _road(_places.length, w, gap);
                final metric = road.computeMetrics().first;
                final height = _firstStop + steps * gap + _belowLast;
                return SingleChildScrollView(
                  child: SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _MapPainter(road)),
                        ),
                        for (final (i, place) in _places.indexed)
                          ..._stopWidgets(i, place, w, gap, selected, driving),
                        AnimatedBuilder(
                          animation: _drive,
                          builder: (context, car) {
                            final end = selected == null
                                ? 0.0
                                : distances[_places.indexOf(selected)];
                            final at = metric
                                .getTangentForOffset(
                                  end *
                                      Curves.easeInOut.transform(_drive.value),
                                )!
                                .position;
                            return Positioned(
                              left: at.dx - _carSize.width / 2,
                              top: at.dy - _carSize.height / 2,
                              child: car!,
                            );
                          },
                          child: IgnorePointer(
                            child: SvgPicture.asset(
                              'assets/images/car_small.svg',
                              width: _carSize.width,
                              height: _carSize.height,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: selected == null || driving ? null : _go,
          icon: SvgPicture.asset(
            'assets/images/car_small.svg',
            width: 34,
            height: 17,
            excludeFromSemantics: true,
          ),
          label: Text(
            selected == null ? 'Choose a place' : 'Drive to ${selected.name}',
          ),
        ),
      ],
    );
  }

  List<Widget> _stopWidgets(
    int i,
    Place place,
    double w,
    double gap,
    Place? selected,
    bool driving,
  ) {
    final at = _stop(i, w, gap);
    final onLeft = i.isEven;
    // The card sits on the outer side of its pin, as wide as there is room.
    final room = onLeft
        ? at.dx - _pinRadius - _cardGap - _edge
        : w - _edge - (at.dx + _pinRadius + _cardGap);
    final width = room.clamp(0.0, _cardWidth);
    return [
      Positioned(
        left: at.dx - _pinRadius,
        top: at.dy - _pinRadius,
        child: _Pin(number: i + 1),
      ),
      Positioned(
        left: onLeft ? at.dx - _pinRadius - _cardGap - width : null,
        right: onLeft ? null : w - (at.dx + _pinRadius + _cardGap + width),
        top: at.dy - 30,
        width: width,
        child: _PlaceCard(
          key: ValueKey('pin-${place.id}'),
          place: place,
          number: i + 1,
          selected: identical(place, selected),
          onTap: driving ? null : () => setState(() => _selected = place),
        ),
      ),
    ];
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: _pinRadius * 2,
      height: _pinRadius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.card,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    super.key,
    required this.place,
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final int number;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$number, ${place.name}',
    excludeSemantics: true,
    onTap: onTap,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.ink,
            width: selected ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/places/icons/${place.id}.svg',
              width: 54,
              height: 33,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox(height: 33),
            ),
            const SizedBox(height: 2),
            Text(
              place.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The sea along the west coast, the road and the START marker.
class _MapPainter extends CustomPainter {
  _MapPainter(this.road);

  final Path road;

  @override
  void paint(Canvas canvas, Size size) {
    final (w, h) = (size.width, size.height);
    final coast = w * 0.09;
    final sea = Path()..moveTo(0, 0);
    for (var y = 0.0; y <= h; y += 80) {
      sea.quadraticBezierTo(coast + 10, y + 40, coast, y + 80);
    }
    sea
      ..lineTo(0, h + 80)
      ..close();
    canvas.drawPath(sea, Paint()..color = AppColors.water);

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(road, stroke(AppColors.ink, 30))
      ..drawPath(road, stroke(AppColors.road, 25));

    final start = road.computeMetrics().first.getTangentForOffset(0)!.position;
    final label = TextPainter(
      text: const TextSpan(
        text: 'START',
        style: TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, start + Offset(20, -label.height / 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.road != road;
}
