import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'journey_sheet.dart';

/// The bar on every level screen: back, the level's name and the map icon.
AppBar levelAppBar(BuildContext context, int level, String title) {
  return AppBar(
    automaticallyImplyLeading: false,
    leadingWidth: 72,
    leading: const Padding(
      padding: EdgeInsets.only(left: 16),
      child: Center(child: SquareBackButton()),
    ),
    titleSpacing: 12,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEVEL $level',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    ),
    actions: const [
      Padding(padding: EdgeInsets.only(right: 16), child: JourneyButton()),
    ],
  );
}

/// The teal back square used on every screen with a way back.
class SquareBackButton extends StatelessWidget {
  const SquareBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.lightTeal,
      foregroundColor: AppColors.ink,
      fixedSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const Icon(Icons.chevron_left, size: 28),
    onPressed: () => Navigator.maybePop(context),
  );
}
