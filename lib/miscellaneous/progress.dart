// ignore_for_file: constant_identifier_names

enum Progress {
  NULL,
  CHECK,
  DOWNLOAD,
  UPDATE,
  COMPLETE,
  START,
  RUN,
  ERROR,
}

extension ProgressExtension on Progress {
  String get message {
    switch (this) {
      case Progress.CHECK:
        return 'Checking for available updates...';
      case Progress.DOWNLOAD:
        return 'Downloading updates in progress...';
      case Progress.UPDATE:
        return 'Updating...';
      case Progress.COMPLETE:
        return 'Update completed!';
      case Progress.START:
        return 'The program has now started!';
      case Progress.RUN:
        return 'The program is already running!';
      case Progress.ERROR:
        return 'An unexpected error occured!';
      default:
        return '';
    }
  }
}
