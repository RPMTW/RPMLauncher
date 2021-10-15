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

  int getIndex(String DataName) => forgeDatakeys.indexOf(DataName);
}

class ForgeData {
  final String Client;
  final String Server;

  const ForgeData({
    required this.Client,
    required this.Server,
  });

  factory ForgeData.fromJson(Map json) =>
      ForgeData(Client: json['client'], Server: json['server']);

  Map<String, dynamic> toJson() => {'client': Client, 'server': Server};
}
