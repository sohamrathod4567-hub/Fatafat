import 'package:flutter_test/flutter_test.dart';

import 'package:billing_app/app.dart';

void main() {
  testWidgets('tapping items updates quantity, subtotal and total', (WidgetTester tester) async {
    await tester.pumpWidget(const BillingApp());

    expect(find.text('Rs 0'), findsOneWidget);

    await tester.tap(find.text('Tea'));
    await tester.pump();
    expect(find.text('Tea'), findsNWidgets(2));
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('Rs 15'), findsNWidgets(2));

    await tester.tap(find.text('Tea').first);
    await tester.pump();
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('Rs 30'), findsNWidgets(2));

    await tester.tap(find.text('Samosa'));
    await tester.pump();
    expect(find.text('Samosa'), findsNWidgets(2));
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('Rs 20'), findsNWidgets(2));
    expect(find.text('Rs 50'), findsOneWidget);
  });

  testWidgets('new bill clears selected items and resets total instantly', (WidgetTester tester) async {
    await tester.pumpWidget(const BillingApp());

    await tester.tap(find.text('Tea'));
    await tester.pump();
    await tester.tap(find.text('Samosa'));
    await tester.pump();

    expect(find.text('Rs 35'), findsOneWidget);

    await tester.tap(find.text('New Bill'));
    await tester.pump();

    expect(find.text('Rs 0'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('x1'), findsNothing);
    expect(find.text('Rs 15'), findsOneWidget);
    expect(find.text('Rs 20'), findsOneWidget);
  });
}
