import 'dart:convert';

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
  /// Seeded from the shell's own fetch (`HomeShell._companySettings`) so this
  /// screen doesn't flash a loading state for data the shell already has.
  final CompanySettings? companySettings;

  /// Fired whenever this screen changes company settings (profile save, logo
  /// upload, Manager Access toggles) so the shell's copy — and therefore the
  /// drawer's Reports/Profit Calculator gating — stays live without the user
  /// having to leave and re-enter Settings.
  final ValueChanged<CompanySettings>? onCompanySettingsChanged;

  const SettingsScreen({super.key, this.companySettings, this.onCompanySettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late final CompanySettingsService _service = CompanySettingsService(context.read<ApiClient>());

  late TabController _tabController;
  CompanySettings? _settings;
  bool _loading = true;
  String? _loadError;

  bool get _isAdmin => context.read<AuthService>().user!.role == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _settings = widget.companySettings;
    // Admin gets Company Profile, Manager Access, Account, Cash Adjustment;
    // everyone else just gets Account (their own username/password) — mirrors
    // the web Settings page's per-role cards.
    _tabController = TabController(length: _isAdmin ? 4 : 1, vsync: this);
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
      if (settings != null) widget.onCompanySettingsChanged?.call(settings);
    } on ApiException catch (e) {
      setState(() => _loadError = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSettingsUpdated(CompanySettings settings) {
    setState(() => _settings = settings);
    widget.onCompanySettingsChanged?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      // Single-tab case: skip the TabBar entirely rather than show a bar with
      // nothing to switch between.
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const _AccountTab(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Company Profile'),
            Tab(text: 'Manager Access'),
            Tab(text: 'Account'),
            Tab(text: 'Cash Adjustment'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CompanyProfileTab(initial: _settings, loadError: _loadError, onSaved: _load),
                _ManagerAccessTab(settings: _settings, onChanged: _onSettingsUpdated),
                const _AccountTab(),
                const _CashAdjustmentTab(),
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

  /// The logo comes back either as a `data:` URI (base64-encoded, stored
  /// directly in the DB — see CompanySettingsController.UploadLogo) or, for
  /// older records, a relative file path served by the API. NetworkImage
  /// can't render a data: URI at all, so that case needs MemoryImage.
  ImageProvider? _logoImageProvider() {
    final logoUrl = _logoUrl;
    if (logoUrl == null) return null;
    if (logoUrl.startsWith('data:')) {
      final commaIndex = logoUrl.indexOf(',');
      if (commaIndex == -1) return null;
      return MemoryImage(base64Decode(logoUrl.substring(commaIndex + 1)));
    }
    return NetworkImage('${ApiConfig.baseUrl.replaceFirst('/api', '')}$logoUrl');
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
                backgroundImage: _logoImageProvider(),
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

/// Self-service username + password change, available to every role — the
/// mobile counterpart of the web Settings page's "Account" card.
class _AccountTab extends StatefulWidget {
  const _AccountTab();

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  final _usernameFormKey = GlobalKey<FormState>();
  late final _newUsernameController = TextEditingController(text: context.read<AuthService>().user!.username);
  final _usernamePasswordController = TextEditingController();
  bool _savingUsername = false;
  String? _usernameError;

  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _savingPassword = false;
  String? _passwordError;

  @override
  void dispose() {
    _newUsernameController.dispose();
    _usernamePasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;
    setState(() {
      _savingUsername = true;
      _usernameError = null;
    });
    final error = await context.read<AuthService>().changeUsername(
          _newUsernameController.text.trim(),
          _usernamePasswordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _usernameError = error);
    } else {
      _usernamePasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated')));
    }
    setState(() => _savingUsername = false);
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    final service = CompanySettingsService(context.read<ApiClient>());
    try {
      await service.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } on ApiException catch (e) {
      setState(() => _passwordError = e.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthService>().user!.username;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Signed in as $username.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Text('Username', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Form(
          key: _usernameFormKey,
          child: Column(
            children: [
              if (_usernameError != null) ...[
                ErrorBanner(_usernameError!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _newUsernameController,
                decoration: const InputDecoration(labelText: 'New Username'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required';
                  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(v.trim())) {
                    return 'Only letters, numbers, dot, dash and underscore allowed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernamePasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) => (v == null || v.isEmpty) ? 'Confirm with your current password' : null,
              ),
              const SizedBox(height: 24),
              SaveButton(saving: _savingUsername, onPressed: _saveUsername, label: 'Update Username'),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Divider()),
        Text('Password', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              if (_passwordError != null) ...[
                ErrorBanner(_passwordError!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              SaveButton(saving: _savingPassword, onPressed: _savePassword, label: 'Update Password', icon: Icons.lock_reset),
            ],
          ),
        ),
      ],
    );
  }
}

/// Admin-only toggles for opening Reports / Profit Calculator to Manager —
/// mirrors the web Settings page's "Manager Access" card.
class _ManagerAccessTab extends StatefulWidget {
  final CompanySettings? settings;
  final ValueChanged<CompanySettings> onChanged;

  const _ManagerAccessTab({required this.settings, required this.onChanged});

  @override
  State<_ManagerAccessTab> createState() => _ManagerAccessTabState();
}

class _ManagerAccessTabState extends State<_ManagerAccessTab> {
  late final CompanySettingsService _service = CompanySettingsService(context.read<ApiClient>());
  bool _savingReports = false;
  bool _savingProfit = false;
  String? _error;

  Future<void> _toggleReports(bool next) async {
    setState(() {
      _savingReports = true;
      _error = null;
    });
    try {
      final updated = await _service.setReportsVisibility(next);
      widget.onChanged(updated);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _savingReports = false);
    }
  }

  Future<void> _toggleProfit(bool next) async {
    setState(() {
      _savingProfit = true;
      _error = null;
    });
    try {
      final updated = await _service.setProfitVisibility(next);
      widget.onChanged(updated);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _savingProfit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Give the Manager role visibility into these pages.'),
        const SizedBox(height: 16),
        if (_error != null) ...[
          ErrorBanner(_error!),
          const SizedBox(height: 16),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reports'),
          subtitle: const Text('When off, only Admin can open Reports.'),
          value: settings?.reportsVisibleToManagers ?? false,
          onChanged: (_savingReports || settings == null) ? null : _toggleReports,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Profit Calculator'),
          subtitle: const Text('When off, only Admin can open Profit Calculator.'),
          value: settings?.profitVisibleToManagers ?? false,
          onChanged: (_savingProfit || settings == null) ? null : _toggleProfit,
        ),
      ],
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
