import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
import 'route_master_models.dart';
import 'route_master_service.dart';

class RouteMasterFormScreen extends StatefulWidget {
  final int? routeId;

  const RouteMasterFormScreen({super.key, this.routeId});

  bool get isEditing => routeId != null;

  @override
  State<RouteMasterFormScreen> createState() => _RouteMasterFormScreenState();
}

class _RouteMasterFormScreenState extends State<RouteMasterFormScreen> {
  late final RouteMasterService _service = RouteMasterService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final route = await _service.getById(widget.routeId!);
      _nameController.text = route.routeName;
      _descriptionController.text = route.description ?? '';
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final route = RouteMaster(
      routeName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );
    try {
      if (widget.isEditing) {
        await _service.update(widget.routeId!, route);
      } else {
        await _service.create(route);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Route' : 'New Route')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Route Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Route name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SaveButton(saving: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}
