import 'package:flutter/material.dart';
import 'routing/app_router.dart';
import 'theme/app_them.dart';

void main() {
  runApp(const MyApp());
}

// entry of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // theme toggle (Light / Dark mode)
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Shop App',
          // theme configurations
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: currentThemeMode,
          //  loads homescreen
          routerConfig: appRouter,
        );
      },
    );
  }
}
