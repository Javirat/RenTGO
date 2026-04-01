import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(fullName: _nameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Text(
                (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 8),
            Text(user?.phone ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            const SizedBox(height: 32),

            // Full name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.t('full_name'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Language selector
            DropdownButtonFormField<String>(
              initialValue: auth.language,
              decoration: InputDecoration(
                labelText: l.t('select_language'),
                prefixIcon: const Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'uz', child: Text("O'zbekcha")),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) auth.setLanguage(v);
              },
            ),
            const SizedBox(height: 16),

            // Role display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    user?.isLandlord == true ? Icons.home_work : Icons.person_search,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user?.isLandlord == true ? l.t('landlord') : l.t('renter'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
