import 'package:flutter/material.dart';

class CustomSpacer {
  static Widget smallWidthSpacer() {
    return const SizedBox(width: 10);
  }

  static Widget mediumWidthSpacer() {
    return const SizedBox(width: 20);
  }

  static Widget bigWidthSpacer() {
    return const SizedBox(width: 30);
  }

  static Widget customWidthSpacer(final double width) {
    return SizedBox(width: width);
  }

  static Widget smallHeightSpacer() {
    return const SizedBox(height: 10);
  }

  static Widget mediumHeightSpacer() {
    return const SizedBox(height: 20);
  }

  static Widget bigHeightSpacer() {
    return const SizedBox(height: 30);
  }

  static Widget customHeightSpacer(final double height) {
    return SizedBox(height: height);
  }
}
