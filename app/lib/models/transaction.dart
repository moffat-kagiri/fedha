import 'package:hive/hive.dart';

part 'transaction.g.dart'; // Critical for code generation

@HiveType(typeId: 1) // Unique typeId (0 is used by Profile)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String type; // "IN" or "EX"

  @HiveField(3)
  final String category; // e.g., "MARKETING"

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  bool isSynced; // Local sync status

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    this.isSynced = false,
  });
 // Convert to JSON for API sync
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
  };
}
}