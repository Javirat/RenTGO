import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';

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

    final totalListings = props.length;
    final activeListings = props.where((p) => p.isActive).length;
    final totalViews = props.fold<int>(0, (sum, p) => sum + p.viewsCount);
    final houses = props.where((p) => p.category == 'house').length;
    final cars = props.where((p) => p.category == 'car').length;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('statistics'))),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.list_alt,
                          label: l.t('total_listings'),
                          value: '$totalListings',
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          label: l.t('active'),
                          value: '$activeListings',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.visibility,
                          label: l.t('views'),
                          value: '$totalViews',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.home,
                          label: l.t('houses'),
                          value: '$houses',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.directions_car,
                          label: l.t('cars'),
                          value: '$cars',
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ..._buildTopList(props, l),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildTopList(List props, AppLocalizations l) {
    if (props.isEmpty) return [];
    final sorted = props.toList()..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final top = sorted.take(5).toList();
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l.t('top_viewed'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 12),
      ...top.map((p) => Card(
            child: ListTile(
              leading: Icon(
                p.category == 'car' ? Icons.directions_car : Icons.home,
                color: const Color(0xFF2563EB),
              ),
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${p.viewsCount}'),
                ],
              ),
            ),
          )),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
