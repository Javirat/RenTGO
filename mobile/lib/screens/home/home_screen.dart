import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/theme_provider.dart';
import '../property/property_detail_screen.dart';
import '../property/create_property_screen.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';
import '../messages/messages_screen.dart';
import '../../widgets/property_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedCategory = 0; // 0=all, 1=house, 2=car

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() => _selectedCategory = index);
    final pp = context.read<PropertyProvider>();
    String? cat;
    if (index == 1) cat = 'house';
    if (index == 2) cat = 'car';
    pp.setFilters(category: cat, region: pp.regionFilter);
    pp.loadProperties(refresh: true);
  }

  void _onSearch(String query) {
    final pp = context.read<PropertyProvider>();
    pp.setFilters(category: pp.categoryFilter, region: query.isEmpty ? null : query);
    pp.loadProperties(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pp = context.watch<PropertyProvider>();
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations(auth.language);
    final isLandlord = auth.user?.isLandlord ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('app_name')),
        actions: [
          if (isLandlord)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2563EB)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (auth.user?.fullName.isNotEmpty == true)
                          ? auth.user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName : auth.user?.phone ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    isLandlord ? l.t('landlord') : l.t('renter'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(l.t('statistics')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
              },
            ),
            if (isLandlord)
              ListTile(
                leading: const Icon(Icons.home_work),
                title: Text(l.t('my_properties')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const _MyPropertiesPage()));
                },
              ),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: Text(l.t('messages')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l.t('profile')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: Text(l.t('dark_mode')),
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l.t('logout'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                auth.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: '${l.t('search')}... (Chilonzor, Yunusobod...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _CategoryChip(
                  label: l.t('all'),
                  icon: Icons.grid_view,
                  selected: _selectedCategory == 0,
                  onTap: () => _onCategoryTap(0),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: l.t('houses'),
                  icon: Icons.home,
                  selected: _selectedCategory == 1,
                  onTap: () => _onCategoryTap(1),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: l.t('cars'),
                  icon: Icons.directions_car,
                  selected: _selectedCategory == 2,
                  onTap: () => _onCategoryTap(2),
                ),
              ],
            ),
          ),

          // Property list
          Expanded(
            child: pp.loading && pp.properties.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : pp.properties.isEmpty
                    ? Center(child: Text(l.t('no_properties')))
                    : RefreshIndicator(
                        onRefresh: () => pp.loadProperties(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pp.properties.length + (pp.properties.length < pp.total ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= pp.properties.length) {
                              pp.loadProperties();
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final p = pp.properties[index];
                            return PropertyCard(
                              property: p,
                              locale: auth.language,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailScreen(propertyId: p.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    return Scaffold(
      appBar: AppBar(title: Text(l.t('my_properties'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : pp.myProperties.isEmpty
              ? Center(child: Text(l.t('no_properties')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pp.myProperties.length,
                  itemBuilder: (context, index) {
                    final p = pp.myProperties[index];
                    return PropertyCard(
                      property: p,
                      locale: auth.language,
                      showActions: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailScreen(propertyId: p.id),
                        ),
                      ),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l.t('confirm_delete')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.t('no'))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.t('yes'))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await pp.deleteProperty(p.id);
                        }
                      },
                    );
                  },
                ),
    );
  }
}
