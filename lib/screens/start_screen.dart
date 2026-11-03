import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../widgets/bridge_scene.dart';
import '../widgets/level_app_bar.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  Future<void> _showCredits(BuildContext context) async {
    final credits = await DefaultAssetBundle.of(context)
        .loadString('assets/content/credits.txt');
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => CreditsScreen(credits)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/images/scenes/clouds.svg',
              fit: BoxFit.fitWidth,
              excludeFromSemantics: true,
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: BridgeStrip()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 160),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 260,
                      semanticsLabel: 'BridgeIt logo',
                    ),
                    const SizedBox(height: 32),
                    Tooltip(
                      message: 'Play',
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 64),
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('Play'),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/welcome'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(140, 48),
                      ),
                      onPressed: () => _showCredits(context),
                      child: const Text('Credits'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The built Level 2 bridge along the bottom of a screen, with her car
/// driving across it. Under reduce motion the car waits by the left tower,
/// or on the far bank when [crossed].
class BridgeStrip extends StatelessWidget {
  const BridgeStrip({super.key, this.crossed = false});

  final bool crossed;

  @override
  Widget build(BuildContext context) =>
      BuiltBridge(crossed: crossed, looping: true);
}

/// The photo, music, word list and font sources, one card per group.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen(this.credits, {super.key});

  final String credits;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(child: SquareBackButton()),
        ),
        title: const Text(
          'Credits',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Close'),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final groups = credits
              .trim()
              .split(RegExp(r'\n\s*\n'))
              .where((g) => g.trim().isNotEmpty)
              .map((g) => g.trim().split('\n'))
              .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (groups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      groups.first.join(' '),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                for (final group in groups.skip(1))
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.first,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final line in group.skip(1))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
