import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaseer/app/app.dart';
import 'package:yaseer/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('يختار المستخدم الوضع الأساسي ويصل إلى لوحة التحكم',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = await AppController.create();

    await tester.pumpWidget(YaseerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('اختر ما يناسب عملك'), findsOneWidget);
    expect(find.text('ابدأ بالأساسي'), findsOneWidget);

    await tester.tap(find.text('ابدأ بالأساسي'));
    await tester.pumpAndSettle();

    expect(find.text('مرحبًا بك في يسير'), findsOneWidget);
    expect(find.text('ديون العملاء المتبقية'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('تعرض شاشة اختيار الوضع على المقاسات الواسعة دون أخطاء',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = await AppController.create();
    addTearDown(controller.dispose);

    await tester.pumpWidget(YaseerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('التطبيق الأساسي'), findsOneWidget);
    expect(find.text('التطبيق الاحترافي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
