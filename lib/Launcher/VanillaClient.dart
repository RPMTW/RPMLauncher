// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';

import 'MinecraftClient.dart';

class VanillaClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  late StateSetter setState;

  VanillaClient._init(
      {required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState});

  static Future<VanillaClient> createClient(
      {required Map Meta, required String VersionID, required SetState}) async {
    return await VanillaClient._init(
            handler: MinecraftClientHandler(),
            SetState: SetState,
            Meta: Meta,
            VersionID: VersionID)
        ._Ready(Meta, VersionID, SetState);
  }

  Future<VanillaClient> _Ready(VersionMetaUrl, VersionID, SetState) async {
    setState = SetState;
    await handler.Install(VersionMetaUrl, VersionID, setState);
    finish = true;
    return this;
  }
}
