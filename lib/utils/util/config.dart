class Config {
  static const String kCustomWindowName = "NoIdeaIndustry";
  static const String kCustomWatermark = "NoIdeaIndustry";

  static const String kAppVersion = "1:0:0:01";
  static const String kWindowIcon = "assets/images/app_icon.ico";
  static const String appFolderName = "LightUpdater";

  static const String kHostUrl = "host-ip/path/to/files/";
  static const String kJsonUrl = "host-ip/path/to/json.json";
  // you do not need to touch this if kCloseOnceStarted and kRestartIfRunning = false
  static const int kCloseAfterSecs = 5;

  static const bool kCloseOnceStarted = false;
  static const bool kRestartIfRunning = false;
}
