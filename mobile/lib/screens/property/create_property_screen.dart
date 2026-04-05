import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/app_theme.dart';
import 'map_picker_screen.dart';

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final f = buf.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class CreatePropertyScreen extends StatefulWidget {
  final Property? property; // null = create, non-null = edit
  const CreatePropertyScreen({super.key, this.property});
  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _totalFloorsCtrl = TextEditingController();
  // Car controllers
  final _carYearCtrl = TextEditingController();
  final _carMileageCtrl = TextEditingController();
  final _carSeatsCtrl = TextEditingController();

  String _carBrand = '';
  String _carColor = '';

  static const _carBrands = [
    'Chevrolet', 'Toyota', 'Hyundai', 'Kia', 'Daewoo', 'BMW', 'Mercedes-Benz',
    'Audi', 'Volkswagen', 'Honda', 'Nissan', 'Mazda', 'Ford', 'Lexus',
    'Mitsubishi', 'Subaru', 'Peugeot', 'Renault', 'Skoda', 'Opel',
    'Lada (VAZ)', 'BYD', 'Chery', 'Haval', 'Geely', 'Jetour', 'Changan',
  ];

  static const _carColors = [
    'white', 'black', 'silver', 'grey', 'red', 'blue', 'green',
    'yellow', 'brown', 'beige', 'orange', 'purple',
  ];

  String _category = 'house';
  String _region = 'Toshkent shahri';
  String _district = '';
  String _currency = 'UZS';
  bool _hasCctv = false;
  bool _saving = false;
  final List<XFile> _images = [];
  List<PropertyImage> _existingImages = [];

  double? _lat;
  double? _lng;
  String? _pickedAddress;

  // House toggles
  bool _furnished = false;
  String _renovation = '';
  bool _balcony = false;
  bool _parking = false;
  bool _wifi = false;
  bool _washer = false;
  bool _conditioner = false;
  bool _fridge = false;
  bool _tv = false;

  // Car toggles
  String _carTransmission = '';
  String _carFuel = '';
  bool _carAc = false;

  bool get _isEdit => widget.property != null;

  static const _regionDistricts = <String, List<String>>{
    'Toshkent shahri': ['Chilonzor', 'Yunusobod', 'Mirzo Ulugbek', 'Sergeli', 'Yakkasaroy',
        'Shayxontohur', 'Olmazor', 'Mirobod', 'Uchtepa', 'Bektemir', 'Yashnobod'],
    'Toshkent viloyati': ['Chirchiq', 'Olmaliq', 'Angren', 'Nurafshon', 'Bekobod', 'Ohangaron',
        'Zangiota', 'Qibray', 'Bo\'stonliq', 'Parkent'],
    'Samarqand': ['Samarqand shahri', 'Urgut', 'Kattaqo\'rg\'on', 'Bulung\'ur', 'Jomboy', 'Pastdarg\'om'],
    'Buxoro': ['Buxoro shahri', 'Kogon', 'G\'ijduvon', 'Vobkent', 'Qorako\'l', 'Olot'],
    'Farg\'ona': ['Farg\'ona shahri', 'Marg\'ilon', 'Quvasoy', 'Qo\'qon', 'Rishton', 'Beshariq'],
    'Andijon': ['Andijon shahri', 'Asaka', 'Xonobod', 'Shahrixon', 'Marhamat', 'Oltinko\'l'],
    'Namangan': ['Namangan shahri', 'Chortoq', 'Chust', 'Pop', 'Kosonsoy', 'Uchqo\'rg\'on'],
    'Qashqadaryo': ['Qarshi', 'Shahrisabz', 'Kitob', 'G\'uzor', 'Koson', 'Muborak'],
    'Surxondaryo': ['Termiz', 'Denov', 'Sherobod', 'Boysun', 'Sho\'rchi', 'Jarqo\'rg\'on'],
    'Navoiy': ['Navoiy shahri', 'Zarafshon', 'Uchquduq', 'Nurota', 'Karmana', 'Konimex'],
    'Xorazm': ['Urganch', 'Xiva', 'Shovot', 'Bog\'ot', 'Gurlan', 'Hazorasp'],
    'Jizzax': ['Jizzax shahri', 'G\'allaorol', 'Do\'stlik', 'Zomin', 'Forish', 'Arnasoy'],
    'Sirdaryo': ['Guliston', 'Sirdaryo shahri', 'Shirin', 'Boyovut', 'Oqoltin', 'Xovos'],
    'Qoraqalpog\'iston': ['Nukus', 'Mo\'ynoq', 'Qo\'ng\'irot', 'Beruniy', 'Chimboy', 'Xo\'jayli'],
  };

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    if (p != null) {
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toInt().toString();
      _roomsCtrl.text = p.rooms > 0 ? p.rooms.toString() : '';
      _capacityCtrl.text = p.capacity > 0 ? p.capacity.toString() : '';
      _floorCtrl.text = p.floor > 0 ? p.floor.toString() : '';
      _totalFloorsCtrl.text = p.totalFloors > 0 ? p.totalFloors.toString() : '';
      _carBrand = _carBrands.contains(p.carBrand) ? p.carBrand : '';
      _carYearCtrl.text = p.carYear > 0 ? p.carYear.toString() : '';
      _carMileageCtrl.text = p.carMileage > 0 ? p.carMileage.toString() : '';
      _carColor = _carColors.contains(p.carColor) ? p.carColor : '';
      _carSeatsCtrl.text = p.carSeats > 0 ? p.carSeats.toString() : '';
      _category = p.category;
      _currency = p.currency.isNotEmpty ? p.currency : 'UZS';
      _region = _regionDistricts.containsKey(p.region) ? p.region : 'Toshkent shahri';
      _district = p.address;
      _hasCctv = p.hasCctv;
      _lat = p.lat != 0 ? p.lat : null;
      _lng = p.lng != 0 ? p.lng : null;
      _pickedAddress = p.address;
      _furnished = p.furnished;
      _renovation = p.renovation;
      _balcony = p.balcony;
      _parking = p.parking;
      _wifi = p.wifi;
      _washer = p.washer;
      _conditioner = p.conditioner;
      _fridge = p.fridge;
      _tv = p.tv;
      _carTransmission = p.carTransmission;
      _carFuel = p.carFuel;
      _existingImages = List.from(p.images);
      _carAc = p.carAc;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _roomsCtrl.dispose(); _capacityCtrl.dispose(); _floorCtrl.dispose();
    _totalFloorsCtrl.dispose(); _carYearCtrl.dispose();
    _carMileageCtrl.dispose(); _carSeatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(maxWidth: 1280, maxHeight: 1280, imageQuality: 75);
    if (files.isNotEmpty) setState(() => _images.addAll(files));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final l = AppLocalizations(auth.language);
    setState(() => _saving = true);
    try {
      final pp = context.read<PropertyProvider>();
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.replaceAll(' ', '')) ?? 0,
        'region': _region, 'address': _district.isNotEmpty ? _district : (_pickedAddress ?? ''),
        'lat': _lat ?? 0, 'lng': _lng ?? 0,
        'category': _category, 'currency': _currency, 'has_cctv': _hasCctv,
      };
      if (_category == 'house') {
        data['rooms'] = int.tryParse(_roomsCtrl.text) ?? 0;
        data['capacity'] = int.tryParse(_capacityCtrl.text) ?? 0;
        data['floor'] = int.tryParse(_floorCtrl.text) ?? 0;
        data['total_floors'] = int.tryParse(_totalFloorsCtrl.text) ?? 0;
        data['furnished'] = _furnished;
        data['renovation'] = _renovation;
        data['balcony'] = _balcony;
        data['parking'] = _parking;
        data['wifi'] = _wifi;
        data['washer'] = _washer;
        data['conditioner'] = _conditioner;
        data['fridge'] = _fridge;
        data['tv'] = _tv;
      }
      if (_category == 'car') {
        data['car_brand'] = _carBrand;
        data['car_year'] = int.tryParse(_carYearCtrl.text) ?? 0;
        data['car_transmission'] = _carTransmission;
        data['car_fuel'] = _carFuel;
        data['car_mileage'] = int.tryParse(_carMileageCtrl.text) ?? 0;
        data['car_color'] = _carColor;
        data['car_ac'] = _carAc;
        data['car_seats'] = int.tryParse(_carSeatsCtrl.text) ?? 0;
      }
      if (_isEdit) {
        await pp.updateProperty(widget.property!.id, data);
        for (int i = 0; i < _images.length; i++) {
          await pp.uploadImage(widget.property!.id, _images[i].path, isPrimary: i == 0);
        }
      } else {
        final property = await pp.createProperty(data);
        for (int i = 0; i < _images.length; i++) {
          await pp.uploadImage(property.id, _images[i].path, isPrimary: i == 0);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } finally { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                Text(_isEdit ? l.t('edit_property') : l.t('add_property'), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Images
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(AppTheme.r20),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 2,
                              strokeAlign: BorderSide.strokeAlignInside),
                        ),
                        child: (_existingImages.isEmpty && _images.isEmpty)
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(AppTheme.r16)),
                                  child: const Icon(Icons.add_photo_alternate_rounded, size: 24, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(l.t('upload_image'), style: GoogleFonts.inter(
                                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                              ])
                            : ListView.builder(
                                scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8),
                                itemCount: _existingImages.length + _images.length + 1,
                                itemBuilder: (_, i) {
                                  // Add button at the end
                                  if (i == _existingImages.length + _images.length) return GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 110, margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(AppTheme.r12),
                                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(Icons.add_rounded, size: 28, color: AppTheme.primary),
                                    ),
                                  );
                                  // Existing images
                                  if (i < _existingImages.length) {
                                    final img = _existingImages[i];
                                    return Stack(children: [
                                      Container(
                                        width: 110, margin: const EdgeInsets.only(right: 8),
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.r12)),
                                        child: Image.network(img.fullUrl, fit: BoxFit.cover, width: 110, height: 150),
                                      ),
                                      Positioned(top: 4, right: 12, child: GestureDetector(
                                        onTap: () async {
                                          if (_isEdit) {
                                            await context.read<PropertyProvider>().deleteImage(widget.property!.id, img.id);
                                          }
                                          setState(() => _existingImages.removeAt(i));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                                          child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                        ),
                                      )),
                                    ]);
                                  }
                                  // New images
                                  final ni = i - _existingImages.length;
                                  return Stack(children: [
                                    Container(
                                      width: 110, margin: const EdgeInsets.only(right: 8),
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppTheme.r12)),
                                      child: Image.file(File(_images[ni].path), fit: BoxFit.cover, width: 110, height: 150),
                                    ),
                                    Positioned(top: 4, right: 12, child: GestureDetector(
                                      onTap: () => setState(() => _images.removeAt(ni)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                      ),
                                    )),
                                  ]);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Category
                    _Label(l.t('category')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _CatToggle(label: l.t('houses'), icon: Icons.home_rounded,
                          active: _category == 'house', isDark: isDark, onTap: () => setState(() => _category = 'house'))),
                      const SizedBox(width: 10),
                      Expanded(child: _CatToggle(label: l.t('cars'), icon: Icons.directions_car_rounded,
                          active: _category == 'car', isDark: isDark, onTap: () => setState(() => _category = 'car'))),
                    ]),
                    const SizedBox(height: 18),
                    _Label(l.t('title')), const SizedBox(height: 8),
                    TextFormField(controller: _titleCtrl,
                        decoration: InputDecoration(hintText: l.t('title'),
                            prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primary)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 14),
                    _Label(l.t('price')), const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _priceCtrl,
                          decoration: InputDecoration(hintText: '1 000 000',
                              prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.primary)),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandsSeparatorInputFormatter()],
                          validator: (v) => (v == null || v.replaceAll(' ', '').isEmpty) ? 'Required' : null)),
                      const SizedBox(width: 10),
                      SizedBox(width: 100, child: DropdownButtonFormField<String>(
                        value: _currency,
                        items: const [
                          DropdownMenuItem(value: 'UZS', child: Text('UZS')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? 'UZS'),
                      )),
                    ]),
                    if (_category == 'house') ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('rooms')), const SizedBox(height: 8),
                          TextFormField(controller: _roomsCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '3',
                                  prefixIcon: const Icon(Icons.meeting_room_rounded, color: AppTheme.primary))),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('capacity')), const SizedBox(height: 8),
                          TextFormField(controller: _capacityCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '50',
                                  prefixIcon: const Icon(Icons.square_foot_rounded, color: AppTheme.primary))),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('floor')), const SizedBox(height: 8),
                          TextFormField(controller: _floorCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '3',
                                  prefixIcon: const Icon(Icons.stairs_rounded, color: AppTheme.primary))),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('total_floors')), const SizedBox(height: 8),
                          TextFormField(controller: _totalFloorsCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '9',
                                  prefixIcon: const Icon(Icons.apartment_rounded, color: AppTheme.primary))),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      _Label(l.t('renovation')), const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _ChipOption(label: l.t('renovation_euro'), value: 'euro', selected: _renovation, onTap: (v) => setState(() => _renovation = v)),
                        _ChipOption(label: l.t('renovation_cosmetic'), value: 'cosmetic', selected: _renovation, onTap: (v) => setState(() => _renovation = v)),
                        _ChipOption(label: l.t('renovation_designer'), value: 'designer', selected: _renovation, onTap: (v) => setState(() => _renovation = v)),
                        _ChipOption(label: l.t('renovation_none'), value: 'none', selected: _renovation, onTap: (v) => setState(() => _renovation = v)),
                      ]),
                      const SizedBox(height: 14),
                      _Label(l.t('amenities')), const SizedBox(height: 8),
                      _AmenityGrid(isDark: isDark, items: [
                        _AmenityItem(Icons.weekend_rounded, l.t('furnished'), _furnished, (v) => setState(() => _furnished = v)),
                        _AmenityItem(Icons.balcony_rounded, l.t('balcony'), _balcony, (v) => setState(() => _balcony = v)),
                        _AmenityItem(Icons.local_parking_rounded, l.t('parking'), _parking, (v) => setState(() => _parking = v)),
                        _AmenityItem(Icons.wifi_rounded, l.t('wifi'), _wifi, (v) => setState(() => _wifi = v)),
                        _AmenityItem(Icons.local_laundry_service_rounded, l.t('washer'), _washer, (v) => setState(() => _washer = v)),
                        _AmenityItem(Icons.ac_unit_rounded, l.t('conditioner'), _conditioner, (v) => setState(() => _conditioner = v)),
                        _AmenityItem(Icons.kitchen_rounded, l.t('fridge'), _fridge, (v) => setState(() => _fridge = v)),
                        _AmenityItem(Icons.tv_rounded, l.t('tv_feature'), _tv, (v) => setState(() => _tv = v)),
                        _AmenityItem(Icons.videocam_rounded, l.t('cctv'), _hasCctv, (v) => setState(() => _hasCctv = v)),
                      ]),
                    ],
                    if (_category == 'car') ...[
                      const SizedBox(height: 14),
                      _Label(l.t('car_brand')), const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _carBrand.isEmpty ? null : _carBrand,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.directions_car_rounded, color: AppTheme.primary)),
                        hint: Text(l.t('car_brand')),
                        items: _carBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) => setState(() => _carBrand = v ?? ''),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('car_year')), const SizedBox(height: 8),
                          TextFormField(controller: _carYearCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '2020',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary))),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('car_seats')), const SizedBox(height: 8),
                          TextFormField(controller: _carSeatsCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '5',
                                  prefixIcon: const Icon(Icons.event_seat_rounded, color: AppTheme.primary))),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('car_mileage')), const SizedBox(height: 8),
                          TextFormField(controller: _carMileageCtrl, keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(hintText: '50000',
                                  prefixIcon: const Icon(Icons.speed_rounded, color: AppTheme.primary))),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _Label(l.t('car_color')), const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _carColor.isEmpty ? null : _carColor,
                            decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.palette_rounded, color: AppTheme.primary)),
                            hint: Text(l.t('car_color')),
                            isExpanded: true,
                            items: _carColors.map((c) => DropdownMenuItem(value: c, child: Text(l.t('color_$c')))).toList(),
                            onChanged: (v) => setState(() => _carColor = v ?? ''),
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      _Label(l.t('car_transmission')), const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        _ChipOption(label: l.t('car_transmission_auto'), value: 'auto', selected: _carTransmission, onTap: (v) => setState(() => _carTransmission = v)),
                        _ChipOption(label: l.t('car_transmission_manual'), value: 'manual', selected: _carTransmission, onTap: (v) => setState(() => _carTransmission = v)),
                      ]),
                      const SizedBox(height: 14),
                      _Label(l.t('car_fuel')), const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _ChipOption(label: l.t('car_fuel_petrol'), value: 'petrol', selected: _carFuel, onTap: (v) => setState(() => _carFuel = v)),
                        _ChipOption(label: l.t('car_fuel_diesel'), value: 'diesel', selected: _carFuel, onTap: (v) => setState(() => _carFuel = v)),
                        _ChipOption(label: l.t('car_fuel_gas'), value: 'gas', selected: _carFuel, onTap: (v) => setState(() => _carFuel = v)),
                        _ChipOption(label: l.t('car_fuel_electric'), value: 'electric', selected: _carFuel, onTap: (v) => setState(() => _carFuel = v)),
                        _ChipOption(label: l.t('car_fuel_hybrid'), value: 'hybrid', selected: _carFuel, onTap: (v) => setState(() => _carFuel = v)),
                      ]),
                      const SizedBox(height: 14),
                      _AmenityGrid(isDark: isDark, items: [
                        _AmenityItem(Icons.ac_unit_rounded, l.t('car_ac'), _carAc, (v) => setState(() => _carAc = v)),
                        _AmenityItem(Icons.radar_rounded, l.t('radar'), _hasCctv, (v) => setState(() => _hasCctv = v)),
                      ]),
                    ],
                    const SizedBox(height: 14),
                    _Label(l.t('region')), const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _region,
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primary)),
                      items: _regionDistricts.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() { _region = v ?? 'Toshkent shahri'; _district = ''; }),
                    ),
                    const SizedBox(height: 14),
                    _Label(l.t('district')), const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_region),
                      value: (_regionDistricts[_region] ?? []).contains(_district) ? _district : null,
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.location_city_rounded, color: AppTheme.primary)),
                      hint: Text(l.t('district')),
                      items: (_regionDistricts[_region] ?? []).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _district = v ?? ''),
                    ),
                    const SizedBox(height: 14),
                    _Label(l.t('address')), const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<MapPickerResult>(
                          context,
                          MaterialPageRoute(builder: (_) => MapPickerScreen(
                            initialLat: _lat, initialLng: _lng,
                          )),
                        );
                        if (result != null) {
                          setState(() {
                            _lat = result.lat;
                            _lng = result.lng;
                            _pickedAddress = result.address;
                          });
                        }
                      },
                      child: Container(
                        height: _lat != null ? 160 : 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(AppTheme.r16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _lat != null && _lng != null
                            ? Stack(children: [
                                IgnorePointer(
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(_lat!, _lng!),
                                      initialZoom: 15,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.rentgo.app',
                                      ),
                                      MarkerLayer(markers: [
                                        Marker(
                                          point: LatLng(_lat!, _lng!),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    color: (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.9),
                                    child: Row(children: [
                                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(
                                        _pickedAddress ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      )),
                                      const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primary),
                                    ]),
                                  ),
                                ),
                              ])
                            : Row(children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.map_rounded, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Expanded(child: Text(
                                  l.t('open_on_map'),
                                  style: GoogleFonts.inter(fontSize: 15,
                                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                )),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
                                const SizedBox(width: 12),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Label(l.t('description')), const SizedBox(height: 8),
                    TextFormField(controller: _descCtrl, maxLines: 3,
                        decoration: InputDecoration(hintText: l.t('description'))),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(_isEdit ? l.t('save') : l.t('create'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    )),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14));
}

class _ChipOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;
  const _ChipOption({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onTap(active ? '' : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.r12),
          border: Border.all(color: active ? AppTheme.primary : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
      ),
    );
  }
}

class _AmenityItem {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  _AmenityItem(this.icon, this.label, this.value, this.onChanged);
}

class _AmenityGrid extends StatelessWidget {
  final bool isDark;
  final List<_AmenityItem> items;
  const _AmenityGrid({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return GestureDetector(
          onTap: () => item.onChanged(!item.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: item.value ? AppTheme.primary.withValues(alpha: 0.1) : isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: item.value ? AppTheme.primary : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 18, color: item.value ? AppTheme.primary : isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                const SizedBox(width: 6),
                Text(item.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                    color: item.value ? AppTheme.primary : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                if (item.value) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_rounded, size: 16, color: AppTheme.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CatToggle extends StatelessWidget {
  final String label; final IconData icon;
  final bool active, isDark; final VoidCallback onTap;
  const _CatToggle({required this.label, required this.icon, required this.active,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: active ? AppTheme.primary : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: active ? Colors.white : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(
            color: active ? Colors.white : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
