import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'content/content_repository.dart';
import 'content/models.dart';
import 'progress/progress_store.dart';
import 'screens/content_error_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent(rootBundle);
    runApp(
      BridgeItApp(
        content: content,
        progress: ProgressStore(prefs, content.unlockCodes),
      ),
    );
  } catch (error) {
    // A missing asset throws FlutterError, not ContentException.
    runApp(
      MaterialApp(
        theme: buildAppTheme(),
        home: ContentErrorScreen(
          message: error is ContentException
              ? error.message
              : 'Something went wrong while starting the game.\n$error',
        ),
      ),
    );
  }
}
