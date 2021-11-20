class ForgeDataList {
  final List<ForgeData> forgeDataList;
  final List forgeDataKeys;

  const ForgeDataList({required this.forgeDataList, required this.forgeDataKeys});

  factory ForgeDataList.fromJson(Map json) {
    List list = json.values.toList();
    List<ForgeData> forgeDataList_ = [];
    list.forEach((data) {
      forgeDataList_.add(ForgeData.fromJson(data));
    });
    return ForgeDataList(
        forgeDataList: forgeDataList_, forgeDataKeys: json.keys.toList());
  }

  List<ForgeData> toList() => forgeDataList;

  int getIndex(String dataName) => forgeDataKeys.indexOf(dataName);
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
