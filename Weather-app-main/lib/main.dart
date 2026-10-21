import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Any uncaught error is logged instead of crashing the app.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter error caught: ${details.exceptionAsString()}');
    };

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      debugPrint('No .env file found or failed to parse. Relying on default settings.');
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => WeatherProvider(),
        child: const AtmosphereApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
  });
}

class AtmosphereApp extends StatelessWidget {
  const AtmosphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        ThemeMode themeMode;
        switch (provider.themeMode) {
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          case 'light':
            themeMode = ThemeMode.light;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'Atmosphere Weather',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: false,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: false,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
