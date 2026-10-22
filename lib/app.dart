import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_theme.dart';

class BridgeItApp extends StatelessWidget {
  const BridgeItApp({super.key, this.home});

  /// Replaced by named routes in Task 4.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgeIt',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home ?? const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo_placeholder.svg',
              width: 230,
              semanticsLabel: 'BridgeIt lotus logo',
            ),
            const SizedBox(height: 8),
            Text('BridgeIt', style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
    );
  }
}
