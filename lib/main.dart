// ponytail: dev-default entry point so `flutter test integration_test/` can
// build the APK without requiring --target. Production builds use --flavor
// and --target explicitly.
import 'main_dev.dart' as app;

Future<void> main() => app.main();
