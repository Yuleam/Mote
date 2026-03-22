import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const PurlApp());
}

class PurlApp extends StatelessWidget {
  const PurlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Pretendard',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Pretendard',
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.bg,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.gowunBatang(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          ),
        ),
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _onboarded = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService().isLoggedIn();
    final onboarded = await AuthService().isOnboarded();
    setState(() {
      _loggedIn = loggedIn;
      _onboarded = onboarded;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (!_loggedIn) {
      return AuthScreen(
        onAuth: () {
          setState(() => _loggedIn = true);
        },
      );
    }

    if (!_onboarded) {
      return OnboardingScreen(
        onComplete: () {
          setState(() => _onboarded = true);
        },
      );
    }

    return const HomeScreen();
  }
}
