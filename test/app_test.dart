import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khabardar/app_state.dart';
import 'package:khabardar/main.dart';
import 'package:khabardar/widgets/logo.dart';

import 'fake_native.dart';

/// Init mixes real I/O (asset load) with fake-time timers (splash), so
/// alternate between the two until [finder] shows up.
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
  });

  testWidgets('first run: splash, onboarding, permissions, home', (
    tester,
  ) async {
    final native = FakeNative()..install();
    await tester.pumpWidget(KhabardarApp(state: AppState()));
    expect(find.byType(KhabardarLogo), findsWidgets);

    await pumpUntil(tester, find.text('Next'));
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on your shield'), findsOneWidget);
    expect(find.text('Call screening'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(native.settings['onboarded'], isTrue);
  });

  testWidgets('check screen flags a listed number and blocks it', (
    tester,
  ) async {
    final native = FakeNative()..install();
    native.settings['onboarded'] = true;
    await tester.pumpWidget(KhabardarApp(state: AppState()));
    await pumpUntil(tester, find.byType(NavigationBar));

    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0300 0000111');
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pumpAndSettle();

    expect(find.text('Scam number'), findsOneWidget);
    expect(find.text('214 people'), findsOneWidget);

    await tester.ensureVisible(find.text('Block number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block number'));
    await tester.pumpAndSettle();
    expect(native.blocked, hasLength(1));
    expect(find.text('Unblock'), findsOneWidget);
  });

  testWidgets('switching to Urdu flips the layout', (tester) async {
    final native = FakeNative()..install();
    native.settings['onboarded'] = true;
    native.settings['language'] = 'ur';
    await tester.pumpWidget(KhabardarApp(state: AppState()));
    await pumpUntil(tester, find.byType(NavigationBar));

    expect(find.text('حالیہ سرگرمی'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(NavigationBar)));
    expect(dir, TextDirection.rtl);
  });
}
