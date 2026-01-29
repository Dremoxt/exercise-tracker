import 'package:flutter/material.dart';
import '../config/environment.dart';

/// A banner that displays when running in QA/staging environment.
/// Shows at the top of the app to clearly indicate this is not production.
class QABanner extends StatelessWidget {
  final Widget child;

  const QABanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Don't show banner in production
    if (EnvironmentConfig.isProduction) {
      return child;
    }

    return Banner(
      message: 'QA',
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: Column(
        children: [
          _QAInfoBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _QAInfoBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.science, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'QA Environment • Local Storage Only • No Cloud Sync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
