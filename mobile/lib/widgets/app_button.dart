import 'package:flutter/material.dart';

/// Primary/secondary buttons with a built-in loading spinner, mirroring
/// frontend/src/components/ui/Button.tsx's variant + isLoading behavior.
enum AppButtonVariant { primary, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
          )
        : Text(label);

    final button = variant == AppButtonVariant.primary
        ? ElevatedButton(onPressed: disabled ? null : onPressed, child: child)
        : OutlinedButton(onPressed: disabled ? null : onPressed, child: child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
