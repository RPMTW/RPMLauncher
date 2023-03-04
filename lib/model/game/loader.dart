enum GameLoader {
  vanilla,
  fabric,
  forge,
  quilt;

  String getIconAssets() {
    return 'assets/images/loader/$name.png';
  }

  String getBackgroundAssets() {
    return 'assets/images/loader/${name}_background.png';
  }
}
