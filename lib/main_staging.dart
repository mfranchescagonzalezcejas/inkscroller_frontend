import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/core/constants/app_constants.dart';

import 'main_common.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  await mainCommon(
    flavor: Flavor.staging,
    apiBaseUrl: AppEnvironment.apiBaseUrl,
    name: AppConstants.appName,
  );
}
