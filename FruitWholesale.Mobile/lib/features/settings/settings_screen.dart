import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/api_config.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
import 'company_settings_models.dart';
import 'company_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late final CompanySettingsService _service = CompanySettingsService(context.read<ApiClient>());

  late TabController _tabController;
  CompanySettings? _settings;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final canAdjustCash = context.read<AuthService>().user!.role != UserRole.staff;
    _tabController = TabController(length: canAdjustCash ? 3 : 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await _service.get();
      setState(() => _settings = settings);
    } on ApiException catch (e) {
      setState(() => _loadError = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthService>().user!.role;
    final canAdjustCash = role != UserRole.staff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Company Profile'),
            const Tab(text: 'Change Password'),
            if (canAdjustCash) const Tab(text: 'Cash Adjustment'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CompanyProfileTab(initial: _settings, loadError: _loadError, onSaved: _load),
                const _ChangePasswordTab(),
                if (canAdjustCash) const _CashAdjustmentTab(),
              ],
            ),
    );
  }
}

class _CompanyProfileTab extends StatefulWidget {
  final CompanySettings? initial;
  final String? loadError;
  final VoidCallback onSaved;

  const _CompanyProfileTab({required this.initial, required this.loadError, required this.onSaved});

  @override
  State<_CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<_CompanyProfileTab> {
  late final CompanySettingsService _service = CompanySettingsService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.companyName);
  late final _ownerController = TextEditingController(text: widget.initial?.ownerName);
  late final _addressController = TextEditingController(text: widget.initial?.address);
  late final _phoneController = TextEditingController(text: widget.initial?.phone);
  late final _gstController = TextEditingController(text: widget.initial?.gstNo);
  late final _openingCashController =
      TextEditingController(text: widget.initial?.openingCashBalance.toStringAsFixed(2) ?? '0');

  String? _logoUrl;
  bool _saving = false;
  bool _uploadingLogo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.initial?.logoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _openingCashController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final updated = await _service.uploadLogo(picked.path);
      setState(() => _logoUrl = updated.logoUrl);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final settings = CompanySettings(
      companyName: _nameController.text.trim(),
      ownerName: _ownerController.text.trim().isEmpty ? null : _ownerController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      gstNo: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      openingCashBalance: double.tryParse(_openingCashController.text) ?? 0,
    );
    try {
      await _service.save(settings);
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile saved')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.loadError != null) ...[
            ErrorBanner(widget.loadError!),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.surfaceContainerHigh,
                backgroundImage: _logoUrl != null ? NetworkImage('${ApiConfig.baseUrl.replaceFirst('/api', '')}$_logoUrl') : null,
                child: _logoUrl == null ? const Icon(Icons.store) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                  icon: _uploadingLogo
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload),
                  label: const Text('Upload Logo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Company Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _ownerController, decoration: const InputDecoration(labelText: 'Owner Name')),
          const SizedBox(height: 16),
          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
          const SizedBox(height: 16),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          TextFormField(controller: _gstController, decoration: const InputDecoration(labelText: 'GST No')),
          const SizedBox(height: 16),
          TextFormField(
            controller: _openingCashController,
            decoration: const InputDecoration(
              labelText: 'Opening Cash Balance',
              helperText: 'Use Cash Adjustment to change the balance after go-live',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SaveButton(saving: _saving, onPressed: _save, label: 'Save Changes'),
        ],
      ),
    );
  }
}

class _ChangePasswordTab extends StatefulWidget {
  const _ChangePasswordTab();

  @override
  State<_ChangePasswordTab> createState() => _ChangePasswordTabState();
}

class _ChangePasswordTabState extends State<_ChangePasswordTab> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final service = CompanySettingsService(context.read<ApiClient>());
    try {
      await service.changePassword(currentPassword: _currentController.text, newPassword: _newController.text);
      _currentController.clear();
      _newController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
            validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 24),
          SaveButton(saving: _saving, onPressed: _save, label: 'Update Password', icon: Icons.lock_reset),
        ],
      ),
    );
  }
}

class _CashAdjustmentTab extends StatefulWidget {
  const _CashAdjustmentTab();

  @override
  State<_CashAdjustmentTab> createState() => _CashAdjustmentTabState();
}

class _CashAdjustmentTabState extends State<_CashAdjustmentTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();
  bool _isIncrease = true;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final service = CompanySettingsService(context.read<ApiClient>());
    try {
      await service.applyCashAdjustment(
        amount: double.tryParse(_amountController.text) ?? 0,
        isIncrease: _isIncrease,
        narration: _narrationController.text.trim(),
      );
      _amountController.clear();
      _narrationController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash adjustment applied')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Cash adjustments create a manual ledger entry. Use this only for corrections — every other cash movement is automatic.',
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          RadioGroup<bool>(
            groupValue: _isIncrease,
            onChanged: (v) => setState(() => _isIncrease = v!),
            child: const Row(
              children: [
                Expanded(child: RadioListTile<bool>(title: Text('Increase Cash'), value: true)),
                Expanded(child: RadioListTile<bool>(title: Text('Decrease Cash'), value: false)),
              ],
            ),
          ),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final amount = double.tryParse(v ?? '');
              if (amount == null || amount <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _narrationController,
            decoration: const InputDecoration(labelText: 'Narration / Reason'),
            maxLines: 2,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Narration is required' : null,
          ),
          const SizedBox(height: 24),
          SaveButton(saving: _saving, onPressed: _save, label: 'Apply Adjustment'),
        ],
      ),
    );
  }
}
