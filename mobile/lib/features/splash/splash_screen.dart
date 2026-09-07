import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shown briefly while `AuthController.build()` resolves the session (the
/// mobile equivalent of the web's initial `useCurrentUser` loading state).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.trust700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, color: Colors.white, size: 48),
            SizedBox(height: 12),
            Text(
              'Ghar Nepal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
