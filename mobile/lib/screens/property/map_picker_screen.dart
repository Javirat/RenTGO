import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

class MapPickerResult {
  final double lat;
  final double lng;
  final String address;
  MapPickerResult({required this.lat, required this.lng, required this.address});
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapCtrl;
  LatLng? _selected;
  String? _address;
  bool _loading = false;

  // Default: Tashkent center
  static const _defaultLat = 41.2995;
  static const _defaultLng = 69.2401;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    if (widget.initialLat != null && widget.initialLat != 0 &&
        widget.initialLng != null && widget.initialLng != 0) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_selected!);
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=ru');
      final resp = await http.get(url, headers: {'User-Agent': 'RenTGO-App'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() => _address = data['display_name'] ?? '');
      }
    } catch (_) {
      // ignore geocoding errors
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onTap(TapPosition tapPos, LatLng point) {
    setState(() {
      _selected = point;
      _address = null;
    });
    _reverseGeocode(point);
  }

  void _confirm() {
    if (_selected == null) return;
    Navigator.pop(context, MapPickerResult(
      lat: _selected!.latitude,
      lng: _selected!.longitude,
      address: _address ?? '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final center = _selected ?? const LatLng(_defaultLat, _defaultLng);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _selected != null ? 16 : 12,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rentgo.app',
              ),
              if (_selected != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _selected!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: AppTheme.danger, size: 50),
                  ),
                ]),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppTheme.r12),
              elevation: 2,
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
          ),
          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selected == null)
                    Center(
                      child: Text(
                        'Нажмите на карту, чтобы выбрать место',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        ),
                      ),
                    ),
                  if (_selected != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(AppTheme.r12)),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _loading
                              ? Text('...', style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary))
                              : Text(
                                  _address ?? '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _confirm,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text('Подтвердить', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
