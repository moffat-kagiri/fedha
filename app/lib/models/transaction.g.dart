// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      uuid: fields[0] as String?,
      id: fields[1] as String?,
      amount: fields[2] as double,
      type: fields[3] as TransactionType,
      categoryId: fields[4] as String,
      category: fields[5] as TransactionCategory?,
      date: fields[6] as DateTime,
      notes: fields[7] as String?,
      description: fields[8] as String?,
      isSynced: fields[9] as bool,
      profileId: fields[10] as String,
      updatedAt: fields[11] as DateTime?,
      goalId: fields[12] as String?,
      smsSource: fields[13] as String?,
      reference: fields[14] as String?,
      recipient: fields[15] as String?,
      isPending: fields[16] as bool,
      isExpense: fields[17] as bool,
      isRecurring: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.profileId)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.goalId)
      ..writeByte(13)
      ..write(obj.smsSource)
      ..writeByte(14)
      ..write(obj.reference)
      ..writeByte(15)
      ..write(obj.recipient)
      ..writeByte(16)
      ..write(obj.isPending)
      ..writeByte(17)
      ..write(obj.isExpense)
      ..writeByte(18)
      ..write(obj.isRecurring);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      uuid: json['uuid'] as String?,
      id: json['id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      categoryId: json['categoryId'] as String,
      category:
          $enumDecodeNullable(_$TransactionCategoryEnumMap, json['category']),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      description: json['description'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      profileId: json['profileId'] as String,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      goalId: json['goalId'] as String?,
      smsSource: json['smsSource'] as String?,
      reference: json['reference'] as String?,
      recipient: json['recipient'] as String?,
      isPending: json['isPending'] as bool? ?? false,
      isExpense: json['isExpense'] as bool? ?? true,
      isRecurring: json['isRecurring'] as bool? ?? false,
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'id': instance.id,
      'amount': instance.amount,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'categoryId': instance.categoryId,
      'category': _$TransactionCategoryEnumMap[instance.category],
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
      'description': instance.description,
      'isSynced': instance.isSynced,
      'profileId': instance.profileId,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'goalId': instance.goalId,
      'smsSource': instance.smsSource,
      'reference': instance.reference,
      'recipient': instance.recipient,
      'isPending': instance.isPending,
      'isExpense': instance.isExpense,
      'isRecurring': instance.isRecurring,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
  TransactionType.savings: 'savings',
};

const _$TransactionCategoryEnumMap = {
  TransactionCategory.food: 'food',
  TransactionCategory.transport: 'transport',
  TransactionCategory.entertainment: 'entertainment',
  TransactionCategory.utilities: 'utilities',
  TransactionCategory.healthcare: 'healthcare',
  TransactionCategory.shopping: 'shopping',
  TransactionCategory.education: 'education',
  TransactionCategory.business: 'business',
  TransactionCategory.investment: 'investment',
  TransactionCategory.other: 'other',
};
