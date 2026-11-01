import 'package:flutter/material.dart';

import 'journey_sheet.dart';

/// The bar on every level screen: back, the level's name and the map icon.
AppBar levelAppBar(BuildContext context, int level, String title) {
  final text = Theme.of(context).textTheme;
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LEVEL $level', style: text.labelLarge),
        Text(
          title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
    actions: const [JourneyButton()],
  );
}
