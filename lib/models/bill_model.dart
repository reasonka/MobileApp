import 'package:cloud_firestore/cloud_firestore.dart';

enum BillCategory { shopping, groceries, food, utilities, rent, other }

extension BillCategoryExtension on BillCategory {
  String get label {
    switch (this) {
      case BillCategory.shopping: return 'Shopping';
      case BillCategory.groceries: return 'Groceries';
      case BillCategory.food: return 'Food';
      case BillCategory.utilities: return 'Utilities';
      case BillCategory.rent: return 'Rent';
      case BillCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case BillCategory.shopping: return '🛍️';
      case BillCategory.groceries: return '🛒';
      case BillCategory.food: return '🍔';
      case BillCategory.utilities: return '💡';
      case BillCategory.rent: return '🏠';
      case BillCategory.other: return '📋';
    }
  }

  static BillCategory fromString(String value) {
    return BillCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BillCategory.other,
    );
  }
}

class BillModel {
  final String billId;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final List<String> settledBy; // ← NEW: UIDs who paid their share
  final BillCategory category;
  final DateTime createdAt;
  final String houseId;

  BillModel({
    required this.billId,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    this.settledBy = const [],
    required this.category,
    required this.createdAt,
    required this.houseId,
  });

  double get perPersonAmount => amount / splitBetween.length;

  /// Bill is fully settled when every non-payer has marked as paid
  bool get isFullySettled {
    final debtors = splitBetween.where((id) => id != paidBy).toList();
    if (debtors.isEmpty) return true;
    return debtors.every((id) => settledBy.contains(id));
  }

  bool isSettledBy(String userId) => settledBy.contains(userId);

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel(
      billId: doc.id,
      amount: (data['amount'] as num).toDouble(),
      paidBy: data['paidBy'] as String,
      splitBetween: List<String>.from(data['splitBetween'] ?? []),
      settledBy: List<String>.from(data['settledBy'] ?? []),
      category: BillCategoryExtension.fromString(data['category'] ?? 'other'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      houseId: data['houseId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'paidBy': paidBy,
    'splitBetween': splitBetween,
    'settledBy': settledBy,
    'category': category.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'houseId': houseId,
  };
}