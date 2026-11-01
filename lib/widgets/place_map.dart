import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';
import '../theme/app_theme.dart';

const _carSize = 32.0;
const _labelWidth = 120.0;

/// The map of places. Tapping a pin drives the car there, then calls
/// [onChosen]. Pins sit on the road in `map.svg`, so move them together.
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
                left: (chosen == null ? 0.1 : chosen.pinX) * w - _carSize / 2,
                top: (chosen == null ? 0.05 : chosen.pinY) * h - _carSize / 2,
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
