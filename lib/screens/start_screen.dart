import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../progress/results_store.dart';
import '../theme/app_theme.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 260,
                semanticsLabel: 'BridgeIt logo',
              ),
              const SizedBox(height: 24),
              IconButton.filled(
                tooltip: 'Play',
                iconSize: 36,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightTeal,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(112, 56),
                ),
                icon: const Icon(Icons.play_arrow),
                onPressed: () => Navigator.pushNamed(
                  context,
                  context.read<ResultsStore>().profile == null
                      ? '/welcome'
                      : '/levels',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
