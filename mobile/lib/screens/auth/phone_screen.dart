import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _rawPhone => '+998${_phoneCtrl.text.replaceAll(' ', '')}';

  Future<void> _sendOtp() async {
    final phone = _rawPhone;
    if (!RegExp(r'^\+998\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Format: +998 XX XXX XX XX');
      return;
    }
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().sendOtp(phone);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
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
            _BackBar(isDark: isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Icon
                    _IconBox(icon: Icons.phone_android_rounded, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      l.t('enter_phone'),
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+998 XX XXX XX XX',
                      style: GoogleFonts.inter(
                        color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 12, // "XX XXX XX XX" = 12 chars with spaces
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _PhoneNumberFormatter(),
                      ],
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text('+998', style: GoogleFonts.inter(
                                  fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 48),
                        hintText: 'XX XXX XX XX',
                        hintStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: 1.5,
                            color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                        counterText: '',
                        errorText: _error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PrimaryBtn(
                      label: l.t('send_otp'),
                      loading: auth.loading,
                      onPressed: _sendOtp,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.infoSoft.withValues(alpha: 0.08) : AppTheme.infoSoft,
                        borderRadius: BorderRadius.circular(AppTheme.r16),
                        border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                            ),
                            child: const Icon(Icons.telegram, color: AppTheme.info, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.t('telegram_hint_title'),
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => launchUrl(Uri.parse('https://t.me/RentGO_appbot'),
                                      mode: LaunchMode.externalApplication),
                                  child: Text('@RentGO_appbot',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.info, fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppTheme.info, fontSize: 14,
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === SHARED WIDGETS ===

class _BackBar extends StatelessWidget {
  final bool isDark;
  const _BackBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Material(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.r12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.r12),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.r12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.r20),
      ),
      child: Icon(icon, size: 28, color: Colors.white),
    );
  }
}

// Formats: XX XXX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (digits.length > 9) {
      return oldValue;
    }
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryBtn({required this.label, this.loading = false, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r16)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
