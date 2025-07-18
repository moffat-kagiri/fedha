// Custom enum adapters for types not generated by build_runner
import 'package:hive/hive.dart';

// Budget Period enum (if not auto-generated)
enum BudgetPeriod { weekly, monthly, yearly }

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 25;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.weekly;
      case 1:
        return BudgetPeriod.monthly;
      case 2:
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.weekly:
        writer.writeByte(0);
        break;
      case BudgetPeriod.monthly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(2);
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

// Budget Status enum (if not auto-generated)
enum BudgetStatus { active, completed, overBudget, paused }

class BudgetStatusAdapter extends TypeAdapter<BudgetStatus> {
  @override
  final int typeId = 26;

  @override
  BudgetStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetStatus.active;
      case 1:
        return BudgetStatus.completed;
      case 2:
        return BudgetStatus.overBudget;
      case 3:
        return BudgetStatus.paused;
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
      case BudgetStatus.completed:
        writer.writeByte(1);
        break;
      case BudgetStatus.overBudget:
        writer.writeByte(2);
        break;
      case BudgetStatus.paused:
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
