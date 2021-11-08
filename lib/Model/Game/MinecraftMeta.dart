class MinecraftMeta {
  Map<String, dynamic> rawMeta;

  MinecraftMeta(this.rawMeta);

  operator [](String key) => rawMeta[key];
  operator []=(String key, dynamic value) => rawMeta[key] = value;

  bool containsKey(String key) => rawMeta.containsKey(key);
}
