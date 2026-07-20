import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'company_settings_models.dart';

class CompanySettingsService {
  final ApiClient _api;

  CompanySettingsService(this._api);

  /// Returns null if no company profile has been saved yet (backend 404).
  Future<CompanySettings?> get() async {
    try {
      final json = await _api.get('/companysettings');
      return CompanySettings.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CompanySettings> save(CompanySettings settings) async {
    final json = await _api.put('/companysettings', body: settings.toSaveJson());
    return CompanySettings.fromJson(json as Map<String, dynamic>);
  }

  Future<CompanySettings> uploadLogo(String filePath) async {
    final json = await _api.postMultipartFile('/companysettings/logo', fieldName: 'file', filePath: filePath);
    return CompanySettings.fromJson(json as Map<String, dynamic>);
  }

  Future<void> applyCashAdjustment({required double amount, required bool isIncrease, required String narration}) async {
    await _api.post('/companysettings/cash-adjustment', body: {
      'amount': amount,
      'isIncrease': isIncrease,
      'narration': narration,
    });
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
