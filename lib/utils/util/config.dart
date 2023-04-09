class Config {
  static const String kCustomWindowName = "CustomName";
  static const String kCustomWatermark = "CustomWatermark";
  static const String kAppVersion = "1:0:0:01";
  static const String kWindowIcon = "assets/images/icon.ico";
  static const String appFolderName = "LightUpdater";

  static const String kHostUrl = "host-ip/path/to/files/";
  static const String kJsonUrl = "host-ip/path/to/json.json";
  // you do not need to touch this if kCloseIfStarted and kRestartIfRunning = false
  static const int kCloseAfterSecs = 5;

  static const bool kCloseIfStarted = false;
  static const bool kRestartIfRunning = false;
}
