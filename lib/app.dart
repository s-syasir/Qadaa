import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/stats_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/setup/welcome_screen.dart';
import 'ui/screens/setup/birth_year_screen.dart';
import 'ui/screens/setup/adjust_debt_screen.dart';
import 'ui/screens/setup/city_screen.dart';
import 'ui/screens/setup/method_screen.dart';

class QadaaApp extends ConsumerWidget {
  const QadaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installDate = ref.watch(installDateProvider);

    return MaterialApp(
      title: 'Qadaa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: installDate.when(
        data: (date) =>
            date == null ? const WelcomeScreen() : const HomeScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Startup error: $e')),
        ),
      ),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/setup/welcome': (_) => const WelcomeScreen(),
        '/setup/birth-year': (_) => const BirthYearScreen(),
        '/setup/adjust-debt': (_) => const AdjustDebtScreen(),
        '/setup/city': (_) => const CityScreen(),
        '/setup/method': (_) => const MethodScreen(),
        '/stats': (_) => const StatsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
