import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'phone_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.r28),
                    ),
                    child: const Icon(Icons.home_work_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'RentGO',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'My Rent',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Text(
                    'Tilni tanlang / Выберите язык / Select language',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _LangBtn(flag: '🇺🇿', label: "O'zbekcha", code: 'uz', isDark: isDark),
                  const SizedBox(height: 10),
                  _LangBtn(flag: '🇷🇺', label: 'Русский', code: 'ru', isDark: isDark),
                  const SizedBox(height: 10),
                  _LangBtn(flag: '🇬🇧', label: 'English', code: 'en', isDark: isDark),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String flag, label, code;
  final bool isDark;

  const _LangBtn({required this.flag, required this.label, required this.code, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.r16),
        onTap: () {
          context.read<AuthProvider>().setLanguage(code);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneScreen()));
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios_rounded, size: 14,
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
