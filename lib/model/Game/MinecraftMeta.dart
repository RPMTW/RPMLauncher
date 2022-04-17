class MinecraftMeta {
  Map<String, dynamic> rawMeta;

  MinecraftMeta(this.rawMeta);

  operator [](String key) => rawMeta[key];
  operator []=(String key, dynamic value) => rawMeta[key] = value;

  int get javaVersion {
    try {
      if (rawMeta.containsKey("javaVersion")) {
        return rawMeta["javaVersion"]["majorVersion"];
      } else {
        return 8;
      }
    } catch (e) {
      return 8;
    }
  }

  bool containsKey(String key) => rawMeta.containsKey(key);
}
