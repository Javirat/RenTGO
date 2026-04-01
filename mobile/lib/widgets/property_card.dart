import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final String locale;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onDelete;

  const PropertyCard({
    super.key,
    required this.property,
    required this.locale,
    required this.onTap,
    this.showActions = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(locale);
    final hasImage = property.primaryImageUrl != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: hasImage
                  ? Image.network(property.primaryImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_formatPrice(property.price)} UZS${l.t('per_month')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Info row
                  Row(
                    children: [
                      if (property.rooms > 0) ...[
                        Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${property.rooms}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(width: 12),
                      ],
                      if (property.capacity > 0) ...[
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${property.capacity} ${l.t('people')}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(width: 12),
                      ],
                      if (property.hasCctv) ...[
                        Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(l.t('cctv'), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Region
                  if (property.region.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(property.region, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),

                  // Actions
                  if (showActions) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        property.category == 'car' ? Icons.directions_car : Icons.home,
        size: 48,
        color: Colors.grey[400],
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
