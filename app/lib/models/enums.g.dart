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

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 31;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.daily;
      case 1:
        return BudgetPeriod.weekly;
      case 2:
        return BudgetPeriod.monthly;
      case 3:
        return BudgetPeriod.quarterly;
      case 4:
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.daily:
        writer.writeByte(0);
        break;
      case BudgetPeriod.weekly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.monthly:
        writer.writeByte(2);
        break;
      case BudgetPeriod.quarterly:
        writer.writeByte(3);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetStatusAdapter extends TypeAdapter<BudgetStatus> {
  @override
  final int typeId = 32;

  @override
  BudgetStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetStatus.active;
      case 1:
        return BudgetStatus.inactive;
      case 2:
        return BudgetStatus.exceeded;
      case 3:
        return BudgetStatus.completed;
      default:
        return BudgetStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetStatus obj) {
    switch (obj) {
      case BudgetStatus.active:
        writer.writeByte(0);
        break;
      case BudgetStatus.inactive:
        writer.writeByte(1);
        break;
      case BudgetStatus.exceeded:
        writer.writeByte(2);
        break;
      case BudgetStatus.completed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvoiceStatusAdapter extends TypeAdapter<InvoiceStatus> {
  @override
  final int typeId = 26;

  @override
  InvoiceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvoiceStatus.draft;
      case 1:
        return InvoiceStatus.sent;
      case 2:
        return InvoiceStatus.paid;
      case 3:
        return InvoiceStatus.overdue;
      case 4:
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, InvoiceStatus obj) {
    switch (obj) {
      case InvoiceStatus.draft:
        writer.writeByte(0);
        break;
      case InvoiceStatus.sent:
        writer.writeByte(1);
        break;
      case InvoiceStatus.paid:
        writer.writeByte(2);
        break;
      case InvoiceStatus.overdue:
        writer.writeByte(3);
        break;
      case InvoiceStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionStatusAdapter extends TypeAdapter<TransactionStatus> {
  @override
  final int typeId = 27;

  @override
  TransactionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionStatus.pending;
      case 1:
        return TransactionStatus.completed;
      case 2:
        return TransactionStatus.failed;
      case 3:
        return TransactionStatus.cancelled;
      case 4:
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionStatus obj) {
    switch (obj) {
      case TransactionStatus.pending:
        writer.writeByte(0);
        break;
      case TransactionStatus.completed:
        writer.writeByte(1);
        break;
      case TransactionStatus.failed:
        writer.writeByte(2);
        break;
      case TransactionStatus.cancelled:
        writer.writeByte(3);
        break;
      case TransactionStatus.refunded:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringTypeAdapter extends TypeAdapter<RecurringType> {
  @override
  final int typeId = 28;

  @override
  RecurringType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringType.daily;
      case 1:
        return RecurringType.weekly;
      case 2:
        return RecurringType.biweekly;
      case 3:
        return RecurringType.monthly;
      case 4:
        return RecurringType.quarterly;
      case 5:
        return RecurringType.yearly;
      default:
        return RecurringType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringType obj) {
    switch (obj) {
      case RecurringType.daily:
        writer.writeByte(0);
        break;
      case RecurringType.weekly:
        writer.writeByte(1);
        break;
      case RecurringType.biweekly:
        writer.writeByte(2);
        break;
      case RecurringType.monthly:
        writer.writeByte(3);
        break;
      case RecurringType.quarterly:
        writer.writeByte(4);
        break;
      case RecurringType.yearly:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 29;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.transactionAlert;
      case 1:
        return NotificationType.budgetWarning;
      case 2:
        return NotificationType.goalProgress;
      case 3:
        return NotificationType.billReminder;
      case 4:
        return NotificationType.accountUpdate;
      case 5:
        return NotificationType.securityAlert;
      default:
        return NotificationType.transactionAlert;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.transactionAlert:
        writer.writeByte(0);
        break;
      case NotificationType.budgetWarning:
        writer.writeByte(1);
        break;
      case NotificationType.goalProgress:
        writer.writeByte(2);
        break;
      case NotificationType.billReminder:
        writer.writeByte(3);
        break;
      case NotificationType.accountUpdate:
        writer.writeByte(4);
        break;
      case NotificationType.securityAlert:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 30;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.cash;
      case 1:
        return AccountType.bankAccount;
      case 2:
        return AccountType.creditCard;
      case 3:
        return AccountType.investment;
      case 4:
        return AccountType.loan;
      case 5:
        return AccountType.savings;
      case 6:
        return AccountType.mobile;
      default:
        return AccountType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.cash:
        writer.writeByte(0);
        break;
      case AccountType.bankAccount:
        writer.writeByte(1);
        break;
      case AccountType.creditCard:
        writer.writeByte(2);
        break;
      case AccountType.investment:
        writer.writeByte(3);
        break;
      case AccountType.loan:
        writer.writeByte(4);
        break;
      case AccountType.savings:
        writer.writeByte(5);
        break;
      case AccountType.mobile:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
