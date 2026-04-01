import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Property? _property;
  bool _loading = true;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await context.read<PropertyProvider>().getProperty(widget.propertyId);
      setState(() {
        _property = p;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not found')),
      );
    }

    final p = _property!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image gallery
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: p.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: p.images.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) => Image.network(
                        p.images[i].minioUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(p),
                      ),
                    )
                  : _imagePlaceholder(p),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image indicator
                  if (p.images.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        p.images.length,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _currentImage ? const Color(0xFF2563EB) : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title
                  Text(p.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '${_formatPrice(p.price)} UZS${l.t('per_month')}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (p.rooms > 0)
                        _InfoChip(icon: Icons.meeting_room, label: '${p.rooms} ${l.t('rooms')}'),
                      if (p.capacity > 0)
                        _InfoChip(icon: Icons.people, label: '${p.capacity} ${l.t('people')}'),
                      _InfoChip(
                        icon: p.category == 'car' ? Icons.directions_car : Icons.home,
                        label: p.category == 'car' ? l.t('cars') : l.t('houses'),
                      ),
                      if (p.hasCctv)
                        _InfoChip(icon: Icons.videocam, label: l.t('cctv')),
                      _InfoChip(icon: Icons.visibility, label: '${p.viewsCount} ${l.t('views')}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  if (p.address.isNotEmpty || p.region.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [p.address, p.region].where((s) => s.isNotEmpty).join(', '),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (p.description.isNotEmpty) ...[
                    Text(l.t('description'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(p.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.phone),
            label: Text(auth.language == 'uz'
                ? 'Bog\'lanish'
                : auth.language == 'ru'
                    ? 'Связаться'
                    : 'Contact'),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Property p) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          p.category == 'car' ? Icons.directions_car : Icons.home,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
