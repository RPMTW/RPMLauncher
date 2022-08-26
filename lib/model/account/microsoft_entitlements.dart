import 'dart:convert';

class MicrosoftEntitlements {
  final List<EntitlementItem> items;
  final String signature;
  final String keyId;
  final String requestId;

  bool get canPlayMinecraft =>
      items.any((item) => item.name == 'product_minecraft') &&
      items.any((item) => item.name == 'game_minecraft');

  const MicrosoftEntitlements({
    required this.items,
    required this.signature,
    required this.keyId,
    required this.requestId,
  });

  factory MicrosoftEntitlements.fromMap(Map<String, dynamic> map) {
    return MicrosoftEntitlements(
      items: List<EntitlementItem>.from(
          map['items']?.map((x) => EntitlementItem.fromMap(x))),
      signature: map['signature'],
      keyId: map['keyId'],
      requestId: map['requestId'],
    );
  }

  factory MicrosoftEntitlements.fromJson(String source) =>
      MicrosoftEntitlements.fromMap(json.decode(source));
}

class EntitlementItem {
  final String name;
  final String source;

  const EntitlementItem({
    required this.name,
    required this.source,
  });

  factory EntitlementItem.fromMap(Map<String, dynamic> map) {
    return EntitlementItem(
      name: map['name'],
      source: map['source'],
    );
  }
}
