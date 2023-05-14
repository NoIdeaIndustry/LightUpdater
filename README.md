# LightUpdater

A Flutter app that helps you downloading and checking files of your project on your user's platforms.

## Prerequisites

The app is supported for any dart sdk within version 2.19.4 and 3.0.0.<br>
To install the flutter sdk, please follow the respective instructions for your platform at https://docs.flutter.dev/get-started/install.

## Usage

The uncompiled app can be run using the Flutter SDK, the compiled version will run according the the build command executed (refer to next lines).<br>
For a simple usage you can simple configure the Config class (refer to 'Configuration').<br>

To run the app, navigate to the project root folder and run the following command:
```dart
flutter run
```

To build the app, navigate to the project root folder and run the following command:
```dart
flutter build {platform=windows,macos,linux,etc...} --release
```

## Configuration

The `Config` class contains the variables that can be configured to customize labels. <br>
The `kHostUrl` variable specifies the URL where the files can be downloaded from.<br>
The `kJsonUrl` variable specifies the URL where the json file can be downloaded from (based on plaftorm).

```dart
class Config {
  static const String kCustomWindowName = "CustomName";
  static const String kCustomWatermark = "CustomWatermark";
  static const String kAppVersion = "1:0:0:01";
  static const String kWindowIcon = "assets/images/icon.ico";
  static const String appFolderName = "LightUpdater";

  static const String kHostUrl = "host-ip/path/to/files/";
  -> code implementation: kHostUrl/{platform}

  static const String kJsonUrl = "host-ip/path/to/json.json";
  -> code implementation: kJsonUrl/{platform}/{platform.json}

  <where platform is either windows, linux, macos, etc...>

  static const int kCloseAfterSecs = 5;

  static const bool kCloseOnceStarted = false;
  static const bool kRestartIfRunning = false;
}
```

To customize the configuration, edit the values in the Config class to match your tastes.

## Disclaimer
The downloading system is base on another project. Check out our [LightGenerator](https://github.com/NoIdeaIndustry/LightGenerator) project for more information.<br>
Dont want to use it? No worries! You just need to follow the same structure but you must use a json file as your entry point eitherway.
```dart
class Entry {
  final String name; // file name
  final int    size; // file size
  final String hash; // file calculated sha265
}
```

This project will and only support desktop version, for other platforms (mobile), updates are directly handeled by associated stores!<br>
Stay tuned for updates.

## License
This project is licensed under the [GPLv3 License](https://github.com/NoIdeaIndustry/FileUpdater/blob/main/LICENSE). See the file for details.