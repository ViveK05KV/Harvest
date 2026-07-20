import 'package:flutter/material.dart';

import 'save_button.dart';

/// The bordered, full-width bottom bar holding a single [SaveButton] —
/// used as `Scaffold.bottomNavigationBar` on most single-column forms.
class SaveFooterBar extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const SaveFooterBar({super.key, required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: SaveButton(saving: saving, onPressed: onPressed),
        ),
      ),
    );
  }
}
