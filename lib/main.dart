import 'package:flutter/material.dart';
import 'routing/app_router.dart';
import 'theme/app_them.dart';

void main() {
  runApp(const MyApp());
}

// App entry widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Anime/Movies Backlog',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
