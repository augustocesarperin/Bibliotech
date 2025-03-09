import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/camera_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<CameraService>(
          create: (_) => CameraService(),
          dispose: (_, cameraService) => cameraService.dispose(),
        ),
        ChangeNotifierProxyProvider<ApiService, AuthService>(
          create: (context) => AuthService(
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, api, previous) => 
            previous ?? AuthService(api),
        ),
      ],
      child: const BibliotecaApp(),
    ),
  );
}

class BibliotecaApp extends StatelessWidget {
  const BibliotecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );
    
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Gerenciamento de Livros com IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      home: Consumer<AuthService>(
        builder: (ctx, auth, _) {
          if (auth.estaCarregando) return const SplashScreen();
          
          if (auth.estaAutenticado) return const HomeScreen();
          
          return const LoginScreen();
        },
      ),
    );
  }
}
