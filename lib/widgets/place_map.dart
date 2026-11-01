import 'package:flutter/material.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

const _carSize = 32.0;
const _labelWidth = 120.0;

/// The map of places. Tapping a pin drives the car there, then calls
/// [onChosen]. The land is a plain panel until the map art exists.
class PlaceMap extends StatefulWidget {
  const PlaceMap({super.key, required this.places, required this.onChosen});

  final List<Place> places;
  final ValueChanged<Place> onChosen;

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  Place? _chosen;

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
              for (final place in widget.places)
                _Pin(
                  place: place,
                  width: w,
                  height: h,
                  chosen: identical(place, chosen),
                  onTap: chosen == null
                      ? () => setState(() => _chosen = place)
                      : null,
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                left: (chosen == null ? 0.06 : chosen.pinX) * w - _carSize / 2,
                top: (chosen == null ? 0.96 : chosen.pinY) * h - _carSize / 2,
                onEnd: () {
                  if (chosen != null) widget.onChosen(chosen);
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
    required this.width,
    required this.height,
    required this.chosen,
    required this.onTap,
  });

  final Place place;
  final double width;
  final double height;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onRight = place.pinX > 0.55;
    final label = SizedBox(
      width: _labelWidth,
      child: Text(
        place.name,
        textAlign: onRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
    final pin = Icon(
      Icons.location_on,
      size: 36,
      color: chosen ? AppColors.correct : AppColors.wrong,
    );
    return Positioned(
      left: onRight ? null : place.pinX * width - 18,
      right: onRight ? width - place.pinX * width - 18 : null,
      top: place.pinY * height - 36,
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
