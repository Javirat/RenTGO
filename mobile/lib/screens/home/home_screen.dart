import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_screen.dart';
import '../property/property_detail_screen.dart';
import '../property/create_property_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/messages_screen.dart';
import '../../widgets/property_card.dart';
import '../auth/language_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  int _selectedCat = 0;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties(refresh: true);
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _onCatTap(int i) {
    setState(() => _selectedCat = i);
    final pp = context.read<PropertyProvider>();
    pp.setFilters(category: i == 1 ? 'house' : i == 2 ? 'car' : null, region: pp.regionFilter);
    pp.loadProperties(refresh: true);
  }

  void _onSearch(String q) {
    final pp = context.read<PropertyProvider>();
    pp.setSearch(q.isEmpty ? null : q);
    pp.loadProperties(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAdmin = auth.user?.isAdmin ?? false;

    final pages = [
      _FeedPage(searchCtrl: _searchCtrl, selectedCat: _selectedCat, onCatTap: _onCatTap, onSearch: _onSearch),
      const MessagesScreen(embedded: true),
      const _MyPropertiesPage(),
      if (isAdmin) const AdminScreen(),
      const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: _BottomBar(
        tab: _tab,
        isAdmin: isAdmin,
        isDark: isDark,
        l: l,
        onTap: (i) => setState(() => _tab = i),
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const CreatePropertyScreen()));
                if (created == true && mounted) {
                  context.read<PropertyProvider>().loadProperties(refresh: true);
                  context.read<PropertyProvider>().loadMyProperties();
                }
              },
              child: const Icon(Icons.add_rounded, size: 26),
            )
          : null,
    );
  }
}

// === BOTTOM NAV ===
class _BottomBar extends StatelessWidget {
  final int tab;
  final bool isAdmin, isDark;
  final AppLocalizations l;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.tab, required this.isAdmin, required this.isDark,
      required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profileIdx = isAdmin ? 4 : 3;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: l.t('listings'),
                  active: tab == 0, onTap: () => onTap(0), isDark: isDark),
              _NavItem(icon: Icons.chat_bubble_rounded, label: l.t('messages'),
                  active: tab == 1, onTap: () => onTap(1), isDark: isDark),
              _NavItem(icon: Icons.home_work_rounded, label: l.t('my_properties'),
                  active: tab == 2, onTap: () => onTap(2), isDark: isDark),
              if (isAdmin)
                _NavItem(icon: Icons.admin_panel_settings_rounded, label: l.t('admin_panel'),
                    active: tab == 3, onTap: () => onTap(3), isDark: isDark),
              _NavItem(icon: Icons.person_rounded, label: l.t('profile'),
                  active: tab == profileIdx, onTap: () => onTap(profileIdx), isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active,
      required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppTheme.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.rFull),
              ),
              child: Icon(icon, size: 22, color: active ? AppTheme.primary
                  : isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.primary
                      : isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                )),
          ],
        ),
      ),
    );
  }
}

// === FEED PAGE ===
class _FeedPage extends StatelessWidget {
  final TextEditingController searchCtrl;
  final int selectedCat;
  final ValueChanged<int> onCatTap;
  final ValueChanged<String> onSearch;

  const _FeedPage({required this.searchCtrl, required this.selectedCat,
      required this.onCatTap, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pp = context.watch<PropertyProvider>();
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.t('app_name'), style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
                      Text(_greeting(auth.language, auth.user?.fullName),
                          style: GoogleFonts.inter(fontSize: 13,
                              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
                    ],
                  ),
                ),
                _HdrBtn(icon: theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    isDark: isDark, onTap: () => theme.toggle()),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: searchCtrl,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: '${l.t('search')}...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () { searchCtrl.clear(); onSearch(''); })
                    : null,
              ),
            ),
          ),

          // Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              children: [
                _Chip(label: l.t('all'), icon: Icons.grid_view_rounded,
                    active: selectedCat == 0, isDark: isDark, onTap: () => onCatTap(0)),
                const SizedBox(width: 8),
                _Chip(label: l.t('houses'), icon: Icons.home_rounded,
                    active: selectedCat == 1, isDark: isDark, onTap: () => onCatTap(1)),
                const SizedBox(width: 8),
                _Chip(label: l.t('cars'), icon: Icons.directions_car_rounded,
                    active: selectedCat == 2, isDark: isDark, onTap: () => onCatTap(2)),
              ],
            ),
          ),

          // List
          Expanded(
            child: pp.loading && pp.properties.isEmpty
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : pp.properties.isEmpty
                    ? _EmptyState(icon: Icons.search_off_rounded, text: l.t('no_properties'), isDark: isDark)
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () => pp.loadProperties(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: pp.properties.length + (pp.properties.length < pp.total ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i >= pp.properties.length) {
                              pp.loadProperties();
                              return const Padding(padding: EdgeInsets.all(16),
                                  child: Center(child: SizedBox(width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5))));
                            }
                            final p = pp.properties[i];
                            return PropertyCard(
                              property: p, locale: auth.language,
                              onTap: () => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => PropertyDetailScreen(propertyId: p.id))),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _greeting(String lang, String? name) {
    final h = DateTime.now().hour;
    final g = h < 12
        ? (lang == 'uz' ? 'Xayrli tong' : lang == 'ru' ? 'Доброе утро' : 'Good morning')
        : h < 18
            ? (lang == 'uz' ? 'Xayrli kun' : lang == 'ru' ? 'Добрый день' : 'Good afternoon')
            : (lang == 'uz' ? 'Xayrli kech' : lang == 'ru' ? 'Добрый вечер' : 'Good evening');
    if (name != null && name.isNotEmpty) return '$g, ${name.split(' ').first}';
    return g;
  }
}

class _HdrBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _HdrBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.r12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.r12),
          onTap: onTap,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Icon(icon, size: 18,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, isDark;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.icon, required this.active,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.rFull),
          border: Border.all(
            color: active ? AppTheme.primary : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? Colors.white
                : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white
                  : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _EmptyState({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.r24),
            ),
            child: Icon(icon, size: 36,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
          ),
          const SizedBox(height: 14),
          Text(text, style: GoogleFonts.inter(fontSize: 15,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
        ],
      ),
    );
  }
}

// === MY PROPERTIES ===
class _MyPropertiesPage extends StatefulWidget {
  const _MyPropertiesPage();
  @override
  State<_MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<_MyPropertiesPage> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(l.t('my_properties'),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
          ),
          Expanded(
            child: pp.myLoading
                ? const Center(child: CircularProgressIndicator())
                : pp.myProperties.isEmpty
                    ? _EmptyState(icon: Icons.home_work_rounded, text: l.t('no_properties'), isDark: isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: pp.myProperties.length,
                        itemBuilder: (ctx, i) {
                          final p = pp.myProperties[i];
                          return PropertyCard(
                            property: p, locale: auth.language, showActions: true,
                            onTap: () => Navigator.push(ctx,
                                MaterialPageRoute(builder: (_) => PropertyDetailScreen(propertyId: p.id))),
                            onDelete: () async {
                              final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r20)),
                                title: Text(l.t('confirm_delete')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.t('no'))),
                                  TextButton(onPressed: () => Navigator.pop(c, true),
                                      child: Text(l.t('yes'), style: const TextStyle(color: AppTheme.danger))),
                                ],
                              ));
                              if (ok == true) await pp.deleteProperty(p.id);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
