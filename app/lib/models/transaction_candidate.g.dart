// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_candidate.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionCandidateAdapter extends TypeAdapter<TransactionCandidate> {
  @override
  final int typeId = 8;

  @override
  TransactionCandidate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionCandidate(
      id: fields[0] as String,
      rawText: fields[1] as String?,
      amount: fields[2] as double,
      description: fields[3] as String?,
      categoryId: fields[4] as String?,
      date: fields[5] as DateTime,
      type: fields[6] as String,
      status: fields[7] as String,
      confidence: fields[8] as double,
      transactionId: fields[9] as String?,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionCandidate obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rawText)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.confidence)
      ..writeByte(9)
      ..write(obj.transactionId)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCandidateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
