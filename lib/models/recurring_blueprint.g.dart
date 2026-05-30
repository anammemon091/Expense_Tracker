// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_blueprint.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringBlueprintAdapter extends TypeAdapter<RecurringBlueprint> {
  @override
  final int typeId = 2;

  @override
  RecurringBlueprint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringBlueprint(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      interval: fields[4] as String,
      startDate: fields[5] as DateTime,
      lastTriggeredDate: fields[6] as DateTime,
      isExpense: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringBlueprint obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.interval)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.lastTriggeredDate)
      ..writeByte(7)
      ..write(obj.isExpense);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringBlueprintAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
