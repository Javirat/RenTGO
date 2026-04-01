import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'phone_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work_rounded, size: 80, color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              const Text(
                'RenTGO',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'My Rent',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              Text(
                'Tilni tanlang / Выберите язык / Select language',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _LanguageButton(
                label: "O'zbekcha",
                flag: '🇺🇿',
                code: 'uz',
              ),
              const SizedBox(height: 12),
              _LanguageButton(
                label: 'Русский',
                flag: '🇷🇺',
                code: 'ru',
              ),
              const SizedBox(height: 12),
              _LanguageButton(
                label: 'English',
                flag: '🇬🇧',
                code: 'en',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final String flag;
  final String code;

  const _LanguageButton({
    required this.label,
    required this.flag,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          context.read<AuthProvider>().setLanguage(code);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
