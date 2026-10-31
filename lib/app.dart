import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'content/models.dart';
import 'progress/progress_store.dart';
import 'progress/results_store.dart';
import 'screens/level2_screen.dart';
import 'screens/level_menu_screen.dart';
import 'screens/level_stub_screen.dart';
import 'screens/start_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

class BridgeItApp extends StatelessWidget {
  const BridgeItApp({
    super.key,
    required this.content,
    required this.progress,
    required this.results,
  });

  final GameContent content;
  final ProgressStore progress;
  final ResultsStore results;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameContent>.value(value: content),
        ChangeNotifierProvider<ProgressStore>.value(value: progress),
        ChangeNotifierProvider<ResultsStore>.value(value: results),
      ],
      child: MaterialApp(
        title: 'BridgeIt',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routes: {
          '/': (_) => const StartScreen(),
          '/welcome': (_) => const WelcomeScreen(),
          '/levels': (_) => const LevelMenuScreen(),
          '/level/1': (_) => const LevelStubScreen(level: 1),
          '/level/2': (_) => const Level2Screen(),
          '/level/3': (_) => const LevelStubScreen(level: 3),
        },
      ),
    );
  }
}
