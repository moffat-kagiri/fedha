import 'package:hive/hive.dart';
import '../models/enums.dart';

// Hive type adapters for enums
class ProfileTypeAdapter extends TypeAdapter<ProfileType> {
  @override
  final int typeId = 100;

  @override
  ProfileType read(BinaryReader reader) {
    return ProfileType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ProfileType obj) {
    writer.writeByte(obj.index);
  }
}

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 101;

  @override
  GoalType read(BinaryReader reader) {
    return GoalType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    writer.writeByte(obj.index);
  }
}

class GoalStatusAdapter extends TypeAdapter<GoalStatus> {
  @override
  final int typeId = 102;

  @override
  GoalStatus read(BinaryReader reader) {
    return GoalStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, GoalStatus obj) {
    writer.writeByte(obj.index);
  }
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 103;

  @override
  TransactionType read(BinaryReader reader) {
    return TransactionType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeByte(obj.index);
  }
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 104;

  @override
  TransactionCategory read(BinaryReader reader) {
    return TransactionCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    writer.writeByte(obj.index);
  }
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 105;

  @override
  BudgetPeriod read(BinaryReader reader) {
    return BudgetPeriod.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    writer.writeByte(obj.index);
  }
}

class BudgetStatusAdapter extends TypeAdapter<BudgetStatus> {
  @override
  final int typeId = 106;

  @override
  BudgetStatus read(BinaryReader reader) {
    return BudgetStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BudgetStatus obj) {
    writer.writeByte(obj.index);
  }
}

class InvoiceStatusAdapter extends TypeAdapter<InvoiceStatus> {
  @override
  final int typeId = 107;

  @override
  InvoiceStatus read(BinaryReader reader) {
    return InvoiceStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, InvoiceStatus obj) {
    writer.writeByte(obj.index);
  }
}

class InvoiceLineItemAdapter extends TypeAdapter<InvoiceLineItem> {
  @override
  final int typeId = 108;

  @override
  InvoiceLineItem read(BinaryReader reader) {
    return InvoiceLineItem(
      description: reader.readString(),
      quantity: reader.readDouble(),
      unitPrice: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceLineItem obj) {
    writer.writeString(obj.description);
    writer.writeDouble(obj.quantity);
    writer.writeDouble(obj.unitPrice);
  }
}

class BudgetLineItemAdapter extends TypeAdapter<BudgetLineItem> {
  @override
  final int typeId = 109;

  @override
  BudgetLineItem read(BinaryReader reader) {
    return BudgetLineItem(
      categoryId: reader.readString(),
      categoryName: reader.readString(),
      allocatedAmount: reader.readDouble(),
      spentAmount: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BudgetLineItem obj) {
    writer.writeString(obj.categoryId);
    writer.writeString(obj.categoryName);
    writer.writeDouble(obj.allocatedAmount);
    writer.writeDouble(obj.spentAmount);
  }
}
