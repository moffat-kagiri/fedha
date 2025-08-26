import 'package:json_annotation/json_annotation.dart';
part 'invoice.g.dart';

@JsonSerializable()
class Invoice {
  String id;
  String invoiceNumber;
  String clientId;
  double amount;
  String currency;
  DateTime issueDate;
  DateTime dueDate;
  String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  String? description;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
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

  bool get isOverdue => status != 'paid' && status != 'cancelled' && DateTime.now().isAfter(dueDate);

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);
}
