import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() => context.read<AdminProvider>().loadUsers(search: _searchCtrl.text, role: _roleFilter);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(children: [
              Material(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(AppTheme.r12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Users (${admin.usersTotal})',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800))),
            ]),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by phone or name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
            ),
          ),
          // Role filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              children: [
                _FilterChip(label: 'All', active: _roleFilter == null, isDark: isDark,
                    onTap: () { setState(() => _roleFilter = null); _load(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Users', active: _roleFilter == 'user', isDark: isDark,
                    onTap: () { setState(() => _roleFilter = 'user'); _load(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Admins', active: _roleFilter == 'admin', isDark: isDark,
                    onTap: () { setState(() => _roleFilter = 'admin'); _load(); }),
              ],
            ),
          ),
          // List
          Expanded(
            child: admin.loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : admin.users.isEmpty
                    ? Center(child: Text('No users found', style: GoogleFonts.inter(color: AppTheme.lightTextTertiary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () async => _load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                          itemCount: admin.users.length,
                          itemBuilder: (ctx, i) {
                            final u = admin.users[i];
                            final roleColor = u.isAdmin ? AppTheme.danger : AppTheme.primary;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                borderRadius: BorderRadius.circular(AppTheme.r16),
                                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  // Avatar
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(color: roleColor,
                                        borderRadius: BorderRadius.circular(AppTheme.r12)),
                                    child: Center(child: Text(
                                      u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                    )),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(u.fullName.isNotEmpty ? u.fullName : u.phone,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                                    if (u.fullName.isNotEmpty)
                                      Text(u.phone, style: GoogleFonts.inter(fontSize: 12,
                                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
                                  ])),
                                  // Role badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.r12),
                                    ),
                                    child: Text(u.role, style: GoogleFonts.inter(
                                        color: roleColor, fontWeight: FontWeight.w700, fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  // Actions
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, size: 20,
                                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r12)),
                                    onSelected: (action) async {
                                      if (action == 'user' || action == 'admin') {
                                        await admin.updateUserRole(u.id, action);
                                      } else if (action == 'delete') {
                                        final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r20)),
                                          title: Text('Delete ${u.fullName.isNotEmpty ? u.fullName : u.phone}?'),
                                          content: const Text('This will delete the user and all their data.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(c, true),
                                                child: const Text('Delete', style: TextStyle(color: AppTheme.danger))),
                                          ],
                                        ));
                                        if (ok == true) await admin.deleteUser(u.id);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'user', child: Text('Set User')),
                                      const PopupMenuItem(value: 'admin', child: Text('Set Admin')),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(value: 'delete',
                                          child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
                                    ],
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.rFull),
          border: Border.all(color: active ? AppTheme.primary : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
      ),
    );
  }
}
