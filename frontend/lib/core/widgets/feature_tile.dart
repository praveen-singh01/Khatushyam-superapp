import 'package:flutter/material.dart';

import 'circle_action.dart';

/// Kept for older call sites; maps to circular mockup-style action.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.locked = false,
    this.accent,
  });

  final String title;
  final IconData icon;
  final bool locked;
  final Color? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CircleAction(icon: icon, label: title, locked: locked, onTap: onTap);
  }
}
