import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown by `main()` when the game content cannot be loaded.
class ContentErrorScreen extends StatelessWidget {
  const ContentErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.wrong,
                ),
                const SizedBox(height: 16),
                Text(
                  "BridgeIt couldn't load its levels.",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
