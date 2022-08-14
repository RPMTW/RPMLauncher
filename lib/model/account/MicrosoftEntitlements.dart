import 'dart:convert';

import 'package:flutter/foundation.dart';

class MicrosoftEntitlements {
  final List<EntitlementItem> items;
  final String signature;
  final String keyId;
  final String requestId;

  bool get canPlayMinecraft =>
      items.any((item) => item.name == "product_minecraft") &&
      items.any((item) => item.name == "game_minecraft");

  const MicrosoftEntitlements({
    required this.items,
    required this.signature,
    required this.keyId,
    required this.requestId,
  });

  MicrosoftEntitlements copyWith({
    List<EntitlementItem>? items,
    String? signature,
    String? keyId,
    String? requestId,
  }) {
    return MicrosoftEntitlements(
      items: items ?? this.items,
      signature: signature ?? this.signature,
      keyId: keyId ?? this.keyId,
      requestId: requestId ?? this.requestId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((x) => x.toMap()).toList(),
      'signature': signature,
      'keyId': keyId,
      'requestId': requestId,
    };
  }

  factory MicrosoftEntitlements.fromMap(Map<String, dynamic> map) {
    return MicrosoftEntitlements(
      items: List<EntitlementItem>.from(
          map['items']?.map((x) => EntitlementItem.fromMap(x))),
      signature: map['signature'],
      keyId: map['keyId'],
      requestId: map['requestId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MicrosoftEntitlements.fromJson(String source) =>
      MicrosoftEntitlements.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MicrosoftEntitlements(items: $items, signature: $signature, keyId: $keyId, requestId: $requestId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MicrosoftEntitlements &&
        listEquals(other.items, items) &&
        other.signature == signature &&
        other.keyId == keyId &&
        other.requestId == requestId;
  }

  @override
  int get hashCode {
    return items.hashCode ^
        signature.hashCode ^
        keyId.hashCode ^
        requestId.hashCode;
  }
}

class EntitlementItem {
  final String name;
  final String source;
  EntitlementItem({
    required this.name,
    required this.source,
  });

  EntitlementItem copyWith({
    String? name,
    String? source,
  }) {
    return EntitlementItem(
      name: name ?? this.name,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
    };
  }

  factory EntitlementItem.fromMap(Map<String, dynamic> map) {
    return EntitlementItem(
      name: map['name'],
      source: map['source'],
    );
  }

  String toJson() => json.encode(toMap());

  factory EntitlementItem.fromJson(String source) =>
      EntitlementItem.fromMap(json.decode(source));

  @override
  String toString() => 'Item(name: $name, source: $source)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntitlementItem &&
        other.name == name &&
        other.source == source;
  }

  @override
  int get hashCode => name.hashCode ^ source.hashCode;
}
