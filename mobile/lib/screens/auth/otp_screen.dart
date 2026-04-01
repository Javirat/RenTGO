import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'role_screen.dart';
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

  Future<void> _verify() async {
    if (_code.length != 5) return;

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    try {
      final isNew = await auth.verifyOtp(phone: widget.phone, code: _code);
      if (!mounted) return;

      if (isNew) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations(auth.language);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('verify'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              l.t('enter_otp'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.phone, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            if (auth.devOtpCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'DEV CODE: ${auth.devOtpCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            MaterialPinField(
              length: 5,
              onCompleted: (pin) {
                _code = pin;
                _verify();
              },
              onChanged: (pin) => _code = pin,
              theme: MaterialPinTheme(
                shape: MaterialPinShape.outlined,
                cellSize: const Size(56, 60),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading ? null : _verify,
              child: auth.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.t('verify')),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  await auth.sendOtp(widget.phone);
                },
                child: Text(l.t('resend_otp')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
