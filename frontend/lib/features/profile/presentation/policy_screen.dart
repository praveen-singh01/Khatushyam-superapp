import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/legal_policies.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.policy});

  final LegalPolicy policy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(policy.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            policy.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
