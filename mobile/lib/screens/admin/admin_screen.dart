import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_directories_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = admin.stats;

    return Scaffold(
      body: SafeArea(
        child: admin.loading && s.isEmpty
            ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => admin.loadDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Row(children: [
                      Expanded(child: Text(l.t('admin_panel'),
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1))),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                        ),
                        child: Text('ADMIN', style: GoogleFonts.inter(
                            color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Stats
                    Text(l.t('dashboard'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Row(children: [
                      _Stat(label: l.t('users'), value: '${s['total_users'] ?? 0}',
                          icon: Icons.people_rounded, color: AppTheme.primary, isDark: isDark),
                      const SizedBox(width: 10),
                      _Stat(label: l.t('listings'), value: '${s['total_properties'] ?? 0}',
                          icon: Icons.home_work_rounded, color: AppTheme.secondary, isDark: isDark),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _Stat(label: l.t('active'), value: '${s['active_properties'] ?? 0}',
                          icon: Icons.check_circle_rounded, color: AppTheme.info, isDark: isDark),
                      const SizedBox(width: 10),
                      _Stat(label: l.t('total_views'), value: '${s['total_views'] ?? 0}',
                          icon: Icons.visibility_rounded, color: AppTheme.warning, isDark: isDark),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _Stat(label: l.t('messages'), value: '${s['total_messages'] ?? 0}',
                          icon: Icons.chat_bubble_rounded, color: AppTheme.danger, isDark: isDark),
                      const SizedBox(width: 10),
                      _Stat(label: l.t('chats'), value: '${s['total_conversations'] ?? 0}',
                          icon: Icons.forum_rounded, color: AppTheme.primary, isDark: isDark),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _Stat(label: l.t('regular_users'), value: '${s['total_regular_users'] ?? 0}',
                          icon: Icons.person_rounded, color: AppTheme.info, isDark: isDark),
                      const SizedBox(width: 10),
                      _Stat(label: l.t('admins'), value: '${s['total_admins'] ?? 0}',
                          icon: Icons.admin_panel_settings_rounded, color: AppTheme.secondary, isDark: isDark),
                    ]),

                    const SizedBox(height: 28),
                    Text(l.t('management'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),

                    // Menu
                    _MenuCard(
                      icon: Icons.people_rounded,
                      color: AppTheme.primary,
                      title: l.t('users'),
                      subtitle: '${s['total_users'] ?? 0} ${l.t('users_subtitle')}',
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.home_work_rounded,
                      color: AppTheme.secondary,
                      title: l.t('listings'),
                      subtitle: '${s['total_properties'] ?? 0} ${l.t('properties_subtitle')}',
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminPropertiesScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.list_alt_rounded,
                      color: AppTheme.warning,
                      title: l.t('characteristics'),
                      subtitle: l.t('directories_subtitle'),
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminDirectoriesScreen())),
                    ),
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.chat_bubble_rounded,
                      color: AppTheme.danger,
                      title: l.t('messages'),
                      subtitle: '${s['total_messages'] ?? 0} ${l.t('messages_subtitle')}',
                      isDark: isDark,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminMessagesScreen())),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _Stat({required this.label, required this.value, required this.icon,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(AppTheme.r12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 11,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
          ]),
        ]),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.color, required this.title,
      required this.subtitle, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.r16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppTheme.r16)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 16,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
          ]),
        ),
      ),
    );
  }
}
