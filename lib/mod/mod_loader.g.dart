// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mod_loader.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModLoaderAdapter extends TypeAdapter<ModLoader> {
  @override
  final int typeId = 1;

  @override
  ModLoader read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ModLoader.vanilla;
      case 1:
        return ModLoader.fabric;
      case 2:
        return ModLoader.forge;
      case 3:
        return ModLoader.paper;
      case 4:
        return ModLoader.unknown;
      default:
        return ModLoader.vanilla;
    }
  }

  @override
  void write(BinaryWriter writer, ModLoader obj) {
    switch (obj) {
      case ModLoader.vanilla:
        writer.writeByte(0);
        break;
      case ModLoader.fabric:
        writer.writeByte(1);
        break;
      case ModLoader.forge:
        writer.writeByte(2);
        break;
      case ModLoader.paper:
        writer.writeByte(3);
        break;
      case ModLoader.unknown:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModLoaderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
