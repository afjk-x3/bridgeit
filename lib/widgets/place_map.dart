import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

const _carSize = 32.0;
const _labelWidth = 120.0;
const _driveTime = Duration(milliseconds: 1600);
const _mapSize = Size(300, 420);

/// The road in `map.svg`, in its view box. Keep the two the same.
final _road =
    (Path()
          ..moveTo(30, 21)
          ..cubicTo(120, 8, 196, 28, 216, 84)
          ..cubicTo(232, 132, 120, 104, 105, 139)
          ..cubicTo(92, 172, 250, 158, 210, 197)
          ..cubicTo(180, 230, 100, 186, 90, 218)
          ..cubicTo(78, 252, 28, 258, 36, 294)
          ..cubicTo(44, 340, 150, 300, 186, 353)
          ..cubicTo(200, 376, 232, 392, 246, 412))
        .computeMetrics()
        .first;

/// The point [distance] along the road, in `map.svg` units.
Offset roadPoint(double distance) =>
    _road.getTangentForOffset(distance)!.position;

/// How far along the road its closest point to [point] is.
double roadDistanceTo(Offset point) {
  var best = 0.0;
  var bestGap = double.infinity;
  for (var d = 0.0; d <= _road.length; d += 2) {
    final gap = (roadPoint(d) - point).distanceSquared;
    if (gap < bestGap) (best, bestGap) = (d, gap);
  }
  return best;
}

/// The map of places. Pins snap to the road; tapping one drives the car along
/// the road to it, then calls [onChosen].
class PlaceMap extends StatefulWidget {
  const PlaceMap({super.key, required this.places, required this.onChosen});

  final List<Place> places;
  final ValueChanged<Place> onChosen;

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  Place? _chosen;

  double _distance(Place place) => roadDistanceTo(
    Offset(place.pinX * _mapSize.width, place.pinY * _mapSize.height),
  );

  Offset _stop(Place place) => roadPoint(_distance(place));

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final (w, h) = (box.maxWidth, box.maxHeight);
          final chosen = _chosen;
          return Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/map.svg',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
              for (final place in widget.places)
                _Pin(
                  place: place,
                  x: _stop(place).dx * w / _mapSize.width,
                  y: _stop(place).dy * h / _mapSize.height,
                  width: w,
                  chosen: identical(place, chosen),
                  onTap: chosen == null
                      ? () => setState(() => _chosen = place)
                      : null,
                ),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: chosen == null ? 0 : _distance(chosen),
                ),
                duration: _driveTime,
                curve: Curves.easeInOut,
                onEnd: () {
                  if (chosen != null) widget.onChosen(chosen);
                },
                builder: (context, distance, car) {
                  final at = roadPoint(distance);
                  return Positioned(
                    left: at.dx * w / _mapSize.width - _carSize / 2,
                    top: at.dy * h / _mapSize.height - _carSize / 2,
                    child: car!,
                  );
                },
                child: const IgnorePointer(
                  child: Icon(
                    Icons.directions_car,
                    size: _carSize,
                    color: AppColors.vehicle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.place,
    required this.x,
    required this.y,
    required this.width,
    required this.chosen,
    required this.onTap,
  });

  final Place place;
  final double x;
  final double y;
  final double width;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onRight = place.pinX > 0.55;
    final label = Container(
      constraints: const BoxConstraints(maxWidth: _labelWidth),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        place.name,
        textAlign: onRight ? TextAlign.right : TextAlign.left,
        textWidthBasis: TextWidthBasis.longestLine,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
    final pin = Icon(
      Icons.location_on,
      size: 36,
      color: chosen ? AppColors.correct : AppColors.wrong,
    );
    return Positioned(
      left: onRight ? null : x - 18,
      right: onRight ? width - x - 18 : null,
      top: y - 36,
      child: Semantics(
        button: true,
        label: place.name,
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('pin-${place.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: onRight ? [label, pin] : [pin, label],
          ),
        ),
      ),
    );
  }
}
