import 'package:dwelleo_app/app/app.dart';
import 'package:dwelleo_app/core/config/app_config.dart';
import 'package:dwelleo_app/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppConfig.init(Flavor.dev);
    await setupServiceLocator();
  });

  tearDownAll(() async {
    await sl.reset();
  });

  testWidgets('DwelleoApp renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DwelleoApp());
    expect(find.byType(DwelleoApp), findsOneWidget);
  });
}
