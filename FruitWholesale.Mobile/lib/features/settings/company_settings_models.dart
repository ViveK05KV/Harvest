class CompanySettings {
  final int companyId;
  final String companyName;
  final String? ownerName;
  final String? address;
  final String? phone;
  final String? gstNo;
  final String? logoUrl;
  final double openingCashBalance;

  const CompanySettings({
    this.companyId = 0,
    required this.companyName,
    this.ownerName,
    this.address,
    this.phone,
    this.gstNo,
    this.logoUrl,
    this.openingCashBalance = 0,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      companyId: json['companyID'] as int,
      companyName: json['companyName'] as String,
      ownerName: json['ownerName'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      gstNo: json['gstNo'] as String?,
      logoUrl: json['logoUrl'] as String?,
      openingCashBalance: (json['openingCashBalance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'companyName': companyName,
        'ownerName': ownerName,
        'address': address,
        'phone': phone,
        'gstNo': gstNo,
        'openingCashBalance': openingCashBalance,
      };
}
