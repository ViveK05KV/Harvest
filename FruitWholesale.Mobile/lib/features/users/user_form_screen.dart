import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'user_models.dart';
import 'user_service.dart';

class UserFormScreen extends StatefulWidget {
  final AppUser? user;

  const UserFormScreen({super.key, this.user});

  bool get isEditing => user != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  late final UserService _service = UserService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user?.fullName);
  late final _usernameController = TextEditingController(text: widget.user?.username);
  final _passwordController = TextEditingController();
  late String _role = widget.user?.role ?? userRoleOptions.first;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEditing) {
        await _service.update(widget.user!.userId, fullName: _nameController.text.trim(), role: _role);
      } else {
        await _service.create(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit User' : 'New User')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              enabled: !widget.isEditing,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [for (final role in userRoleOptions) DropdownMenuItem(value: role, child: Text(role))],
              onChanged: (value) => setState(() => _role = value!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
