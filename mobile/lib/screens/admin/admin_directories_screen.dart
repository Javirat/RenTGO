import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AdminDirectoriesScreen extends StatelessWidget {
  const AdminDirectoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations(context.watch<AuthProvider>().language);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(children: [
              Material(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(AppTheme.r12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.r12),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Text(l.t('characteristics'), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 14),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              _Card(Icons.directions_car_rounded, AppTheme.primary, l.t('car_brand'), 'car_brand', isDark),
              const SizedBox(height: 10),
              _Card(Icons.palette_rounded, AppTheme.secondary, l.t('car_color'), 'car_color', isDark),
              const SizedBox(height: 10),
              _Card(Icons.location_on_rounded, AppTheme.warning, l.t('region'), 'region', isDark),
              const SizedBox(height: 10),
              _Card(Icons.location_city_rounded, AppTheme.info, l.t('district'), 'district', isDark),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _Card(IconData icon, Color color, String title, String type, bool isDark) {
    return Builder(builder: (context) => Material(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(AppTheme.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.r16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _DirListScreen(title: title, dirType: type))),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.r16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppTheme.r16)),
                child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700))),
            Icon(Icons.arrow_forward_ios_rounded, size: 16,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
          ]),
        ),
      ),
    ));
  }
}

class _DirListScreen extends StatefulWidget {
  final String title, dirType;
  const _DirListScreen({required this.title, required this.dirType});
  @override
  State<_DirListScreen> createState() => _DirListScreenState();
}

class _DirListScreenState extends State<_DirListScreen> {
  final _api = ApiClient();
  List<dynamic> _items = [];
  List<dynamic> _regions = []; // for district parent dropdown
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _api.getDirectories(widget.dirType);
      if (widget.dirType == 'district') _regions = await _api.getDirectories('region');
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _display(dynamic item, String lang) {
    final uz = (item['value_uz'] ?? '') as String;
    final ru = (item['value_ru'] ?? '') as String;
    final en = (item['value_en'] ?? '') as String;
    if (lang == 'uz' && uz.isNotEmpty) return uz;
    if (lang == 'ru' && ru.isNotEmpty) return ru;
    if (lang == 'en' && en.isNotEmpty) return en;
    if (ru.isNotEmpty) return ru;
    return item['value'] ?? '';
  }

  Future<void> _showForm({dynamic existing}) async {
    final isEdit = existing != null;
    final isDistrict = widget.dirType == 'district';
    final keyCtrl = TextEditingController(text: isEdit ? existing['value'] ?? '' : '');
    final uzCtrl = TextEditingController(text: isEdit ? existing['value_uz'] ?? '' : '');
    final ruCtrl = TextEditingController(text: isEdit ? existing['value_ru'] ?? '' : '');
    final enCtrl = TextEditingController(text: isEdit ? existing['value_en'] ?? '' : '');
    String? parentRegion = isEdit ? existing['parent_value'] : null;

    final result = await showDialog<bool>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r20)),
        title: Text(isEdit ? 'Редактировать' : 'Добавить', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: keyCtrl,
              decoration: const InputDecoration(hintText: 'Ключ (value)', prefixIcon: Icon(Icons.key_rounded, color: AppTheme.primary))),
          const SizedBox(height: 10),
          TextField(controller: uzCtrl,
              decoration: const InputDecoration(hintText: "O'zbekcha", prefixIcon: Icon(Icons.language_rounded, color: AppTheme.primary))),
          const SizedBox(height: 10),
          TextField(controller: ruCtrl,
              decoration: const InputDecoration(hintText: 'Русский', prefixIcon: Icon(Icons.language_rounded, color: AppTheme.secondary))),
          const SizedBox(height: 10),
          TextField(controller: enCtrl,
              decoration: const InputDecoration(hintText: 'English', prefixIcon: Icon(Icons.language_rounded, color: AppTheme.info))),
          if (isDistrict) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: parentRegion,
              decoration: const InputDecoration(hintText: 'Регион', prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.warning)),
              isExpanded: true,
              items: _regions.map<DropdownMenuItem<String>>((r) {
                final rName = (r['value_ru'] ?? r['value']) as String;
                return DropdownMenuItem(value: r['value'] as String, child: Text(rName));
              }).toList(),
              onChanged: (v) => setS(() => parentRegion = v),
            ),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Сохранить' : 'Добавить', style: const TextStyle(color: AppTheme.primary))),
        ],
      ));
    });

    if (result != true) return;
    final key = keyCtrl.text.trim().isNotEmpty ? keyCtrl.text.trim() : uzCtrl.text.trim();
    if (key.isEmpty) return;

    final data = <String, dynamic>{
      'type': widget.dirType,
      'value': key,
      'value_uz': uzCtrl.text.trim(),
      'value_ru': ruCtrl.text.trim(),
      'value_en': enCtrl.text.trim(),
      if (isDistrict && parentRegion != null) 'parent_value': parentRegion,
    };

    try {
      if (isEdit) {
        await _api.adminUpdateDirectory(existing['id'], data);
      } else {
        await _api.adminCreateDirectory(data);
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<AuthProvider>().language;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(children: [
              Material(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(AppTheme.r12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 44, height: 44,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTheme.r12),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('${widget.title} (${_items.length})',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800))),
            ]),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary.withValues(alpha: 0.6), strokeWidth: 3))
                : _items.isEmpty
                    ? Center(child: Text('—', style: GoogleFonts.inter(fontSize: 18,
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            final name = _display(item, lang);
                            final parent = (item['parent_value'] ?? '') as String;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                borderRadius: BorderRadius.circular(AppTheme.r12),
                                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (parent.isNotEmpty)
                                    Text(parent, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary)),
                                ])),
                                GestureDetector(
                                  onTap: () => _showForm(existing: item),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(Icons.edit_rounded, size: 18,
                                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _api.adminDeleteDirectory(item['id']);
                                    _load();
                                  },
                                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
