import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../property/property_detail_screen.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});
  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  final _searchCtrl = TextEditingController();
  String? _catFilter;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() {
    String? category = _catFilter;
    String? status;
    if (_catFilter == '__pending') {
      category = null;
      status = 'pending';
    }
    context.read<AdminProvider>().loadProperties(
        search: _searchCtrl.text, category: category, status: status, isActive: _activeFilter);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
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
              Expanded(child: Text('${l.t('listings')} (${admin.propsTotal})',
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
                hintText: '${l.t('search')}...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
            ),
          ),
          // Filters
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              children: [
                _Chip(label: l.t('all'), active: _catFilter == null && _activeFilter == null, isDark: isDark,
                    onTap: () { setState(() { _catFilter = null; _activeFilter = null; }); _load(); }),
                const SizedBox(width: 8),
                _Chip(label: l.t('status_pending'), active: _catFilter == '__pending', isDark: isDark,
                    onTap: () { setState(() { _catFilter = '__pending'; _activeFilter = null; }); _load(); }),
                const SizedBox(width: 8),
                _Chip(label: l.t('houses'), active: _catFilter == 'house', isDark: isDark,
                    onTap: () { setState(() { _catFilter = 'house'; _activeFilter = null; }); _load(); }),
                const SizedBox(width: 8),
                _Chip(label: l.t('cars'), active: _catFilter == 'car', isDark: isDark,
                    onTap: () { setState(() { _catFilter = 'car'; _activeFilter = null; }); _load(); }),
              ],
            ),
          ),
          // List
          Expanded(
            child: admin.loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : admin.properties.isEmpty
                    ? Center(child: Text(l.t('no_properties'), style: GoogleFonts.inter(color: AppTheme.lightTextTertiary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () async => _load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                          itemCount: admin.properties.length,
                          itemBuilder: (ctx, i) {
                            final p = admin.properties[i];
                            return _PropertyAdminCard(p: p, l: l, isDark: isDark, admin: admin,
                                onTap: () async {
                                  await Navigator.push(ctx, MaterialPageRoute(
                                      builder: (_) => PropertyDetailScreen(propertyId: p.id)));
                                  _load();
                                });
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _PropertyAdminCard extends StatelessWidget {
  final dynamic p;
  final AppLocalizations l;
  final bool isDark;
  final AdminProvider admin;
  final VoidCallback onTap;
  const _PropertyAdminCard({required this.p, required this.l, required this.isDark, required this.admin, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppTheme.secondary;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = p.status.isEmpty ? 'pending' : p.status;
    final sc = _statusColor(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (p.category == 'car' ? AppTheme.warning : AppTheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.r12),
              ),
              child: Icon(
                p.category == 'car' ? Icons.directions_car_rounded : Icons.home_rounded,
                color: p.category == 'car' ? AppTheme.warning : AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${p.ownerName.isNotEmpty ? p.ownerName : p.ownerPhone} | ${p.region}',
                  style: GoogleFonts.inter(fontSize: 12,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
            ])),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.r12),
              ),
              child: Text(l.t('status_$status'),
                  style: GoogleFonts.inter(color: sc, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _InfoPill('${_fmtPrice(p.price)} ${p.currency}', AppTheme.primary, isDark),
            const SizedBox(width: 6),
            _InfoPill('${p.viewsCount} ${l.t('views')}', AppTheme.warning, isDark),
          ]),
        ]),
      ),
    ),
    );
  }

  String _fmtPrice(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.r12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.isDark, required this.onTap});

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

class _InfoPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  const _InfoPill(this.text, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.r12),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
