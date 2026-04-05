import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'name_screen.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  String? _error;

  String get _formattedPhone {
    final p = widget.phone.replaceAll('+', '').replaceAll(' ', '');
    if (p.length == 12) {
      return '+${p.substring(0, 3)} ${p.substring(3, 5)} ${p.substring(5, 8)} ${p.substring(8, 10)} ${p.substring(10)}';
    }
    return widget.phone;
  }

  Future<void> _verify() async {
    if (_code.length != 5) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final l = AppLocalizations(auth.language);
    try {
      final isNew = await auth.verifyOtp(phone: widget.phone, code: _code);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => isNew ? const NameScreen() : const HomeScreen()),
        (_) => false,
      );
    } catch (_) {
      setState(() => _error = l.t('invalid_code'));
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
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(AppTheme.r20),
                      ),
                      child: const Icon(Icons.shield_rounded, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(l.t('enter_otp'),
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(_formattedPhone,
                            style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('(${l.t('change')})',
                              style: GoogleFonts.inter(
                                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (auth.devOtpCode != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.warningSoft.withValues(alpha: 0.1) : AppTheme.warningSoft,
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bug_report_rounded, color: AppTheme.warning, size: 20),
                            const SizedBox(width: 10),
                            Text('DEV: ${auth.devOtpCode}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 4, color: AppTheme.warning,
                                )),
                          ],
                        ),
                      ),
                    ],
                    MaterialPinField(
                      length: 5,
                      onCompleted: (pin) { _code = pin; _verify(); },
                      onChanged: (pin) => _code = pin,
                      theme: MaterialPinTheme(
                        shape: MaterialPinShape.outlined,
                        cellSize: const Size(56, 62),
                        borderRadius: BorderRadius.circular(AppTheme.r16),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.dangerSoft.withValues(alpha: 0.1) : AppTheme.dangerSoft,
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
                            const SizedBox(width: 8),
                            Text(_error!, style: GoogleFonts.inter(color: AppTheme.danger, fontWeight: FontWeight.w500, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.loading ? null : _verify,
                        child: auth.loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text(l.t('verify'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () async => await auth.sendOtp(widget.phone),
                        child: Text(l.t('resend_otp'),
                            style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 15)),
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

class _BackBar extends StatelessWidget {
  final bool isDark;
  const _BackBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ]),
    );
  }
}
