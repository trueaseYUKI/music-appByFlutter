import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  // 子组件
  final Widget child;
  const InfoCard(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: child,
      ),
    );
  }
}
