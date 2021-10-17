class ForgeDatas {
  final List<ForgeData> forgeDatas;
  final List forgeDatakeys;

  const ForgeDatas({required this.forgeDatas, required this.forgeDatakeys});

  factory ForgeDatas.fromJson(Map json) {
    List lsit = json.values.toList();
    List<ForgeData> forgeDatas_ = [];
    lsit.forEach((data) {
      forgeDatas_.add(ForgeData.fromJson(data));
    });
    return ForgeDatas(
        forgeDatas: forgeDatas_, forgeDatakeys: json.keys.toList());
  }

  List<ForgeData> toList() => forgeDatas;

  int getIndex(String dataName) => forgeDatakeys.indexOf(dataName);
}

class ForgeData {
  final String client;
  final String server;

  const ForgeData({
    required this.client,
    required this.server,
  });

  factory ForgeData.fromJson(Map json) =>
      ForgeData(client: json['client'], server: json['server']);

  Map<String, dynamic> toJson() => {'client': client, 'server': server};
}
