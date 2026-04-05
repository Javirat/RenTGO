import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

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
    final p = property;
    final hasImage = p.primaryImageUrl != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.r20),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.r20),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: p.primaryImageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 640,
                              fadeInDuration: const Duration(milliseconds: 200),
                              placeholder: (_, _a) => _placeholder(p, isDark),
                              errorWidget: (_, _a, _b) => _placeholder(p, isDark),
                            )
                          : _placeholder(p, isDark),
                    ),
                    // Price + views row
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                            ),
                            child: Text(
                              '${_formatPrice(p.price)} ${p.currency}${l.t('per_month')}',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const Spacer(),
                          if (p.viewsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(AppTheme.r12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_rounded, size: 13,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                  const SizedBox(width: 4),
                                  Text('${p.viewsCount}',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Status badge (only for owner view)
                    if (showActions && p.status != 'approved') Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (p.status == 'rejected' ? AppTheme.danger : AppTheme.warning).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                        ),
                        child: Text(l.t('status_${p.status.isEmpty ? 'pending' : p.status}'),
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      // Info pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (p.rooms > 0)
                            _Pill(icon: Icons.meeting_room_rounded, label: '${p.rooms}', isDark: isDark),
                          if (p.capacity > 0)
                            _Pill(icon: Icons.square_foot_rounded, label: '${p.capacity} m²', isDark: isDark),
                          if (p.floor > 0)
                            _Pill(icon: Icons.stairs_rounded, label: '${p.floor}/${p.totalFloors > 0 ? p.totalFloors : '?'}', isDark: isDark),
                          if (p.carBrand.isNotEmpty)
                            _Pill(icon: Icons.directions_car_rounded, label: p.carBrand, isDark: isDark),
                          if (p.carYear > 0)
                            _Pill(icon: Icons.calendar_today_rounded, label: '${p.carYear}', isDark: isDark),
                        ],
                      ),
                      if (p.region.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14,
                                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                            const SizedBox(width: 4),
                            Text(p.region, style: GoogleFonts.inter(
                                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                                fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                      if (showActions && onDelete != null) ...[
                        const SizedBox(height: 12),
                        Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, height: 1),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: AppTheme.dangerSoft,
                            borderRadius: BorderRadius.circular(AppTheme.r12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                              onTap: onDelete,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 16),
                                    const SizedBox(width: 6),
                                    Text(l.t('delete'), style: GoogleFonts.inter(
                                        color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Property p, bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: Center(
        child: Icon(
          p.category == 'car' ? Icons.directions_car_rounded : Icons.home_rounded,
          size: 44, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const _Pill({required this.icon, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
