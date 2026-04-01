import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController(text: '+998');
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final regex = RegExp(r'^\+998\d{9}$');
    if (!regex.hasMatch(phone)) {
      setState(() => _error = 'Format: +998XXXXXXXXX');
      return;
    }

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    try {
      await auth.sendOtp(phone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
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
      appBar: AppBar(title: Text(l.t('phone_number'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              l.t('enter_phone'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '+998 XX XXX XX XX',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 13,
              style: const TextStyle(fontSize: 18, letterSpacing: 1),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                counterText: '',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading ? null : _sendOtp,
              child: auth.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.t('send_otp')),
            ),
          ],
        ),
      ),
    );
  }
}
