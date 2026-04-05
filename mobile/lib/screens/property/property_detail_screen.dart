import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../messages/chat_screen.dart';
import 'create_property_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Property? _property;
  bool _loading = true;
  int _currentImg = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await context.read<PropertyProvider>().getProperty(widget.propertyId);
      setState(() { _property = p; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3)));
    }
    if (_property == null) {
      return Scaffold(appBar: AppBar(), body: Center(
          child: Text('Not found', style: GoogleFonts.inter(color: AppTheme.lightTextTertiary))));
    }

    final p = _property!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTheme.r12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
              ),
            ),
            actions: [
              if (auth.user?.id == p.ownerId)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppTheme.r12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      onTap: () async {
                        final edited = await Navigator.push<bool>(context,
                            MaterialPageRoute(builder: (_) => CreatePropertyScreen(property: p)));
                        if (edited == true) _load();
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  p.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: p.images.length,
                          onPageChanged: (i) => setState(() => _currentImg = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: p.images[i].fullUrl, fit: BoxFit.cover,
                            memCacheWidth: 720,
                            fadeInDuration: const Duration(milliseconds: 200),
                            placeholder: (_, _a) => _imgPlaceholder(p, isDark),
                            errorWidget: (_, _a, _b) => _imgPlaceholder(p, isDark),
                          ),
                        )
                      : _imgPlaceholder(p, isDark),
                  // Bottom fade
                  Positioned(bottom: 0, left: 0, right: 0,
                    child: Container(height: 80, decoration: BoxDecoration(
                      color: Colors.transparent,
                      // No gradient — just a color bar
                    )),
                  ),
                  // Dots
                  if (p.images.length > 1)
                    Positioned(bottom: 16, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _currentImg ? 20 : 8, height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentImg ? AppTheme.primary : Colors.white.withValues(alpha: 0.5),
                          ),
                        )),
                      ),
                    ),
                  // Count
                  if (p.images.length > 1)
                    Positioned(top: 56, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: Text('${_currentImg + 1}/${p.images.length}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                    ),
                    child: Text('${_fmtPrice(p.price)} ${p.currency}${l.t('per_month')}',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 18),
                  // Info chips
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (p.rooms > 0) _Tag(Icons.meeting_room_rounded, '${p.rooms} ${l.t('rooms')}', AppTheme.primary, isDark),
                    if (p.capacity > 0) _Tag(Icons.square_foot_rounded, '${p.capacity} ${l.t('people')}', AppTheme.info, isDark),
                    if (p.floor > 0) _Tag(Icons.stairs_rounded, '${p.floor}/${p.totalFloors > 0 ? p.totalFloors : '?'} ${l.t('floor')}', AppTheme.primary, isDark),
                    _Tag(p.category == 'car' ? Icons.directions_car_rounded : Icons.home_rounded,
                        p.category == 'car' ? l.t('cars') : l.t('houses'), AppTheme.warning, isDark),
                    if (p.renovation.isNotEmpty && p.renovation != 'none') _Tag(Icons.construction_rounded, l.t('renovation_${p.renovation}'), AppTheme.info, isDark),
                    // Car info
                    if (p.carBrand.isNotEmpty) _Tag(Icons.directions_car_rounded, p.carBrand, AppTheme.primary, isDark),
                    if (p.carYear > 0) _Tag(Icons.calendar_today_rounded, '${p.carYear}', AppTheme.info, isDark),
                    if (p.carTransmission.isNotEmpty) _Tag(Icons.settings_rounded, l.t('car_transmission_${p.carTransmission}'), AppTheme.primary, isDark),
                    if (p.carFuel.isNotEmpty) _Tag(Icons.local_gas_station_rounded, l.t('car_fuel_${p.carFuel}'), AppTheme.warning, isDark),
                    if (p.carMileage > 0) _Tag(Icons.speed_rounded, '${p.carMileage} km', AppTheme.info, isDark),
                    if (p.carColor.isNotEmpty) _Tag(Icons.palette_rounded, l.t('color_${p.carColor}'), AppTheme.primary, isDark),
                    if (p.carSeats > 0) _Tag(Icons.event_seat_rounded, '${p.carSeats} ${l.t('car_seats')}', AppTheme.info, isDark),
                    _Tag(Icons.visibility_rounded, '${p.viewsCount} ${l.t('views')}', AppTheme.lightTextTertiary, isDark),
                  ]),
                  const SizedBox(height: 18),
                  // Amenities
                  if (_hasAmenities(p)) ...[
                    Text(l.t('amenities'), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (p.furnished) _AmenityChip(Icons.weekend_rounded, l.t('furnished'), isDark),
                      if (p.balcony) _AmenityChip(Icons.balcony_rounded, l.t('balcony'), isDark),
                      if (p.parking) _AmenityChip(Icons.local_parking_rounded, l.t('parking'), isDark),
                      if (p.wifi) _AmenityChip(Icons.wifi_rounded, l.t('wifi'), isDark),
                      if (p.washer) _AmenityChip(Icons.local_laundry_service_rounded, l.t('washer'), isDark),
                      if (p.conditioner) _AmenityChip(Icons.ac_unit_rounded, l.t('conditioner'), isDark),
                      if (p.fridge) _AmenityChip(Icons.kitchen_rounded, l.t('fridge'), isDark),
                      if (p.tv) _AmenityChip(Icons.tv_rounded, l.t('tv_feature'), isDark),
                      if (p.hasCctv && p.category == 'house') _AmenityChip(Icons.videocam_rounded, l.t('cctv'), isDark),
                      if (p.hasCctv && p.category == 'car') _AmenityChip(Icons.radar_rounded, l.t('radar'), isDark),
                      if (p.carAc) _AmenityChip(Icons.ac_unit_rounded, l.t('car_ac'), isDark),
                    ]),
                    const SizedBox(height: 18),
                  ],
                  // Location map
                  if (p.lat != 0 && p.lng != 0) ...[
                    GestureDetector(
                      onTap: () {
                        final url = Uri.parse('https://yandex.com/maps/?pt=${p.lng},${p.lat}&z=16&l=map');
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.r16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(children: [
                          IgnorePointer(
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(p.lat, p.lng),
                                initialZoom: 15,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.rentgo.app',
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: LatLng(p.lat, p.lng),
                                    width: 40, height: 40,
                                    child: const Icon(Icons.location_on, color: AppTheme.danger, size: 40),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.92),
                              child: Row(children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                  [p.address, p.region].where((s) => s.isNotEmpty).join(', '),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                )),
                                Text(l.t('open_on_map'),
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primary),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else if (p.address.isNotEmpty || p.region.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(AppTheme.r16),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.r12)),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(
                          [p.address, p.region].where((s) => s.isNotEmpty).join(', '),
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 18),
                  ],
                  // Description
                  if (p.description.isNotEmpty) ...[
                    Text(l.t('description'), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(p.description, style: GoogleFonts.inter(
                        fontSize: 15, height: 1.6, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(auth, p, l, isDark),
    );
  }

  Future<void> _startChat(BuildContext ctx, Property p, AppLocalizations l) async {
    try {
      final conv = await ctx.read<ChatProvider>().startConversation(p.id, p.ownerId);
      if (mounted) {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => ChatScreen(
          conversationId: conv.id,
          otherName: p.ownerName.isNotEmpty ? p.ownerName : p.ownerPhone,
          propertyTitle: p.title,
        )));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
    }
  }

  void _showContact(BuildContext ctx, Property p, AppLocalizations l, bool isDark) {
    showModalBottomSheet(context: ctx, builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.r20)),
          child: Center(child: Text(
            p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(height: 14),
        if (p.ownerName.isNotEmpty) Text(p.ownerName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (p.ownerPhone.isNotEmpty) Text(_fmtPhone(p.ownerPhone), style: GoogleFonts.inter(
            fontSize: 16, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: SizedBox(height: 52, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            onPressed: () => launchUrl(Uri.parse('tel:${p.ownerPhone}')),
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: Text(l.t('call'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 52, child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: p.ownerPhone));
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l.t('copied')),
                  backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l.t('copy'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ))),
        ]),
        const SizedBox(height: 8),
      ]),
    ));
  }

  Widget? _buildBottomBar(AuthProvider auth, Property p, AppLocalizations l, bool isDark) {
    final isOwner = auth.user?.id == p.ownerId;
    final isAdmin = auth.user?.isAdmin ?? false;

    // Admin sees approve/reject/delete
    if (isAdmin && !isOwner) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
          ),
          child: Row(children: [
            if (p.status != 'approved')
              Expanded(child: SizedBox(height: 52, child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AdminProvider>().updatePropertyStatus(p.id, 'approved');
                  if (mounted) { _load(); }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(l.t('approve'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
              ))),
            if (p.status != 'approved') const SizedBox(width: 10),
            if (p.status != 'rejected')
              Expanded(child: SizedBox(height: 52, child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AdminProvider>().updatePropertyStatus(p.id, 'rejected');
                  if (mounted) { _load(); }
                },
                icon: const Icon(Icons.block_rounded, size: 20),
                label: Text(l.t('reject'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              ))),
            if (p.status != 'rejected') const SizedBox(width: 10),
            SizedBox(height: 52, width: 52, child: Material(
              color: AppTheme.dangerSoft,
              borderRadius: BorderRadius.circular(AppTheme.r16),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.r16),
                onTap: () async {
                  final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r20)),
                    title: Text(l.t('confirm_delete')),
                    content: Text(p.title),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.t('cancel'))),
                      TextButton(onPressed: () => Navigator.pop(c, true),
                          child: Text(l.t('delete'), style: const TextStyle(color: AppTheme.danger))),
                    ],
                  ));
                  if (ok == true && mounted) {
                    await context.read<AdminProvider>().deleteProperty(p.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 22),
              ),
            )),
          ]),
        ),
      );
    }

    // Owner sees nothing
    if (isOwner) return null;

    // Others see contact/message
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
        ),
        child: Row(children: [
          Material(
            color: AppTheme.secondarySoft,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.r16),
              onTap: () => _showContact(context, p, l, isDark),
              child: const SizedBox(width: 56, height: 56,
                  child: Icon(Icons.phone_rounded, color: AppTheme.secondary, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(height: 56, child: ElevatedButton.icon(
              onPressed: () => _startChat(context, p, l),
              icon: const Icon(Icons.message_rounded, size: 18),
              label: Text(l.t('write_message'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            )),
          ),
        ]),
      ),
    );
  }

  bool _hasAmenities(Property p) =>
      p.furnished || p.balcony || p.parking || p.wifi || p.washer ||
      p.conditioner || p.fridge || p.tv || p.hasCctv || p.carAc;

  Widget _imgPlaceholder(Property p, bool isDark) => Container(
    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    child: Center(child: Icon(
      p.category == 'car' ? Icons.directions_car_rounded : Icons.home_rounded,
      size: 56, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)),
  );

  String _fmtPhone(String phone) {
    final p = phone.replaceAll('+', '').replaceAll(' ', '');
    if (p.length == 12) return '+${p.substring(0, 3)} ${p.substring(3, 5)} ${p.substring(5, 8)} ${p.substring(8, 10)} ${p.substring(10)}';
    return phone;
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

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _AmenityChip(this.icon, this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.r12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _Tag(this.icon, this.label, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.r12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
