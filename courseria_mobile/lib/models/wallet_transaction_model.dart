
enum TransactionStatus { pending, approved, rejected }

class WalletTransaction {
  final String id;
  final String transactionId;
  final double amount;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? receiptImageUrl;
  final String? note;

  WalletTransaction({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.receiptImageUrl,
    this.note,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: _statusFromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      receiptImageUrl: json['receipt_screenshot_url'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'amount': amount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'receipt_screenshot_url': receiptImageUrl,
      'note': note,
    };
  }

  static TransactionStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return TransactionStatus.approved;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }
}
