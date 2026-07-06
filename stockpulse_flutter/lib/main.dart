import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  debugPrint("STP: Main initialization started...");
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("STP: .env loaded.");
  } catch (e) {
    debugPrint("STP ERROR: Could not load .env file: $e");
  }

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  debugPrint("STP: Hive initialized.");

  // Initialize Supabase with variables from .env
  try {
    debugPrint("STP: Initializing Supabase...");
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL', fallback: ''),
      anonKey: dotenv.get('SUPABASE_SERVICE_ROLE_KEY', fallback: dotenv.get('SUPABASE_ANON_KEY', fallback: '')),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint("STP: Supabase initialization timed out!");
      throw 'Initialization Timeout';
    });
    debugPrint("STP: Supabase initialized.");
  } catch (e) {
    debugPrint("STP ERROR: Supabase init failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PortfolioProvider>(
          create: (_) => PortfolioProvider(),
          update: (_, auth, portfolio) => portfolio!..updateAuth(auth),
        ),
      ],
      child: const StockPulseApp(),
    ),
  );
  debugPrint("STP: runApp called.");
}

class StockPulseApp extends StatelessWidget {
  const StockPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'StockPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const SplashScreen();
          }
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
