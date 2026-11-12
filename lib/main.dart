import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';
import 'theme/app_them.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read SUPABASE_URL and SUPABASE_ANON_KEY from the .env file
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  }

  // Connect to Supabase before the app starts
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  // ProviderScope stores the state of all the Riverpod providers.
  runApp(const ProviderScope(child: MyApp()));
}

// entry of the app
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The router sends logged-out users to the login page.
    final appRouter = ref.watch(routerProvider);
    // Light / dark mode, switched with the button in the app bar.
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Book Shop',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
