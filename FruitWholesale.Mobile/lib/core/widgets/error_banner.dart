import 'package:flutter/material.dart';

/// The red-tinted message box shown at the top of forms when a save/load fails.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
    );
  }
}
