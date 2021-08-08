import 'dart:io';

import 'MinecraftClient.dart';

class VanillaClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  var SetState;

  VanillaClient._init(
      {required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<VanillaClient> createClient(
      {required Map Meta,
      required String VersionID,
      required setState}) async {
    return await new VanillaClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            Meta: Meta,
            VersionID: VersionID)
        ._Ready(Meta, VersionID, setState);
  }

  Future<VanillaClient> _Ready(
      VersionMetaUrl, VersionID, SetState) async {
    await handler.Install(VersionMetaUrl, VersionID, SetState);
    return this;
  }
}
