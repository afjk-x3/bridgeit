import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'content/models.dart';
import 'progress/progress_store.dart';
import 'screens/intro_screen.dart';
import 'screens/level1_screen.dart';
import 'screens/level2_screen.dart';
import 'screens/level3_screen.dart';
import 'screens/level_menu_screen.dart';
import 'theme/app_theme.dart';

class BridgeItApp extends StatelessWidget {
  const BridgeItApp({super.key, required this.content, required this.progress});

  final GameContent content;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameContent>.value(value: content),
        ChangeNotifierProvider<ProgressStore>.value(value: progress),
      ],
      child: MaterialApp(
        title: 'BridgeIt',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routes: {
          '/': (_) => const IntroScreen(),
          '/levels': (_) => const LevelMenuScreen(),
          '/level/1': (_) => const Level1Screen(),
          '/level/2': (_) => const Level2Screen(),
          '/level/3': (_) => const Level3Screen(),
        },
      ),
    );
  }
}
