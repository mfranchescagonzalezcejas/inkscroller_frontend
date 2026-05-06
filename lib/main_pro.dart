import 'core/config/app_environment.dart';
import 'core/constants/app_constants.dart';
import 'main_common.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  await mainCommon(
    flavor: Flavor.pro,
    apiBaseUrl: AppEnvironment.apiBaseUrl,
    name: AppConstants.appName,
  );
}
