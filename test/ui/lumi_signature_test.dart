import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/core/widgets/lumi_signature.dart';

Widget app(Widget child) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('moment pauses, resets duration and cancels timers on close', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LumiMomentCard()));
    await tester.tap(find.byType(LumiMomentCard));
    await tester.pumpAndSettle();
    expect(find.text('1:00'), findsOneWidget);
    await tester.tap(find.text('Start my moment'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:58'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:58'), findsOneWidget);
    await tester.tap(find.text('2 min'));
    await tester.pump();
    expect(find.text('2:00'), findsOneWidget);
    await tester.tap(find.text('Start my moment'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('moment pauses when app leaves foreground', (tester) async {
    await tester.pumpWidget(app(const LumiMomentCard()));
    await tester.tap(find.byType(LumiMomentCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start my moment'));
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:59'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Continue'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('header supports small screen, large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: const LumiSignatureHeader(
                eyebrow: 'MY LUMI SPACE',
                title: 'Your space. Your kind of care.',
                description: 'Your profile and favourite experiences.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Your space. Your kind of care.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
