import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CreatePropertyScreen extends StatefulWidget {
  const CreatePropertyScreen({super.key});

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
  final _addressCtrl = TextEditingController();

  String _category = 'house';
  String _region = 'Chilonzor';
  bool _hasCctv = false;
  bool _saving = false;
  final List<XFile> _images = [];

  final _regions = [
    'Chilonzor', 'Yunusobod', 'Mirzo Ulugbek', 'Sergeli',
    'Yakkasaroy', 'Shayxontohur', 'Olmazor', 'Mirobod',
    'Uchtepa', 'Bektemir', 'Yashnobod',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _roomsCtrl.dispose();
    _capacityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => _images.addAll(files));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final l = AppLocalizations(auth.language);
    if (auth.user?.role != 'landlord') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('only_landlord')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final pp = context.read<PropertyProvider>();
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.replaceAll(' ', '')) ?? 0,
        'region': _region,
        'address': _addressCtrl.text.trim(),
        'category': _category,
        'has_cctv': _hasCctv,
      };
      if (_category == 'house') {
        data['rooms'] = int.tryParse(_roomsCtrl.text) ?? 0;
        data['capacity'] = int.tryParse(_capacityCtrl.text) ?? 0;
      }
      final property = await pp.createProperty(data);

      // Upload images
      for (int i = 0; i < _images.length; i++) {
        await pp.uploadImage(property.id, _images[i].path, isPrimary: i == 0);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('add_property'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: _images.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(l.t('upload_image'), style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: _images.length + 1,
                          itemBuilder: (_, i) {
                            if (i == _images.length) {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, size: 32, color: Color(0xFF94A3B8)),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  child: const Icon(Icons.image, size: 32, color: Color(0xFF94A3B8)),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Category toggle
              Row(
                children: [
                  Expanded(
                    child: _CategoryToggle(
                      label: l.t('houses'),
                      icon: Icons.home,
                      selected: _category == 'house',
                      onTap: () => setState(() => _category = 'house'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoryToggle(
                      label: l.t('cars'),
                      icon: Icons.directions_car,
                      selected: _category == 'car',
                      onTap: () => setState(() => _category = 'car'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: l.t('title')),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(labelText: '${l.t('price')} (UZS)', prefixIcon: const Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorInputFormatter(),
                ],
                validator: (v) => (v == null || v.replaceAll(' ', '').isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Rooms & Capacity (only for houses)
              if (_category == 'house') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roomsCtrl,
                        decoration: InputDecoration(labelText: l.t('rooms')),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        decoration: InputDecoration(labelText: l.t('capacity')),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Region
              DropdownButtonFormField<String>(
                value: _region,
                decoration: InputDecoration(labelText: l.t('region')),
                items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _region = v ?? 'Chilonzor'),
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(labelText: l.t('address')),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: l.t('description')),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // CCTV
              SwitchListTile(
                title: Text(l.t('cctv')),
                secondary: const Icon(Icons.videocam),
                value: _hasCctv,
                onChanged: (v) => setState(() => _hasCctv = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l.t('create')),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryToggle({
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
