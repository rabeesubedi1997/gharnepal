import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_user.dart';
import '../application/settings_providers.dart';

/// Mirrors frontend/src/pages/Settings.tsx: three independent cards
/// (profile, phone, password), each with its own local save state — no
/// single "form" spanning all three.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileSection(user: user),
                const SizedBox(height: 16),
                _PhoneSection(user: user),
                const SizedBox(height: 16),
                const _PasswordSection(),
              ],
            ),
    );
  }
}

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  late final _nameController = TextEditingController(text: widget.user.name);
  bool _saving = false;
  String? _status;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).updateProfile(_nameController.text.trim());
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) setState(() => _status = 'saved');
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        setState(() => _status = message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _nameController.text.trim() != widget.user.name && _nameController.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.user.email),
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Contact support to change your email address.',
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Save',
              expand: false,
              isLoading: _saving,
              onPressed: dirty ? _save : null,
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status == 'saved' ? 'Saved.' : _status!,
                style: TextStyle(color: _status == 'saved' ? AppColors.success600 : AppColors.danger600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhoneSection extends ConsumerStatefulWidget {
  const _PhoneSection({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_PhoneSection> createState() => _PhoneSectionState();
}

class _PhoneSectionState extends ConsumerState<_PhoneSection> {
  late final _phoneController = TextEditingController(text: widget.user.phone ?? '');
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _error(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).requestPhoneOtp(phone);
      if (mounted) setState(() => _codeSent = true);
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .verifyPhoneOtp(phone: _phoneController.text.trim(), code: code);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        setState(() {
          _codeSent = false;
          _codeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone verified.')));
      }
    } catch (error) {
      if (mounted) _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.user.phoneVerified && _phoneController.text.trim() == widget.user.phone;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Phone', style: Theme.of(context).textTheme.titleMedium),
                if (verified) ...[
                  const SizedBox(width: 8),
                  const AppBadge(label: 'Verified', tone: BadgeTone.success),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              enabled: !_codeSent,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number', hintText: 'e.g. 98XXXXXXXX'),
              onChanged: (_) => setState(() {}),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Verification code'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(label: 'Confirm code', isLoading: _busy, onPressed: _confirmCode),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outlined,
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            }),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              AppButton(
                label: verified ? 'Re-verify this number' : 'Send verification code',
                expand: false,
                isLoading: _busy,
                onPressed: _phoneController.text.trim().isEmpty ? null : _sendCode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection();

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updatePassword(
            currentPassword: _currentController.text,
            password: _newController.text,
            passwordConfirmation: _confirmController.text,
          );
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _currentController.text.isNotEmpty && _newController.text.isNotEmpty && _confirmController.text.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Password', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password', helperText: 'At least 8 characters'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            AppButton(label: 'Update password', expand: false, isLoading: _saving, onPressed: canSave ? _save : null),
          ],
        ),
      ),
    );
  }
}
