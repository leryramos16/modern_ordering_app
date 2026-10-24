import 'dart:convert';

import 'package:admin_app/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('product list shows new price right after Save changes', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'test'});
    var price = 2.5;
    Map<String, dynamic> espresso() => {
      'id': 1,
      'categoryId': 1,
      'name': 'Espresso',
      'description': null,
      'price': price,
      'imageUrl': null,
      'isAvailable': true,
    };

    final fakeServer = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET' && path == '/admin/products') {
        return http.Response(jsonEncode([espresso()]), 200);
      }
      if (request.method == 'GET' && path == '/categories') {
        return http.Response(jsonEncode([{'id': 1, 'name': 'Coffee'}]), 200);
      }
      if (request.method == 'PUT' && path == '/admin/products/1') {
        price = 9.99;
        return http.Response(jsonEncode(espresso()), 200);
      }
      return http.Response('not found', 404);
    });

    await http.runWithClient(() async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ProductsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('₱2.50'), findsOneWidget);

      await tester.tap(find.text('Espresso'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('₱9.99'), findsOneWidget, reason: 'list should refresh');
    }, () => fakeServer);
  });
}
