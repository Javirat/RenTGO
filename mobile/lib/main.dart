import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/property_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/language_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const RenTGOApp());
}

class RenTGOApp extends StatelessWidget {
  const RenTGOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<ThemeProvider>().init();
    await context.read<AuthProvider>().init();
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'RenTGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.themeMode,
      home: !_initialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isLoggedIn
              ? const HomeScreen()
              : const LanguageScreen(),
    );
  }
}
