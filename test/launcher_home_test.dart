import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/ui/screen/main_screen.dart';

import 'script/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());
  testWidgets('Launcher Home', (WidgetTester tester) async {
    await tester.pumpWidget(const MainScreen());
  });
}
