import 'package:caremate/app/caremate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  testWidgets('sign-in screen matches the reviewed phone layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CareMateApp(authCoordinator: signedOutCoordinator()),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/auth_sign_in.png'),
    );
  });
}
