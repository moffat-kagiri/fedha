// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileTypeAdapter extends TypeAdapter<ProfileType> {
  @override
  final int typeId = 20;

  @override
  ProfileType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProfileType.personal;
      case 1:
        return ProfileType.business;
      case 2:
        return ProfileType.family;
      case 3:
        return ProfileType.student;
      default:
        return ProfileType.personal;
    }
  }

  @override
  void write(BinaryWriter writer, ProfileType obj) {
    switch (obj) {
      case ProfileType.personal:
        writer.writeByte(0);
        break;
      case ProfileType.business:
        writer.writeByte(1);
        break;
      case ProfileType.family:
        writer.writeByte(2);
        break;
      case ProfileType.student:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 21;

  @override
  GoalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalType.savings;
      case 1:
        return GoalType.debtReduction;
      case 2:
        return GoalType.investment;
      case 3:
        return GoalType.expenseReduction;
      case 4:
        return GoalType.emergencyFund;
      case 5:
        return GoalType.incomeIncrease;
      case 6:
        return GoalType.retirement;
      case 7:
        return GoalType.other;
      default:
        return GoalType.savings;
    }
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    switch (obj) {
      case GoalType.savings:
        writer.writeByte(0);
        break;
      case GoalType.debtReduction:
        writer.writeByte(1);
        break;
      case GoalType.investment:
        writer.writeByte(2);
        break;
      case GoalType.expenseReduction:
        writer.writeByte(3);
        break;
      case GoalType.emergencyFund:
        writer.writeByte(4);
        break;
      case GoalType.incomeIncrease:
        writer.writeByte(5);
        break;
      case GoalType.retirement:
        writer.writeByte(6);
        break;
      case GoalType.other:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 22;

  @override
  GoalStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalStatus.active;
      case 1:
        return GoalStatus.completed;
      case 2:
        return GoalStatus.paused;
      case 3:
        return GoalStatus.cancelled;
      default:
        return GoalStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    switch (obj) {
      case GoalStatus.active:
        writer.writeByte(0);
        break;
      case GoalStatus.completed:
        writer.writeByte(1);
        break;
      case GoalStatus.paused:
        writer.writeByte(2);
        break;
      case GoalStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 23;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.transfer;
      case 3:
        return TransactionType.savings;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.transfer:
        writer.writeByte(2);
        break;
      case TransactionType.savings:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 24;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cash;
      case 1:
        return PaymentMethod.card;
      case 2:
        return PaymentMethod.bank;
      case 3:
        return PaymentMethod.mobile;
      case 4:
        return PaymentMethod.online;
      case 5:
        return PaymentMethod.cheque;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cash:
        writer.writeByte(0);
        break;
      case PaymentMethod.card:
        writer.writeByte(1);
        break;
      case PaymentMethod.bank:
        writer.writeByte(2);
        break;
      case PaymentMethod.mobile:
        writer.writeByte(3);
        break;
      case PaymentMethod.online:
        writer.writeByte(4);
        break;
      case PaymentMethod.cheque:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 25;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.food;
      case 1:
        return TransactionCategory.transport;
      case 2:
        return TransactionCategory.entertainment;
      case 3:
        return TransactionCategory.utilities;
      case 4:
        return TransactionCategory.healthcare;
      case 5:
        return TransactionCategory.shopping;
      case 6:
        return TransactionCategory.education;
      case 7:
        return TransactionCategory.business;
      case 8:
        return TransactionCategory.investment;
      case 9:
        return TransactionCategory.other;
      default:
        return TransactionCategory.food;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.food:
        writer.writeByte(0);
        break;
      case TransactionCategory.transport:
        writer.writeByte(1);
        break;
      case TransactionCategory.entertainment:
        writer.writeByte(2);
        break;
      case TransactionCategory.utilities:
        writer.writeByte(3);
        break;
      case TransactionCategory.healthcare:
        writer.writeByte(4);
        break;
      case TransactionCategory.shopping:
        writer.writeByte(5);
        break;
      case TransactionCategory.education:
        writer.writeByte(6);
        break;
      case TransactionCategory.business:
        writer.writeByte(7);
        break;
      case TransactionCategory.investment:
        writer.writeByte(8);
        break;
      case TransactionCategory.other:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
