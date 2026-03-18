import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:popgrid/core/services/ad_service.dart';
import 'package:popgrid/main.dart';

void main() {
  setUp(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<AdService>()) {
      getIt.registerLazySingleton<AdService>(() => AdService());
    }
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PopGridApp());
    expect(find.text('PopGrid'), findsOneWidget);
  });
}
