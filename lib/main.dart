import 'bootstrap.dart';
import 'core/config/app_config.dart';

// Default entry point (dev). Flavor-specific launches use main_<flavor>.dart.
void main() => bootstrap(Flavor.dev);
