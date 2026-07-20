class CurrentStock {
  final int fruitId;
  final String fruitName;
  final String unit;
  final double currentStock;

  const CurrentStock({
    required this.fruitId,
    required this.fruitName,
    required this.unit,
    required this.currentStock,
  });

  factory CurrentStock.fromJson(Map<String, dynamic> json) {
    return CurrentStock(
      fruitId: json['fruitID'] as int,
      fruitName: json['fruitName'] as String,
      unit: json['unit'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
    );
  }
}

class StockLedgerEntry {
  final int stockLedgerId;
  final DateTime transactionDate;
  final String transactionType;
  final double quantityIn;
  final double quantityOut;
  final double runningStock;
  final String? narration;

  const StockLedgerEntry({
    required this.stockLedgerId,
    required this.transactionDate,
    required this.transactionType,
    required this.quantityIn,
    required this.quantityOut,
    required this.runningStock,
    this.narration,
  });

  factory StockLedgerEntry.fromJson(Map<String, dynamic> json) {
    return StockLedgerEntry(
      stockLedgerId: json['stockLedgerID'] as int,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      transactionType: json['transactionType'] as String,
      quantityIn: (json['quantityIn'] as num).toDouble(),
      quantityOut: (json['quantityOut'] as num).toDouble(),
      runningStock: (json['runningStock'] as num).toDouble(),
      narration: json['narration'] as String?,
    );
  }
}
