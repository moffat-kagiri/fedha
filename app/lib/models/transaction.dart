@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;
  
  @HiveField(2)
  final bool isSynced; // Track sync status

  Transaction({required this.id, required this.amount, this.isSynced = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    // ... other fields
  };
}