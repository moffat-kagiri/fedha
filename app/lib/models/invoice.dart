import 'package:hive/hive.dart';

part 'invoice.g.dart';

@HiveType(typeId: 7)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  String clientId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String currency;

  @HiveField(5)
  DateTime issueDate;

  @HiveField(6)
  DateTime dueDate;

  @HiveField(7)
  String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'

  @HiveField(8)
  String? description;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;
  
  @HiveField(13)
  bool isSynced;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.amount,
    this.currency = 'KES',
    required this.issueDate,
    required this.dueDate,
    this.status = 'draft',
    this.description,
    this.notes,
    this.isActive = true,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  bool get isOverdue => 
    status != 'paid' && status != 'cancelled' && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'amount': amount,
      'currency': currency,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'description': description,
      'notes': notes,
      'is_active': isActive,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      clientId: json['client_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'KES',
      issueDate: json['issue_date'] != null 
        ? DateTime.parse(json['issue_date']) 
        : DateTime.now(),
      dueDate: json['due_date'] != null 
        ? DateTime.parse(json['due_date']) 
        : DateTime.now().add(const Duration(days: 30)),
      status: json['status'] ?? 'draft',
      description: json['description'],
      notes: json['notes'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isSynced: json['is_synced'] ?? json['isSynced'] ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, amount: $amount, status: $status)';
  }
}
