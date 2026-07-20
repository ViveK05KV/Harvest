import 'package:flutter/material.dart';

/// The FilledButton-with-spinner used at the bottom of every save/create form.
class SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;

  const SaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
    this.label = 'Save',
    this.icon = Icons.save,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: saving ? null : onPressed,
      icon: saving
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon),
      label: Text(label),
    );
  }
}
