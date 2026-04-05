import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_screen.dart';
import '../auth/language_screen.dart';
import '../home/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: context.read<AuthProvider>().user?.fullName ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(fullName: _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Saved'), backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        return;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating));
    } finally { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(children: [
        const SizedBox(height: 12),
        // Avatar
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.r28)),
          child: Center(child: Text(
            (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(height: 10),
        Text(_formatPhone(user?.phone ?? ''), style: GoogleFonts.inter(
            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary, fontSize: 15)),
        const SizedBox(height: 28),
        // Name
        _FieldLabel(l.t('full_name')),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(hintText: l.t('full_name'),
              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary)),
        ),
        const SizedBox(height: 18),
        // Language
        _FieldLabel(l.t('select_language')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: auth.language,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.language_rounded, color: AppTheme.primary)),
          items: const [
            DropdownMenuItem(value: 'uz', child: Text("O'zbekcha")),
            DropdownMenuItem(value: 'ru', child: Text('Русский')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) { if (v != null) auth.setLanguage(v); },
        ),
        const SizedBox(height: 18),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(l.t('save'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 16),
        // Logout
        SizedBox(width: double.infinity, height: 56, child: OutlinedButton.icon(
          onPressed: () {
            auth.logout();
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LanguageScreen()), (_) => false);
          },
          icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
          label: Text(l.t('logout'), style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.danger)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r16)),
          ),
        )),
      ]),
    );

    if (widget.embedded) {
      return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(l.t('profile'),
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
        ),
        Expanded(child: content),
      ]));
    }
    return Scaffold(appBar: AppBar(title: Text(l.t('profile'))), body: content);
  }
}

String _formatPhone(String phone) {
  final p = phone.replaceAll('+', '').replaceAll(' ', '');
  if (p.length == 12) {
    return '+${p.substring(0, 3)} ${p.substring(3, 5)} ${p.substring(5, 8)} ${p.substring(8, 10)} ${p.substring(10)}';
  }
  return phone;
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)));
}
