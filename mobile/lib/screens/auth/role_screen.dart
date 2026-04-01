import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.t('select_role'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.person_search,
                label: l.t('renter'),
                description: auth.language == 'uz'
                    ? 'Ijara uchun uy/mashina qidiraman'
                    : auth.language == 'ru'
                        ? 'Ищу жильё/машину в аренду'
                        : 'Looking for property to rent',
                onTap: () => _selectRole(context, 'renter'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.home_work,
                label: l.t('landlord'),
                description: auth.language == 'uz'
                    ? 'Uy/mashina ijaraga beraman'
                    : auth.language == 'ru'
                        ? 'Сдаю жильё/машину в аренду'
                        : 'I want to rent out my property',
                onTap: () => _selectRole(context, 'landlord'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String role) async {
    await context.read<AuthProvider>().updateProfile(role: role);
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
