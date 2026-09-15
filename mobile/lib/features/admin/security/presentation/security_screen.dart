import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/security_providers.dart';
import '../data/models/admin_security.dart';

/// Mirrors the website's admin Security page: reCAPTCHA bot-protection
/// (toggle + keys) and a self-serve outbound-email test. Any admin can
/// reach this (not gated to super admin — see AdminSecurityController).
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _siteKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _testToController = TextEditingController();

  bool _toggleBusy = false;
  bool _keysBusy = false;
  bool _testBusy = false;
  String? _toggleError;
  String? _keysError;
  bool _saved = false;
  MailTestResult? _testResult;

  @override
  void dispose() {
    _siteKeyController.dispose();
    _secretKeyController.dispose();
    _testToController.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool next) async {
    if (_toggleBusy) return;
    setState(() {
      _toggleBusy = true;
      _toggleError = null;
    });
    try {
      await ref.read(securityRepositoryProvider).update(recaptchaEnabled: next);
      ref.invalidate(adminSecurityProvider);
    } catch (error) {
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      if (mounted) setState(() => _toggleError = message);
    } finally {
      if (mounted) setState(() => _toggleBusy = false);
    }
  }

  Future<void> _saveKeys() async {
    setState(() {
      _keysBusy = true;
      _keysError = null;
      _saved = false;
    });
    try {
      await ref.read(securityRepositoryProvider).update(
        recaptchaSiteKey: _siteKeyController.text.trim().isEmpty ? null : _siteKeyController.text.trim(),
        recaptchaSecretKey: _secretKeyController.text.trim().isEmpty ? null : _secretKeyController.text.trim(),
      );
      ref.invalidate(adminSecurityProvider);
      _siteKeyController.clear();
      _secretKeyController.clear();
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      if (mounted) setState(() => _keysError = message);
    } finally {
      if (mounted) setState(() => _keysBusy = false);
    }
  }

  Future<void> _sendTestEmail() async {
    setState(() {
      _testBusy = true;
      _testResult = null;
    });
    try {
      final result = await ref
          .read(securityRepositoryProvider)
          .sendTestEmail(to: _testToController.text.trim().isEmpty ? null : _testToController.text.trim());
      if (mounted) setState(() => _testResult = result);
    } catch (error) {
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _testBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(adminSecurityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: security.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Skeleton(height: 320, borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        error: (error, _) => ErrorState(
          message: 'Could not load security settings.',
          onRetry: () => ref.invalidate(adminSecurityProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RecaptchaCard(
              data: data,
              siteKeyController: _siteKeyController,
              secretKeyController: _secretKeyController,
              toggleBusy: _toggleBusy,
              keysBusy: _keysBusy,
              toggleError: _toggleError,
              keysError: _keysError,
              saved: _saved,
              onToggle: _toggle,
              onSaveKeys: _saveKeys,
            ),
            const SizedBox(height: 16),
            _MailTestCard(
              testToController: _testToController,
              busy: _testBusy,
              result: _testResult,
              onSend: _sendTestEmail,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecaptchaCard extends StatelessWidget {
  const _RecaptchaCard({
    required this.data,
    required this.siteKeyController,
    required this.secretKeyController,
    required this.toggleBusy,
    required this.keysBusy,
    required this.toggleError,
    required this.keysError,
    required this.saved,
    required this.onToggle,
    required this.onSaveKeys,
  });

  final AdminSecurity data;
  final TextEditingController siteKeyController;
  final TextEditingController secretKeyController;
  final bool toggleBusy;
  final bool keysBusy;
  final String? toggleError;
  final String? keysError;
  final bool saved;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSaveKeys;

  @override
  Widget build(BuildContext context) {
    final canEnable = data.recaptchaSiteKey != null && data.recaptchaSecretConfigured;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('"I\'m not a robot" check (reCAPTCHA)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Nothing currently stops a script from creating accounts in a loop. Add your Google '
                        'reCAPTCHA v2 keys below, then turn this on.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      data.recaptchaEnabled ? 'On' : 'Off',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink700),
                    ),
                    toggleBusy
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Switch(
                            value: data.recaptchaEnabled,
                            onChanged: canEnable ? onToggle : null,
                          ),
                  ],
                ),
              ],
            ),
            if (toggleError != null) ...[
              const SizedBox(height: 4),
              Text(toggleError!, style: const TextStyle(color: AppColors.danger600)),
            ],
            if (data.recaptchaSiteKey == null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://www.google.com/recaptcha/admin/create'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Get a free site key + secret key at google.com/recaptcha/admin — choose reCAPTCHA v2, '
                  '"I\'m not a robot" Checkbox.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.link600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: siteKeyController,
              decoration: InputDecoration(labelText: 'Site key', hintText: data.recaptchaSiteKey ?? 'Not set'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secretKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Secret key',
                hintText: data.recaptchaSecretConfigured ? 'Set — leave blank to keep it' : 'Not set',
              ),
            ),
            if (keysError != null) ...[
              const SizedBox(height: 8),
              Text(keysError!, style: const TextStyle(color: AppColors.danger600)),
            ],
            if (saved) ...[
              const SizedBox(height: 8),
              const Text('Saved.', style: TextStyle(color: AppColors.success600)),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Save keys',
                variant: AppButtonVariant.outlined,
                expand: false,
                isLoading: keysBusy,
                onPressed: onSaveKeys,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MailTestCard extends StatelessWidget {
  const _MailTestCard({
    required this.testToController,
    required this.busy,
    required this.result,
    required this.onSend,
  });

  final TextEditingController testToController;
  final bool busy;
  final MailTestResult? result;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Outbound email', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "If alert emails aren't arriving, the most common cause is MAIL_MAILER still set to \"log\" even after "
              'SMTP credentials were added to the live .env. Send a test email right now to check the current setup.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: testToController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Send test to (optional)',
                hintText: 'Leave blank to send to your own email',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Send test email',
                variant: AppButtonVariant.outlined,
                expand: false,
                isLoading: busy,
                onPressed: onSend,
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result!.sent ? AppColors.success100 : AppColors.danger100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result!.sent
                      ? 'Sent to ${result!.to} via mailer "${result!.mailer}". Check your inbox (and spam folder).'
                      : 'Failed via mailer "${result!.mailer}": ${result!.error}',
                  style: TextStyle(color: result!.sent ? AppColors.success600 : AppColors.danger600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
