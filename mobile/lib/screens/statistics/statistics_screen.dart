import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadMyProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pp = context.watch<PropertyProvider>();
    final l = AppLocalizations(auth.language);
    final props = pp.myProperties;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final total = props.length;
    final active = props.where((p) => p.isActive).length;
    final views = props.fold<int>(0, (s, p) => s + p.viewsCount);
    final houses = props.where((p) => p.category == 'house').length;
    final cars = props.where((p) => p.category == 'car').length;

    return Scaffold(
      body: SafeArea(
        child: pp.loading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(children: [
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
                    Text(l.t('statistics'), style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ]),
                  const SizedBox(height: 20),

                  // Stats grid
                  Row(children: [
                    Expanded(child: _StatCard(icon: Icons.list_alt_rounded, label: l.t('total_listings'),
                        value: '$total', color: AppTheme.primary, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.check_circle_rounded, label: l.t('active'),
                        value: '$active', color: AppTheme.secondary, isDark: isDark)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _StatCard(icon: Icons.visibility_rounded, label: l.t('views'),
                        value: '$views', color: AppTheme.warning, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.home_rounded, label: l.t('houses'),
                        value: '$houses', color: AppTheme.info, isDark: isDark)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _StatCard(icon: Icons.directions_car_rounded, label: l.t('cars'),
                        value: '$cars', color: AppTheme.danger, isDark: isDark)),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 24),

                  // Top viewed
                  ..._buildTop(props, l, isDark),
                ]),
              ),
      ),
    );
  }

  List<Widget> _buildTop(List props, AppLocalizations l, bool isDark) {
    if (props.isEmpty) return [];
    final sorted = props.toList()..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final top = sorted.take(5).toList();
    return [
      Text(l.t('top_viewed'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      ...top.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.warning, AppTheme.info, AppTheme.danger];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Row(children: [
            // Rank
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: colors[i % colors.length], borderRadius: BorderRadius.circular(AppTheme.r12)),
              child: Center(child: Text('${i + 1}', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
            ),
            const SizedBox(width: 12),
            Icon(p.category == 'car' ? Icons.directions_car_rounded : Icons.home_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(AppTheme.r12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.visibility_rounded, size: 13, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text('${p.viewsCount}', style: GoogleFonts.inter(
                    color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ]),
        );
      }),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool isDark;

  const _StatCard({required this.icon, required this.label, required this.value,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(AppTheme.r12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
