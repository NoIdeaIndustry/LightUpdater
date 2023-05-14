import 'package:flutter/material.dart';

import 'package:light_updater/utils/utils.dart';

import 'custom_spacer.dart';

class CustomWatermark extends StatelessWidget {
  const CustomWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          Config.kCustomWatermark,
          style: Styles.defaultLightLightStyle,
          textAlign: TextAlign.center,
        ),
        const Text(
          'LightUpdater - by NoideaIndustry',
          style: Styles.defaultLightLightStyle,
          textAlign: TextAlign.center,
        ),
        CustomSpacer.customHeightSpacer(5),
        const Text(
          "Version ${Config.kAppVersion}",
          style: Styles.defaultLightLightStyle,
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
